import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/services/cloudinary_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME ALIASES  (maps old local constants → AppColors)
// ─────────────────────────────────────────────────────────────────────────────
const _bg       = AppColors.bg;
const _bgCard   = AppColors.surface;
const _bgCard2  = AppColors.surface2;
const _border   = AppColors.border;
const _primary  = AppColors.primary;
const _primDark = Color(0xFF4B2FD4);
const _green    = AppColors.success;
const _danger   = AppColors.error;
const _fp       = Colors.white;
const _fs       = AppColors.textSecondary;
const _fm       = AppColors.textMuted;

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────
enum MaterialType { pdf, image, doc, link }

extension MaterialTypeX on MaterialType {
  String get label => ['PDF', 'Image', 'Doc', 'Link'][index];
  IconData get icon => [
        Icons.picture_as_pdf_rounded,
        Icons.image_rounded,
        Icons.description_rounded,
        Icons.link_rounded,
      ][index];
  List<String> get allowedExtensions => <List<String>>[
        ['pdf'],
        ['jpeg', 'jpg', 'png'],
        ['doc', 'docx', 'ppt', 'pptx'],
        [],                               // link — no file picker
      ][index];
}

// ClassModel is used directly — no local _ClassOption needed.

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class MaterialUploadScreen extends StatefulWidget {
  /// Optional pre-selected class (e.g. when opened from ClassDetailScreen).
  final ClassModel? preselectedClass;

  const MaterialUploadScreen({super.key, this.preselectedClass});

  @override
  State<MaterialUploadScreen> createState() => _MaterialUploadScreenState();
}

class _MaterialUploadScreenState extends State<MaterialUploadScreen> {
  // controllers
  final _titleCtrl   = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _formKey     = GlobalKey<FormState>();

  // state
  ClassModel?    _selectedClass;
  MaterialType   _selectedType  = MaterialType.pdf;
  File?          _pickedFile;
  String?        _pickedFileName;
  String?        _pickedFileSize;
  bool           _isUploading   = false;
  double         _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.preselectedClass;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── File picking ────────────────────────────────────────────────────────────
  Future<void> _pickFile() async {
    if (_selectedType == MaterialType.link) {
      _showSnack('Enter a link in the description field.', isError: true);
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _selectedType.allowedExtensions,
      allowMultiple: false,
    );
    if (result == null) return;

    final pf   = result.files.single;
    final file = File(pf.path!);
    final mb   = (pf.size / (1024 * 1024));

    if (mb > 20) {
      _showSnack('File exceeds 20 MB limit.', isError: true);
      return;
    }

    setState(() {
      _pickedFile     = file;
      _pickedFileName = pf.name;
      _pickedFileSize = '${mb.toStringAsFixed(1)} MB';
    });
  }

  void _removeFile() => setState(() {
        _pickedFile     = null;
        _pickedFileName = null;
        _pickedFileSize = null;
      });

  // ── Class picker bottom sheet ────────────────────────────────────────────────
  void _showClassPicker() {
    final classes = context.read<AppState>().myClasses;
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ClassPickerSheet(
        classes: classes,
        selected: _selectedClass,
        onSelect: (c) {
          setState(() => _selectedClass = c);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── Submit ──────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedClass == null) {
      _showSnack('Please assign a class.', isError: true);
      return;
    }
    if (_pickedFile == null && _selectedType != MaterialType.link) {
      _showSnack('Please attach a file.', isError: true);
      return;
    }

    setState(() { _isUploading = true; _uploadProgress = 0; });

    try {
      final appState = context.read<AppState>();
      final cloudinary = CloudinaryService();
      final teacherId = appState.currentUser!.id;

      if (_selectedType == MaterialType.link) {
        // For links, save directly to Firestore without Cloudinary upload
        await cloudinary.saveMaterialLink(
          classId: _selectedClass!.id,
          name: _titleCtrl.text.trim(),
          subject: _subjectCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          url: _descCtrl.text.trim(), // Link URL from description
          uploadedBy: teacherId,
        );
      } else {
        // Upload file to Cloudinary
        final result = await cloudinary.uploadFile(
          file: _pickedFile!,
          fileName: _pickedFileName!,
          teacherId: teacherId,
          onProgress: (progress) {
            if (mounted) setState(() => _uploadProgress = progress);
          },
        );

        // Save to Firestore
        await cloudinary.saveMaterial(
          classId: _selectedClass!.id,
          name: _titleCtrl.text.trim(),
          subject: _subjectCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          type: _selectedType.label.toLowerCase(),
          cloudinaryResult: result,
          uploadedBy: teacherId,
        );
      }

      if (mounted) {
        _showSnack('Material uploaded successfully!');
        Navigator.maybePop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isUploading = false; _uploadProgress = 0; });
        _showSnack(e.toString(), isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: isError ? _danger : _green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Column(
            children: [
              // ── Header (flat bg, matches Pencil design) ────────────────────
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 20),
                color: _bg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button (plain row with chevron + text)
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.chevron_left_rounded,
                            color: _fs,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Back',
                            style: GoogleFonts.inter(
                              color: _fs,
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Upload Material',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Share resources with your students',
                      style: GoogleFonts.inter(
                        color: _fm,
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable form ─────────────────────────────────────────────
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Title ──────────────────────────────────────────
                            _fieldLabel('Title'),
                            const SizedBox(height: 8),
                            _AppInput(
                              controller: _titleCtrl,
                              hint: 'e.g. Chapter 3 — Laws of Motion',
                              icon: Icons.text_fields_rounded,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Enter a title'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // ── Subject ────────────────────────────────────────
                            _fieldLabel('Subject'),
                            const SizedBox(height: 8),
                            _AppInput(
                              controller: _subjectCtrl,
                              hint: 'e.g. Physics',
                              icon: Icons.book_outlined,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Enter a subject'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // ── Assign to Class ────────────────────────────────
                            _fieldLabel('Assign to Class'),
                            const SizedBox(height: 8),
                            _ClassField(
                              selected: _selectedClass,
                              onTap: _showClassPicker,
                            ),
                            const SizedBox(height: 16),

                            // ── Material Type ──────────────────────────────────
                            _fieldLabel('Material Type'),
                            const SizedBox(height: 8),
                            _TypeChips(
                              selected: _selectedType,
                              onSelect: (t) => setState(() {
                                _selectedType = t;
                                _removeFile();
                              }),
                            ),
                            const SizedBox(height: 16),

                            // ── Description ────────────────────────────────────
                            _fieldLabel('Description (optional)'),
                            const SizedBox(height: 8),
                            _DescField(controller: _descCtrl),
                            const SizedBox(height: 16),

                            // ── Attach File ────────────────────────────────────
                            _fieldLabel('Attach File'),
                            const SizedBox(height: 8),
                            _pickedFile != null
                                ? _FilePreviewCard(
                                    name: _pickedFileName!,
                                    size: _pickedFileSize!,
                                    onRemove: _removeFile,
                                  )
                                : _UploadZone(
                                    isLink: _selectedType == MaterialType.link,
                                    onBrowse: _pickFile,
                                  ),
                          ],
                        ),
                      ),
                    ),

                    // ── Sticky bottom button ──────────────────────────────────
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: _BottomBar(
                        isLoading: _isUploading,
                        onTap: _isUploading ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Upload overlay (centered with black transparent background) ────
          if (_isUploading)
            Container(
              color: Colors.black.withValues(alpha: 0.75),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: _bgCard,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Circular progress indicator
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: _uploadProgress,
                                strokeWidth: 6,
                                backgroundColor: _bgCard2,
                                valueColor: const AlwaysStoppedAnimation(_primary),
                              ),
                            ),
                            Text(
                              '${(_uploadProgress * 100).toInt()}%',
                              style: GoogleFonts.inter(
                                color: _fp,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Uploading to Cloudinary...',
                        style: GoogleFonts.inter(
                          color: _fp,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait while we upload your file',
                        style: GoogleFonts.inter(
                          color: _fm,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Text(text,
            style: GoogleFonts.inter(
              color: _fs,
              fontSize: 13,
              fontWeight: FontWeight.normal,
            )),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

// ── Standard input (matches Login / Create Test style) ───────────────────────
class _AppInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;

  const _AppInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: 1,
      style: GoogleFonts.inter(color: _fp, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: _fm, fontSize: 14),
        prefixIcon: Icon(icon, color: _fm, size: 18),
        filled: true,
        fillColor: _bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _danger, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorStyle: GoogleFonts.inter(color: _danger, fontSize: 11),
        isDense: true,
      ),
    );
  }
}

// ── Class selector field ──────────────────────────────────────────────────────
class _ClassField extends StatelessWidget {
  final ClassModel? selected;
  final VoidCallback onTap;

  const _ClassField({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final filled = selected != null;
    final displayText = filled ? '${selected!.name} — ${selected!.subject}' : 'Select a class';
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: filled ? _primary : _border,
            width: filled ? 1.5 : 1,
          ),
          boxShadow: filled
              ? [BoxShadow(color: _primary.withValues(alpha: 0.12), blurRadius: 10)]
              : [],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.groups_rounded,
              color: filled ? _primary : _fm,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayText,
                style: GoogleFonts.inter(
                  color: filled ? _fp : _fm,
                  fontSize: 14,
                  fontWeight: filled ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            if (filled)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Selected',
                  style: GoogleFonts.inter(
                    color: _primary, fontSize: 10, fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: filled ? _primary : _fm,
              size: 18,
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

// ── Class picker bottom sheet ─────────────────────────────────────────────────
class _ClassPickerSheet extends StatelessWidget {
  final List<ClassModel> classes;
  final ClassModel? selected;
  final void Function(ClassModel) onSelect;

  const _ClassPickerSheet({
    required this.classes,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Assign to Class',
              style: GoogleFonts.inter(
                color: _fp, fontSize: 18, fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Material will be visible to students in this class',
              style: GoogleFonts.inter(color: _fm, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (classes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No classes found. Create a class first.',
                  style: GoogleFonts.inter(color: _fm, fontSize: 13),
                ),
              ),
            ...classes.map((c) {
              final isSelected = selected?.id == c.id;
              return GestureDetector(
                onTap: () => onSelect(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _primary.withValues(alpha: 0.10)
                        : _bgCard2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _primary : _border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // class icon
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isSelected
                                ? [_primary, _primDark]
                                : [_bgCard, _border],
                          ),
                        ),
                        child: Icon(
                          Icons.class_rounded,
                          color: isSelected ? Colors.white : _fm,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              style: GoogleFonts.inter(
                                color: _fp,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${c.subject} · ${c.studentCount} student${c.studentCount == 1 ? '' : 's'}',
                              style: GoogleFonts.inter(color: _fm, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      // check
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? _primary : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? _primary : _border,
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 13,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Material type chips ────────────────────────────────────────────────────────
class _TypeChips extends StatelessWidget {
  final MaterialType selected;
  final void Function(MaterialType) onSelect;

  const _TypeChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: MaterialType.values.map((t) {
        final active = t == selected;
        return GestureDetector(
          onTap: () => onSelect(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: active ? _primary : _bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? _primary : _border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  t.icon,
                  size: 14,
                  color: active ? Colors.white : _fs,
                ),
                const SizedBox(width: 6),
                Text(
                  t.label,
                  style: GoogleFonts.inter(
                    color: active ? Colors.white : _fs,
                    fontSize: 12,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Description textarea ───────────────────────────────────────────────────────
class _DescField extends StatefulWidget {
  final TextEditingController controller;
  const _DescField({required this.controller});

  @override
  State<_DescField> createState() => _DescFieldState();
}

class _DescFieldState extends State<_DescField> {
  int _charCount = 0;
  static const int _maxChars = 200;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateCharCount);
    _charCount = widget.controller.text.length;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateCharCount);
    super.dispose();
  }

  void _updateCharCount() {
    setState(() {
      _charCount = widget.controller.text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TextField(
          controller: widget.controller,
          minLines: 1,
          maxLines: 3,
          maxLength: _maxChars,
          style: GoogleFonts.inter(color: _fp, fontSize: 14, height: 1.4),
          decoration: InputDecoration(
            hintText: 'Add context for your students...',
            hintStyle: GoogleFonts.inter(color: _fm, fontSize: 14),
            filled: true,
            fillColor: _bgCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border, width: 1),
            ),
            contentPadding: const EdgeInsets.fromLTRB(48, 14, 70, 14),
            isDense: true,
            counterText: '',
          ),
        ),
        // Icon positioned on the left
        const Positioned(
          left: 16,
          top: 14,
          child: Icon(Icons.list_rounded, color: _fm, size: 16),
        ),
        // Counter positioned on the right
        Positioned(
          right: 16,
          top: 14,
          child: Text(
            '$_charCount/$_maxChars',
            style: GoogleFonts.inter(
              color: _charCount > _maxChars * 0.9 ? _danger : _fm,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Upload drop zone ───────────────────────────────────────────────────────────
class _UploadZone extends StatelessWidget {
  final bool isLink;
  final VoidCallback onBrowse;

  const _UploadZone({required this.isLink, required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLink ? null : onBrowse,
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: isLink
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.link_rounded, color: _fm, size: 36),
                    const SizedBox(height: 16),
                    Text(
                      'Paste the link in the description above',
                      style: GoogleFonts.inter(color: _fm, fontSize: 13),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.094),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_rounded,
                      color: _primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Drag & drop or browse',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: _fp,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PDF · DOC · PNG · Max 20MB',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: _fm, fontSize: 13),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── File preview card (after picking) ─────────────────────────────────────────
class _FilePreviewCard extends StatelessWidget {
  final String name;
  final String size;
  final VoidCallback onRemove;

  const _FilePreviewCard({
    required this.name,
    required this.size,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1F0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _green),
      ),
      child: Row(
        children: [
          // file icon
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: _danger.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: _danger,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // info
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _fp,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$size · Ready to upload',
                  style: GoogleFonts.inter(color: _green, fontSize: 11),
                ),
              ],
            ),
          ),
          // remove
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, color: _fm, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sticky bottom button ───────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const _BottomBar({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bg.withValues(alpha: 0), _bg],
          stops: const [0, 0.35],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: onTap == null
                  ? [_fm, _fm]
                  : [_primary, _primDark],
            ),
            boxShadow: onTap == null
                ? []
                : [
                    BoxShadow(
                      color: _primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              'Upload Material',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// end of file
