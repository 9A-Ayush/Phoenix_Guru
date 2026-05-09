import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../shared/widgets/widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  bool _saving = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().currentUser!;
    _nameCtrl = TextEditingController(text: user.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; _success = null; });
    final err = await context.read<AppState>().updateProfile(name: _nameCtrl.text.trim());
    if (!mounted) return;
    if (err != null) {
      setState(() { _saving = false; _error = err; });
    } else {
      setState(() { _saving = false; _success = 'Profile updated successfully'; });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser!;
    final screenWidth = MediaQuery.of(context).size.width;
    final avatarRadius = screenWidth < 360 ? 44.0 : 52.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        // Glow top-left
        Positioned(
          top: -60, left: -60,
          child: Container(
            width: 260, height: 260,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x446C47FF), Colors.transparent],
              ),
            ),
          ),
        ),
        // Glow bottom-right
        Positioned(
          bottom: 60, right: -60,
          child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.accent.withValues(alpha: 0.15), Colors.transparent],
              ),
            ),
          ),
        ),

        SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth < 360 ? 16 : 24,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 12),

                // Back button
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

                // Avatar section
                Center(
                  child: Column(children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        GradientAvatar(
                          initials: user.avatarInitials,
                          radius: avatarRadius,
                          fontSize: avatarRadius * 0.52,
                        ),
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.bg, width: 2),
                          ),
                          child: const Icon(Symbols.edit, color: Colors.white, size: 14),
                        ),
                      ],
                    ).animate().scale(
                      begin: const Offset(0.8, 0.8),
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    ),
                    const SizedBox(height: 12),
                    Text(user.name,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: screenWidth < 360 ? 18 : 20,
                            fontWeight: FontWeight.w700))
                        .animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Symbols.school, color: AppColors.primary, size: 13),
                        const SizedBox(width: 5),
                        Text('Teacher',
                            style: GoogleFonts.poppins(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ).animate().fadeIn(delay: 200.ms),
                  ]),
                ),

                const SizedBox(height: 36),

                // Section label
                Text('Personal Information',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8))
                    .animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 12),

                // Name field
                _FieldLabel('Full Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    if (v.trim().length < 2) return 'Name too short';
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Your full name',
                    prefixIcon: const Icon(Symbols.person, color: AppColors.textMuted, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15, end: 0),

                const SizedBox(height: 16),

                // Email (read-only)
                _FieldLabel('Email Address'),
                const SizedBox(height: 8),
                Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    const Icon(Symbols.mail, color: AppColors.textMuted, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(user.email,
                          style: GoogleFonts.poppins(
                              color: AppColors.textMuted, fontSize: 14)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Locked',
                          style: GoogleFonts.poppins(
                              color: AppColors.textMuted, fontSize: 10)),
                    ),
                  ]),
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.15, end: 0),

                const SizedBox(height: 16),

                // Role (read-only)
                _FieldLabel('Role'),
                const SizedBox(height: 8),
                Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    const Icon(Symbols.school, color: AppColors.textMuted, size: 20),
                    const SizedBox(width: 12),
                    Text('Teacher',
                        style: GoogleFonts.poppins(
                            color: AppColors.textMuted, fontSize: 14)),
                  ]),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15, end: 0),

                // Error / success
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
                if (_success != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(Symbols.check_circle, color: AppColors.success, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_success!,
                          style: GoogleFonts.poppins(color: AppColors.success, fontSize: 13))),
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
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _saving
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Symbols.save, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('Save Changes',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ]),
                  ),
                ).animate().fadeIn(delay: 450.ms),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

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
