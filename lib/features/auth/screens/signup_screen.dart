import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../../student/screens/student_shell.dart';
import '../../teacher/screens/teacher_shell.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  UserRole _role = UserRole.student;
  String? _error;

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final err = await context.read<AppState>().signUp(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text, _role);
    if (!mounted) return;
    if (err != null) { setState(() => _error = err); return; }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => _role == UserRole.teacher ? const TeacherShell() : const StudentShell()),
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
                const SizedBox(height: 80),
                Text('Join Phoenix Guru 🚀',
                    style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 15))
                    .animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 6),
                Text('Create Account',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700))
                    .animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 28),

                AppInput(label: 'Full Name', hint: 'Your name', prefixIcon: Symbols.person,
                    controller: _nameCtrl,
                    validator: (v) => (v == null || v.isEmpty) ? 'Name required' : null)
                    .animate().fadeIn(delay: 150.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 14),
                AppInput(label: 'Email Address', hint: 'you@email.com', prefixIcon: Symbols.mail,
                    controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null)
                    .animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 14),
                AppInput(label: 'Password', hint: '••••••••', prefixIcon: Symbols.lock,
                    obscure: _obscure, controller: _passCtrl,
                    validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
                    suffix: IconButton(
                      icon: Icon(_obscure ? Symbols.visibility : Symbols.visibility_off, color: AppColors.textMuted, size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ))
                    .animate().fadeIn(delay: 250.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 20),
                Row(children: [
                  Text('I am a', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(width: 12),
                  _roleBtn(UserRole.student, 'Student'),
                  const SizedBox(width: 8),
                  _roleBtn(UserRole.teacher, 'Teacher'),
                ]),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(10)),
                    child: Text(_error!, style: GoogleFonts.poppins(color: AppColors.error, fontSize: 13)),
                  ),
                ],

                const SizedBox(height: 24),
                AppButton(label: 'Create Account', onTap: _signUp, loading: loading)
                    .animate().fadeIn(delay: 350.ms),

                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Already have an account?', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('Login', style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
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
        height: 40, width: 100,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(label, style: GoogleFonts.poppins(
            color: active ? Colors.white : AppColors.textSecondary,
            fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w500)),
      ),
    );
  }
}
