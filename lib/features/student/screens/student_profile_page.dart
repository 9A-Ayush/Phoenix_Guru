import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/widgets/feedback_form_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../teacher/screens/edit_profile_screen.dart';
import '../../teacher/screens/notifications_screen.dart';
import '../quiz/quiz_screens.dart';
import 'help_support_screen.dart';

// ── Profile Page ──────────────────────────────────────────────────────────────
class StudentProfilePage extends StatelessWidget {
  final void Function(int)? onTabChange;
  const StudentProfilePage({super.key, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser!;
    final attempts = state.myAttempts;

    return SingleChildScrollView(
        child: Column(children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            height: 260,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF1C1240), AppColors.bg],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(height: 50),
              UserAvatar(
                initials: user.avatarInitials,
                photoUrl: user.photoUrl,
                radius: 40,
                fontSize: 28,
                badgeLabel: 'S',
                badgeColor: AppColors.success,
              ),
              const SizedBox(height: 16),
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
              // ── Stats row ──────────────────────────────────────────────────
              Container(
                height: 72,
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  _stat('${context.read<AppState>().myClasses.length}', 'Classes', AppColors.primary),
                  Container(width: 1, height: 40, color: AppColors.border),
                  _stat('${attempts.length}', 'Tests Done', AppColors.warning),
                  Container(width: 1, height: 40, color: AppColors.border),
                  _stat('84%', 'Avg Score', AppColors.success),
                ]),
              ),

              const SizedBox(height: 16),

              // ── Menu items ─────────────────────────────────────────────────
              MenuRow(
                icon: Symbols.person,
                iconColor: AppColors.primary,
                label: 'Edit Profile',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen())),
              ),
              const SizedBox(height: 10),
              MenuRow(
                icon: Symbols.notifications,
                iconColor: AppColors.warning,
                label: 'Notifications',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              ),
              const SizedBox(height: 10),
              MenuRow(
                icon: Symbols.edit_square,
                iconColor: AppColors.primary,
                label: 'Submit Feedback',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const FeedbackFormScreen())),
              ),
              const SizedBox(height: 10),
              MenuRow(
                icon: Symbols.help,
                iconColor: AppColors.textSecondary,
                label: 'Help & Support',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const StudentHelpSupportScreen())),
              ),

              const SizedBox(height: 20),

              // ── Quiz Results ───────────────────────────────────────────────
              SectionHeader(
                title: 'My Quiz Results',
                action: 'View All',
                onAction: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const QuizResultsListScreen())),
              ),
              const SizedBox(height: 12),
              if (attempts.isEmpty)
                Text('No quiz attempts yet',
                    style:
                        GoogleFonts.poppins(color: AppColors.textSecondary))
              else
                ...attempts.take(2).map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _QuizResultCard(attempt: a),
                    )),

              const SizedBox(height: 20),

              // ── Logout ─────────────────────────────────────────────────────
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

  Widget _stat(String value, String label, Color color) => Expanded(
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

// ── Quiz Result Card ──────────────────────────────────────────────────────────
class _QuizResultCard extends StatelessWidget {
  final QuizAttempt attempt;
  const _QuizResultCard({required this.attempt});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: Text('A',
              style: GoogleFonts.poppins(
                  color: AppColors.success,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Text(attempt.testTitle,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            Text('Rank #${attempt.rank} of ${attempt.totalParticipants}',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 11)),
          ]),
        ),
        Text('84%',
            style: GoogleFonts.poppins(
                color: AppColors.success,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
