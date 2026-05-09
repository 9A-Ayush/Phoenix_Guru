import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';

// ── Subject model ─────────────────────────────────────────────────────────────

class _Subject {
  final String name;
  final IconData icon;
  final Color color;

  const _Subject(this.name, this.icon, this.color);
}

const _kSubjects = [
  _Subject('Physics',          Symbols.science,       AppColors.primary),
  _Subject('Mathematics',      Symbols.calculate,     Color(0xFF1565C0)),
  _Subject('Chemistry',        Symbols.biotech,       Color(0xFF00897B)),
  _Subject('Biology',          Symbols.eco,           AppColors.success),
  _Subject('History',          Symbols.history_edu,   AppColors.warning),
  _Subject('Geography',        Symbols.public,        Color(0xFF0288D1)),
  _Subject('English',          Symbols.menu_book,     AppColors.accent),
  _Subject('Computer Science', Symbols.computer,      Color(0xFF7C3AED)),
  _Subject('Economics',        Symbols.trending_up,   Color(0xFF00838F)),
  _Subject('Other',            Symbols.school,        AppColors.textSecondary),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();
  int    _subjectIndex = 0;
  bool   _loading  = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  _Subject get _subject => _kSubjects[_subjectIndex];

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AppState>().createClass(
        name:        _nameCtrl.text.trim(),
        subject:     _subject.name,
        description: _descCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Class created!',
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
        // Glow blobs
        Positioned(
          top: -60, right: -60,
          child: Container(
            width: 240, height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_subject.color.withValues(alpha: 0.18), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 80, left: -60,
          child: Container(
            width: 200, height: 200,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x226C47FF), Colors.transparent],
              ),
            ),
          ),
        ),

        SafeArea(
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.chevron_left_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text('Create Class',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),

                // ── Preview card ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _subject.color.withValues(alpha: 0.25),
                            _subject.color.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _subject.color.withValues(alpha: 0.35)),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Row(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: _subject.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(_subject.icon,
                              color: _subject.color, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ValueListenableBuilder(
                                valueListenable: _nameCtrl,
                                builder: (_, __, ___) => Text(
                                  _nameCtrl.text.isEmpty
                                      ? 'Class Name'
                                      : _nameCtrl.text,
                                  style: GoogleFonts.poppins(
                                    color: _nameCtrl.text.isEmpty
                                        ? AppColors.textMuted
                                        : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(_subject.name,
                                  style: GoogleFonts.poppins(
                                      color: _subject.color,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              Row(children: [
                                Icon(Symbols.key,
                                    color: AppColors.textMuted, size: 13),
                                const SizedBox(width: 4),
                                Text('Code auto-generated',
                                    style: GoogleFonts.poppins(
                                        color: AppColors.textMuted,
                                        fontSize: 11)),
                              ]),
                            ],
                          ),
                        ),
                      ]),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                  ),
                ),

                // ── Class name field ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('Class Name'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameCtrl,
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 14),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Class name is required'
                              : null,
                          decoration: InputDecoration(
                            hintText: 'e.g. Physics — Class 12A',
                            prefixIcon: const Icon(Symbols.edit,
                                color: AppColors.textMuted, size: 18),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                        ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.15, end: 0),
                      ],
                    ),
                  ),
                ),

                // ── Subject picker ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('Subject'),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final sub = _kSubjects[i];
                        final active = _subjectIndex == i;
                        return GestureDetector(
                          onTap: () => setState(() => _subjectIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: active
                                  ? sub.color.withValues(alpha: 0.15)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: active
                                    ? sub.color
                                    : AppColors.border,
                                width: active ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(sub.icon,
                                    color: active
                                        ? sub.color
                                        : AppColors.textMuted,
                                    size: 24),
                                const SizedBox(height: 6),
                                Text(sub.name,
                                    style: GoogleFonts.poppins(
                                      color: active
                                          ? sub.color
                                          : AppColors.textSecondary,
                                      fontSize: 10,
                                      fontWeight: active
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ).animate().fadeIn(
                              delay: (200 + i * 30).ms,
                              duration: 300.ms),
                        );
                      },
                      childCount: _kSubjects.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                  ),
                ),

                // ── Description ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('Description  (optional)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 3,
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText:
                                'What will students learn in this class?',
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: AppColors.border)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: AppColors.border)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 2)),
                            filled: true,
                            fillColor: AppColors.surface,
                          ),
                        ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.15, end: 0),
                      ],
                    ),
                  ),
                ),

                // ── Info note ────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                    child: Container(
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
                            'A unique 6-digit join code is auto-generated. Share it with students to let them join.',
                            style: GoogleFonts.poppins(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.4),
                          ),
                        ),
                      ]),
                    ).animate().fadeIn(delay: 430.ms),
                  ),
                ),

                // ── Error ────────────────────────────────────────────────────
                if (_error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          const Icon(Symbols.error,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_error!,
                                style: GoogleFonts.poppins(
                                    color: AppColors.error, fontSize: 13)),
                          ),
                        ]),
                      ),
                    ),
                  ),

                // ── Create button ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 36),
                    child: SizedBox(
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
                                    color: Colors.white, strokeWidth: 2.5))
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
                    ).animate().fadeIn(delay: 480.ms),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500));
  }
}
