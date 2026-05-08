import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import 'login_screen.dart';
import 'role_picker_screen.dart';
import '../../student/screens/student_shell.dart';
import '../../teacher/screens/teacher_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _waitAndNavigate();
  }

  Future<void> _waitAndNavigate() async {
    final state = context.read<AppState>();

    // Run splash animation AND auth initialization in parallel.
    // Splash shows for at least 2.4s (for the animation to play),
    // but waits longer if auth init hasn't finished yet.
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2400)),
      state.initialized.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          // If init takes >8s, give up and go to login.
          debugPrint('Auth initialization timed out');
        },
      ),
    ]);

    if (!mounted) return;
    _navigate();
  }

  void _navigate() {
    final state = context.read<AppState>();
    Widget next;
    if (state.authStatus == AuthStatus.authenticated && state.currentUser != null) {
      next = state.isTeacher ? const TeacherShell() : const StudentShell();
    } else if (state.authStatus == AuthStatus.needsRolePicker) {
      next = const RolePickerScreen();
    } else {
      next = const LoginScreen();
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => next,
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        // Glow top-left
        Positioned(
          top: -80, left: -80,
          child: Container(
            width: 300, height: 300,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x666C47FF), Colors.transparent],
              ),
            ),
          ),
        ),
        // Glow bottom-right
        Positioned(
          bottom: -60, right: -60,
          child: Container(
            width: 340, height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppColors.accent.withOpacity(0.27), Colors.transparent]),
            ),
          ),
        ),
        SafeArea(
          child: Column(children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo box
                  Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(28)),
                    child: const Icon(Symbols.school, color: Colors.white, size: 48),
                  )
                  .animate().scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 400.ms),

                  const SizedBox(height: 24),

                  // Name row
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Phoenix', style: GoogleFonts.poppins(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    Text('Guru', style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 34, fontWeight: FontWeight.w700)),
                  ]).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 12),

                  Text('Smart Learning. Real Results.',
                      style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 15))
                  .animate().fadeIn(delay: 700.ms, duration: 400.ms),

                  const SizedBox(height: 32),

                  // Progress dots
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _dot(active: true, delay: 900),
                    const SizedBox(width: 8),
                    _dot(delay: 1100),
                    const SizedBox(width: 8),
                    _dot(delay: 1300),
                  ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text('v1.0  •  Phoenix Tech',
                  style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 12))
              .animate().fadeIn(delay: 1200.ms),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _dot({bool active = false, int delay = 0}) {
    return Container(
      width: active ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.surface2,
        borderRadius: BorderRadius.circular(4),
      ),
    ).animate().fadeIn(delay: delay.ms, duration: 300.ms);
  }
}
