import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models.dart';
import '../../../core/providers/app_state.dart';
import '../../student/screens/student_shell.dart';
import '../../teacher/screens/teacher_shell.dart';

// ── Role descriptor ───────────────────────────────────────────────────────────

class _RoleOption {
  final UserRole role;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;

  const _RoleOption({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });
}

const _kRoles = [
  _RoleOption(
    role: UserRole.student,
    title: 'Student',
    subtitle: 'Access classes, tests & study materials',
    icon: Icons.menu_book_rounded,
    gradient: [AppColors.primary, Color(0xFF4B2FD4)],
  ),
  _RoleOption(
    role: UserRole.teacher,
    title: 'Teacher',
    subtitle: 'Create classes, assign tests & track progress',
    icon: Icons.school_rounded,
    gradient: [AppColors.accent, Color(0xFFCC4444)],
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class RolePickerScreen extends StatefulWidget {
  const RolePickerScreen({super.key});

  @override
  State<RolePickerScreen> createState() => _RolePickerScreenState();
}

class _RolePickerScreenState extends State<RolePickerScreen> {
  UserRole _selected = UserRole.student;
  bool _saving = false;
  String? _error;

  Future<void> _onContinue() async {
    setState(() { _saving = true; _error = null; });
    final err = await context.read<AppState>().saveGoogleUserRole(_selected);
    if (!mounted) return;
    if (err != null) {
      setState(() { _saving = false; _error = err; });
      return;
    }
    final isTeacher = _selected == UserRole.teacher;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => isTeacher ? const TeacherShell() : const StudentShell(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AppState>().currentUser;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        // Glow top-left
        Positioned(
          left: -80, top: -80,
          child: Container(
            width: 280, height: 280,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x556C47FF), Colors.transparent],
              ),
            ),
          ),
        ),
        // Glow bottom-right
        Positioned(
          right: -60, bottom: 200,
          child: Container(
            width: 240, height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.accent.withValues(alpha: 0.25), Colors.transparent],
              ),
            ),
          ),
        ),

        SafeArea(
          child: Column(children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final nav = Navigator.of(context);
                      await context.read<AppState>().logout();
                      if (mounted) nav.pop();
                    },
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  Text('Step 1 of 1',
                      style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: [
                  const SizedBox(height: 16),

                  // Avatar with initials
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface2,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: user?.avatarInitials != null
                        ? Center(
                            child: Text(user!.avatarInitials,
                                style: GoogleFonts.poppins(
                                    color: AppColors.primary,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700)),
                          )
                        : const Icon(Icons.person_rounded, color: AppColors.primary, size: 36),
                  ).animate().scale(begin: const Offset(0.7, 0.7), duration: 400.ms, curve: Curves.easeOut),

                  const SizedBox(height: 10),

                  // Google badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('Signed in with Google',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary, fontSize: 11)),
                    ]),
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 24),

                  // Heading
                  Text('Who are you?',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700))
                      .animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 8),
                  Text('Select your role to personalize your experience',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 14, height: 1.4))
                      .animate().fadeIn(delay: 280.ms),

                  const SizedBox(height: 28),

                  // Role cards
                  ...List.generate(_kRoles.length, (i) {
                    final opt = _kRoles[i];
                    final active = _selected == opt.role;
                    return Padding(
                      padding: EdgeInsets.only(bottom: i < _kRoles.length - 1 ? 12 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = opt.role),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: active ? AppColors.primary : AppColors.border,
                              width: active ? 2 : 1,
                            ),
                            boxShadow: active
                                ? [BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.18),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  )]
                                : [],
                          ),
                          child: Row(children: [
                            // Icon container
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: opt.gradient,
                                ),
                              ),
                              child: Icon(opt.icon, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 16),
                            // Text
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(opt.title,
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 3),
                                Text(opt.subtitle,
                                    style: GoogleFonts.poppins(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                        height: 1.4)),
                              ],
                            )),
                            const SizedBox(width: 12),
                            // Radio indicator
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: active ? AppColors.primary : Colors.transparent,
                                border: Border.all(
                                  color: active ? AppColors.primary : AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: active
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                                  : null,
                            ),
                          ]),
                        ),
                      ).animate().fadeIn(delay: (300 + i * 80).ms).slideY(begin: 0.15, end: 0),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Settings note
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 13),
                    const SizedBox(width: 6),
                    Text('You can change this later in settings',
                        style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 12)),
                  ]).animate().fadeIn(delay: 500.ms),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_error!,
                          style: GoogleFonts.poppins(color: AppColors.error, fontSize: 13)),
                    ),
                  ],

                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ]),
        ),

        // Sticky bottom button
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), AppColors.bg],
                stops: [0.0, 0.4],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
            child: GestureDetector(
              onTap: _saving ? null : _onContinue,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primary, Color(0xFF4B2FD4)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: _saving
                    ? const Center(child: SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      ))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(
                          'Continue as ${_kRoles.firstWhere((r) => r.role == _selected).title}',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 18),
                      ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
