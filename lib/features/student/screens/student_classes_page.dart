import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models.dart';
import '../../../shared/widgets/widgets.dart';

// ── Classes Page ──────────────────────────────────────────────────────────────
class StudentClassesPage extends StatefulWidget {
  const StudentClassesPage({super.key});
  @override
  State<StudentClassesPage> createState() => _StudentClassesPageState();
}

class _StudentClassesPageState extends State<StudentClassesPage> {
  void _showJoinSheet() => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => const _JoinClassSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<AppState>().myClasses;
    return SafeArea(
      bottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('My Classes',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            GestureDetector(
              onTap: _showJoinSheet,
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Symbols.add, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text('Join Class',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: classes.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Symbols.menu_book,
                        color: AppColors.textMuted, size: 48),
                    const SizedBox(height: 12),
                    Text('No classes yet',
                        style: GoogleFonts.poppins(
                            color: AppColors.textSecondary, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Join a class with a code from your teacher',
                        style: GoogleFonts.poppins(
                            color: AppColors.textMuted, fontSize: 13),
                        textAlign: TextAlign.center),
                  ]),
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: classes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final cls = classes[i];
                    return ClassListTile(
                      icon: _icon(cls.subject),
                      iconColor: _color(i),
                      name: cls.name,
                      subtitle:
                          '${cls.teacherName} • ${cls.studentCount} students',
                    ).animate().fadeIn(delay: (i * 60).ms);
                  },
                ),
        ),
      ]),
    );
  }

  IconData _icon(String s) {
    if (s.toLowerCase().contains('physics')) return Symbols.science;
    if (s.toLowerCase().contains('math')) return Symbols.calculate;
    if (s.toLowerCase().contains('hist')) return Symbols.history_edu;
    return Symbols.school;
  }

  Color _color(int i) {
    const c = [AppColors.primary, AppColors.warning, AppColors.success, AppColors.accent];
    return c[i % c.length];
  }
}

// ── Join Class Sheet ──────────────────────────────────────────────────────────
class _JoinClassSheet extends StatefulWidget {
  const _JoinClassSheet();
  @override
  State<_JoinClassSheet> createState() => _JoinClassSheetState();
}

class _JoinClassSheetState extends State<_JoinClassSheet> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  String? _error;
  bool _loading = false;
  ClassModel? _preview;

  String get _code =>
      _ctrl.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    final clean = v.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final code = clean.length > 6 ? clean.substring(0, 6) : clean;
    if (code != _ctrl.text) {
      _ctrl.value = TextEditingValue(
        text: code,
        selection: TextSelection.collapsed(offset: code.length),
      );
    }
    setState(() {
      _preview =
          code.length == 6 ? context.read<AppState>().classForCode(code) : null;
    });
  }

  Future<void> _join() async {
    if (_code.length < 6) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await context.read<AppState>().joinClass(_code);
    if (!mounted) return;
    setState(() { _loading = false; });
    if (err != null) {
      setState(() { _error = err; });
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final code = _code;
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.35),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                    width: 64,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Text('Join a Class',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Enter the 6-digit code shared by your teacher',
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),

              // ── 6 display boxes ─────────────────────────────────────────
              GestureDetector(
                onTap: () => _focus.requestFocus(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    final filled = i < code.length;
                    final active = i == code.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 44,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: filled || active
                              ? AppColors.primary
                              : AppColors.border,
                          width: active ? 2 : (filled ? 1.5 : 1),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        filled ? code[i] : '',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700),
                      ),
                    );
                  }),
                ),
              ),

              // ── Hidden text field (captures input + paste) ──────────────
              SizedBox(
                height: 0,
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  autofocus: true,
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Colors.transparent, fontSize: 1),
                  cursorColor: Colors.transparent,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  onChanged: _onChanged,
                ),
              ),

              // ── Class preview ────────────────────────────────────────────
              if (_preview != null) ...[
                const SizedBox(height: 14),
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Symbols.school,
                            color: AppColors.primary, size: 22)),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Text(_preview!.name,
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          Text(_preview!.teacherName,
                              style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary, fontSize: 12)),
                        ])),
                    const Icon(Symbols.check_circle,
                        color: AppColors.success, size: 22),
                  ]),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style:
                        GoogleFonts.poppins(color: AppColors.error, fontSize: 13)),
              ],

              const SizedBox(height: 14),
              AppButton(label: 'Join Class', onTap: _join, loading: _loading),
            ]),
      ),
    );
  }
}
