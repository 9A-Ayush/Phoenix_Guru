import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../shared/widgets/widgets.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedSubject = 'Physics';
  bool   _loading = false;
  String? _error;

  static const _subjects = [
    'Physics', 'Mathematics', 'Chemistry', 'Biology',
    'History', 'Geography', 'English', 'Computer Science',
    'Economics', 'Other',
  ];

  @override
  void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AppState>().createClass(
        name:        _nameCtrl.text.trim(),
        subject:     _selectedSubject,
        description: _descCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Class created successfully!',
            style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final hPad = sw < 360 ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        // Glow top-right
        Positioned(
          top: -80, right: -80,
          child: Container(
            width: 260, height: 260,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x336C47FF), Colors.transparent],
              ),
            ),
          ),
        ),

        SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 12),
                const AppBackButton(),
                const SizedBox(height: 32),

                // Icon + heading
                Center(
                  child: Column(children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Symbols.school,
                          color: AppColors.primary, size: 36),
                    ).animate().scale(
                        begin: const Offset(0.5, 0.5),
                        duration: 500.ms,
                        curve: Curves.elasticOut),
                    const SizedBox(height: 16),
                    Text('Create Class',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700))
                        .animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 4),
                    Text('Set up your new class',
                        style: GoogleFonts.poppins(
                            color: AppColors.textSecondary, fontSize: 13))
                        .animate().fadeIn(delay: 250.ms),
                  ]),
                ),

                const SizedBox(height: 32),

                // Class Name
                _Label('Class Name *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Class name is required' : null,
                  decoration: InputDecoration(
                    hintText: 'e.g. Physics — Class 12A',
                    prefixIcon: const Icon(Symbols.edit,
                        color: AppColors.textMuted, size: 18),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 16),

                // Subject dropdown
                _Label('Subject *'),
                const SizedBox(height: 8),
                _SubjectDropdown(
                  value: _selectedSubject,
                  subjects: _subjects,
                  onChanged: (v) =>
                      setState(() => _selectedSubject = v ?? _selectedSubject),
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 16),

                // Description
                _Label('Description'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Brief description of what this class covers...',
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 2)),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 16),

                // Info note
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x116C47FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Symbols.info,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'A 6-digit join code will be auto-generated for students',
                        style: GoogleFonts.poppins(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ]),
                ).animate().fadeIn(delay: 450.ms),

                // Error
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(_error!,
                        style: GoogleFonts.poppins(
                            color: AppColors.error, fontSize: 13)),
                  ),
                ],

                const SizedBox(height: 24),

                // Create button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _create,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Symbols.add,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text('Create Class',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                  ),
                ).animate().fadeIn(delay: 500.ms)
                    .scale(begin: const Offset(0.95, 0.95)),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Field label ───────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text,
          style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500)),
    );
  }
}

// ── Subject dropdown ──────────────────────────────────────────────────────────

class _SubjectDropdown extends StatelessWidget {
  final String value;
  final List<String> subjects;
  final void Function(String?) onChanged;

  const _SubjectDropdown({
    required this.value,
    required this.subjects,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppColors.surface2,
          icon: const Icon(Symbols.keyboard_arrow_down,
              color: AppColors.textMuted, size: 18),
          isExpanded: true,
          items: subjects.map((s) => DropdownMenuItem(
            value: s,
            child: Row(children: [
              Icon(_icon(s), color: AppColors.primary, size: 18),
              const SizedBox(width: 12),
              Text(s,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ]),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  IconData _icon(String s) {
    switch (s) {
      case 'Physics':          return Symbols.science;
      case 'Mathematics':      return Symbols.calculate;
      case 'Chemistry':        return Symbols.biotech;
      case 'Biology':          return Symbols.eco;
      case 'History':          return Symbols.history_edu;
      case 'Geography':        return Symbols.public;
      case 'English':          return Symbols.menu_book;
      case 'Computer Science': return Symbols.computer;
      case 'Economics':        return Symbols.trending_up;
      default:                 return Symbols.school;
    }
  }
}
