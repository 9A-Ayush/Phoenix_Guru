import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models.dart';
import '../../../shared/widgets/widgets.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../../student/screens/student_shell.dart';
import '../../teacher/screens/teacher_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  UserRole _role = UserRole.student;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final state = context.read<AppState>();
    final err = await state.login(_emailCtrl.text.trim(), _passCtrl.text, _role);
    if (!mounted) return;
    if (err != null) { setState(() => _error = err); return; }
    // Use server-side role from AppState (not local _role) for navigation consistency.
    final isTeacher = state.currentUser!.role == UserRole.teacher;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => isTeacher ? const TeacherShell() : const StudentShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<AppState, bool>((s) => s.isLoading);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        Positioned(top: -80, left: -80,
          child: Container(width: 300, height: 300,
            decoration: const BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Color(0x556C47FF), Colors.transparent])))),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(key: _formKey, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 90),
                Text('Welcome Back 👋',
                    style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 16))
                    .animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 8),
                Text('Login to your account',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700))
                    .animate().fadeIn(delay: 100.ms, duration: 400.ms),

                const SizedBox(height: 32),

                AppInput(
                  label: 'Email Address', hint: 'you@email.com',
                  prefixIcon: Symbols.mail,
                  controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter valid email' : null,
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 16),
                AppInput(
                  label: 'Password', hint: '••••••••',
                  prefixIcon: Symbols.lock, obscure: _obscure,
                  controller: _passCtrl,
                  validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  suffix: IconButton(
                    icon: Icon(_obscure ? Symbols.visibility : Symbols.visibility_off, color: AppColors.textMuted, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                    child: Text('Forgot Password?',
                        style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(10)),
                    child: Text(_error!, style: GoogleFonts.poppins(color: AppColors.error, fontSize: 13)),
                  ),
                ],

                const SizedBox(height: 24),
                AppButton(label: 'Login', onTap: _login, loading: loading)
                    .animate().fadeIn(delay: 400.ms, duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),

                const SizedBox(height: 24),
                Row(children: const [
                  Expanded(child: Divider(color: AppColors.border)),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(color: AppColors.textMuted))),
                  Expanded(child: Divider(color: AppColors.border)),
                ]),
                const SizedBox(height: 16),

                // Role selector
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Login as:', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(width: 12),
                  _roleBtn(UserRole.teacher, 'Teacher'),
                  const SizedBox(width: 8),
                  _roleBtn(UserRole.student, 'Student'),
                ]),

                const SizedBox(height: 32),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text("Don't have an account?", style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: Text('Sign Up', style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 32),
              ],
            )),
          ),
        ),
      ]),
    );
  }

  Widget _roleBtn(UserRole role, String label) {
    final active = _role == role;
    return GestureDetector(
      onTap: () => setState(() => _role = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36, width: 90,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: GoogleFonts.poppins(
                color: active ? Colors.white : AppColors.textSecondary,
                fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w500)),
      ),
    );
  }
}
