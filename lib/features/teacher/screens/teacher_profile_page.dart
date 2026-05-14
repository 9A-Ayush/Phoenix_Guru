import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/widgets/feedback_form_screen.dart';
import '../../auth/screens/login_screen.dart';
import 'edit_profile_screen.dart';
import 'material_upload_screen.dart';
import 'notifications_screen.dart';
import 'help_support_screen.dart';

// ── Profile Page ──────────────────────────────────────────────────────────────

class TeacherProfilePage extends StatelessWidget {
  const TeacherProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;

    if (user == null) return const SizedBox.shrink();

    final classes = state.myClasses;
    final tests = state.allTests;

    return SingleChildScrollView(
      child: Column(children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          height: 240 + MediaQuery.of(context).padding.top,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF1C1240), AppColors.bg],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(height: 40 + MediaQuery.of(context).padding.top),
            Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                GradientAvatar(
                    initials: user.avatarInitials, radius: 40, fontSize: 28),
                Positioned(
                  bottom: -10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9B7BFF), Color(0xFF5B2FD4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.bg, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Symbols.school, color: Colors.white, size: 11),
                      const SizedBox(width: 4),
                      Text('TEACHER',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5)),
                    ]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(user.name,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            Text(user.email,
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 13)),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            // ── Stats ────────────────────────────────────────────────────────
            Container(
              height: 72,
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                _stat('${classes.length}', 'Classes', AppColors.primary),
                Container(width: 1, height: 40, color: AppColors.border),
                _stat(
                    '${classes.fold(0, (s, c) => s + c.studentCount)}',
                    'Students',
                    AppColors.warning),
                Container(width: 1, height: 40, color: AppColors.border),
                _stat('${tests.length}', 'Tests', AppColors.success),
              ]),
            ),

            const SizedBox(height: 16),

            // ── Menu ─────────────────────────────────────────────────────────
            MenuRow(
              icon: Symbols.person,
              iconColor: AppColors.primary,
              label: 'Edit Profile',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const EditProfileScreen())),
            ),
            const SizedBox(height: 10),
            MenuRow(
              icon: Symbols.upload_file,
              iconColor: AppColors.success,
              label: 'Upload Material',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const MaterialUploadScreen())),
            ),
            const SizedBox(height: 10),
            MenuRow(
              icon: Symbols.notifications,
              iconColor: AppColors.warning,
              label: 'Notifications',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen())),
            ),
            const SizedBox(height: 10),
            MenuRow(
              icon: Symbols.edit_square,
              iconColor: AppColors.primary,
              label: 'Submit Feedback',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const FeedbackFormScreen())),
            ),
            const SizedBox(height: 10),
            MenuRow(
              icon: Symbols.help,
              iconColor: AppColors.textSecondary,
              label: 'Help & Support',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const HelpSupportScreen())),
            ),

            const SizedBox(height: 20),

            // ── Logout ────────────────────────────────────────────────────────
            GestureDetector(
              onTap: () {
                context.read<AppState>().logout();
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false);
              },
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Symbols.logout, color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Text('Logout',
                      style: GoogleFonts.poppins(
                          color: AppColors.error,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ]),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Expanded(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value,
            style: GoogleFonts.poppins(
                color: color, fontSize: 20, fontWeight: FontWeight.w700)),
        Text(label,
            style: GoogleFonts.poppins(
                color: AppColors.textSecondary, fontSize: 11)),
      ]),
    );
  }
}
