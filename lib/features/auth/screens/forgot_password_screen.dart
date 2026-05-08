import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../shared/widgets/widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final err = await context.read<AppState>().forgotPassword(_emailCtrl.text.trim());
    if (!mounted) return;
    setState(() { _loading = false; if (err != null) _error = err; else _sent = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        Positioned(top: -100, left: 80,
          child: Container(width: 280, height: 280,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppColors.accent.withOpacity(0.27), Colors.transparent])))),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(key: _formKey, child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Align(alignment: Alignment.centerLeft, child: const AppBackButton()),
                const SizedBox(height: 60),

                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(28)),
                  child: const Icon(Symbols.lock_reset, color: AppColors.primary, size: 48),
                ).animate().scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.elasticOut),

                const SizedBox(height: 28),
                Text('Forgot Password?',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700))
                    .animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 10),
                Text("Enter your email and we'll send you a reset link",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14))
                    .animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 36),

                if (!_sent) ...[
                  AppInput(
                    label: 'Email Address', hint: 'you@email.com',
                    prefixIcon: Symbols.mail, controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@')) ? 'Enter valid email' : null,
                  ).animate().fadeIn(delay: 350.ms),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(10)),
                      child: Text(_error!, style: GoogleFonts.poppins(color: AppColors.error, fontSize: 13)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  AppButton(label: 'Send Reset Link', onTap: _send, loading: _loading)
                      .animate().fadeIn(delay: 400.ms),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.success.withOpacity(0.3))),
                    child: Row(children: [
                      const Icon(Symbols.check_circle, color: AppColors.success, size: 22),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Reset link sent! Check your inbox.',
                          style: GoogleFonts.poppins(color: AppColors.success, fontSize: 14))),
                    ]),
                  ).animate().scale(begin: const Offset(0.9, 0.9), duration: 400.ms),
                  const SizedBox(height: 24),
                  AppButton(label: 'Back to Login', onTap: () => Navigator.pop(context)),
                ],

                const SizedBox(height: 24),
                Container(
                  height: 64, padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    const Icon(Symbols.info, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Check your inbox for the reset link. It expires in 15 minutes.',
                          style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
                    ),
                  ]),
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 32),
              ],
            )),
          ),
        ),
      ]),
    );
  }
}
