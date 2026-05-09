import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    final err = await context.read<AppState>().changePassword(
      currentPassword: _currentCtrl.text,
      newPassword: _newCtrl.text,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() { _saving = false; _error = err; });
    } else {
      // Show success then pop
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Password changed successfully',
            style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final hPad = screenWidth < 360 ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        // Glow
        Positioned(
          top: -60, right: -60,
          child: Container(
            width: 240, height: 240,
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

                // Back
                GestureDetector(
                  onTap: () => Navigator.pop(context),
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

                const SizedBox(height: 32),

                // Icon + heading
                Center(
                  child: Column(children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Symbols.lock_reset, color: AppColors.success, size: 36),
                    ).animate().scale(
                      begin: const Offset(0.7, 0.7),
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    ),
                    const SizedBox(height: 16),
                    Text('Change Password',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: screenWidth < 360 ? 20 : 22,
                            fontWeight: FontWeight.w700))
                        .animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 6),
                    Text('Enter your current password to continue',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            color: AppColors.textSecondary, fontSize: 13))
                        .animate().fadeIn(delay: 200.ms),
                  ]),
                ),

                const SizedBox(height: 36),

                // Current password
                _buildPasswordField(
                  label: 'Current Password',
                  hint: 'Your current password',
                  controller: _currentCtrl,
                  obscure: _obscureCurrent,
                  onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  delay: 250,
                ),

                const SizedBox(height: 16),

                // Divider with label
                Row(children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('New Password',
                        style: GoogleFonts.poppins(
                            color: AppColors.textMuted, fontSize: 11)),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ]).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 16),

                // New password
                _buildPasswordField(
                  label: 'New Password',
                  hint: 'Min 6 characters',
                  controller: _newCtrl,
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                  delay: 350,
                ),

                const SizedBox(height: 16),

                // Confirm password
                _buildPasswordField(
                  label: 'Confirm New Password',
                  hint: 'Repeat new password',
                  controller: _confirmCtrl,
                  obscure: _obscureConfirm,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v != _newCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                  delay: 400,
                ),

                // Password strength hints
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Password tips',
                        style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...[
                      'At least 6 characters',
                      'Mix letters and numbers',
                      'Avoid using your name or email',
                    ].map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        const Icon(Symbols.check_circle, color: AppColors.textMuted, size: 14),
                        const SizedBox(width: 8),
                        Text(tip,
                            style: GoogleFonts.poppins(
                                color: AppColors.textMuted, fontSize: 12)),
                      ]),
                    )),
                  ]),
                ).animate().fadeIn(delay: 450.ms),

                // Error
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(Symbols.error, color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_error!,
                          style: GoogleFonts.poppins(color: AppColors.error, fontSize: 13))),
                    ]),
                  ),
                ],

                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _saving
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Symbols.lock_reset, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('Update Password',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ]),
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    required int delay,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Symbols.lock, color: AppColors.textMuted, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Symbols.visibility : Symbols.visibility_off,
              color: AppColors.textMuted,
              size: 20,
            ),
            onPressed: onToggle,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    ]).animate().fadeIn(delay: delay.ms).slideY(begin: 0.15, end: 0);
  }
}
