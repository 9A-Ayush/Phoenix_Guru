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
import 'help_support_screen.dart';
import 'student_results_screen.dart';
import 'material_cache_manager_screen.dart';

// ── Profile Page ──────────────────────────────────────────────────────────────
class StudentProfilePage extends StatelessWidget {
  final void Function(int)? onTabChange;
  const StudentProfilePage({super.key, this.onTabChange});

  // ── Compute avg score — rank-based since score() needs questions list ────────
  String _avgScore(List<QuizAttempt> attempts) {
    if (attempts.isEmpty) return 'N/A';
    // Use rank/totalParticipants as a percentile proxy
    final ranked = attempts.where((a) => a.totalParticipants > 0).toList();
    if (ranked.isEmpty) return '${attempts.length} done';
    final avgPct = ranked
            .map((a) => 1.0 - ((a.rank - 1) / a.totalParticipants))
            .reduce((a, b) => a + b) /
        ranked.length;
    return '${(avgPct * 100).toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser!;
    final attempts = state.myAttempts;
    final classes = state.myClasses;

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
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen())),
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  UserAvatar(
                    initials: user.avatarInitials,
                    photoUrl: user.photoUrl,
                    radius: 40,
                    fontSize: 28,
                  ),
                  Positioned(
                    bottom: -10,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF34D399), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.bg, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Symbols.school, color: Colors.white, size: 11),
                        const SizedBox(width: 4),
                        Text('STUDENT',
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
            ),
            const SizedBox(height: 22),
            Text(user.name,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(user.email,
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 13)),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            // ── Stats row ────────────────────────────────────────────────────
            Container(
              height: 72,
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                _stat('${classes.length}', 'Classes', AppColors.primary),
                Container(width: 1, height: 40, color: AppColors.border),
                _stat('${attempts.length}', 'Tests Done', AppColors.warning),
                Container(width: 1, height: 40, color: AppColors.border),
                _stat(_avgScore(attempts), 'Avg Score', AppColors.success),
              ]),
            ),

            const SizedBox(height: 16),

            // ── Menu items ───────────────────────────────────────────────────
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
              icon: Symbols.bar_chart,
              iconColor: AppColors.success,
              label: 'My Results',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const StudentResultsScreen())),
            ),
            const SizedBox(height: 10),
            MenuRow(
              icon: Symbols.storage,
              iconColor: const Color(0xFF8B5CF6),
              label: 'Offline Storage',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const MaterialCacheManagerScreen())),
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
                      builder: (_) => const StudentHelpSupportScreen())),
            ),

            const SizedBox(height: 20),

            // ── Recent Results ───────────────────────────────────────────────
            SectionHeader(
              title: 'Recent Results',
              action: attempts.isEmpty ? null : 'View All',
              onAction: attempts.isEmpty
                  ? null
                  : () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const StudentResultsScreen())),
            ),
            const SizedBox(height: 12),
            if (attempts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No results yet',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary)),
              )
            else
              ...attempts.take(3).map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _QuizResultCard(attempt: a),
                  )),

            const SizedBox(height: 20),

            // ── Logout ───────────────────────────────────────────────────────
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
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  const Icon(Symbols.logout,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Text('Logout',
                      style: GoogleFonts.poppins(
                          color: AppColors.error,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ]),
    );
  }

  Widget _stat(String value, String label, Color color) => Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value,
              style: GoogleFonts.poppins(
                  color: color,
                  fontSize: value.length > 4 ? 16 : 20,
                  fontWeight: FontWeight.w700)),
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

  String get _rankText {
    if (attempt.totalParticipants > 0) {
      return 'Rank #${attempt.rank} of ${attempt.totalParticipants}';
    }
    return 'Completed';
  }

  Color get _rankColor {
    if (attempt.totalParticipants <= 0) return AppColors.textSecondary;
    final pct = 1.0 - ((attempt.rank - 1) / attempt.totalParticipants);
    if (pct >= 0.75) return AppColors.success;
    if (pct >= 0.5) return AppColors.warning;
    return AppColors.error;
  }

  String get _badgeLetter =>
      attempt.testTitle.isNotEmpty
          ? attempt.testTitle[0].toUpperCase()
          : 'Q';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: _rankColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: Text(_badgeLetter,
              style: GoogleFonts.poppins(
                  color: _rankColor,
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
                    fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(_rankText,
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 11)),
          ]),
        ),
        if (attempt.totalParticipants > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _rankColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#${attempt.rank}',
              style: GoogleFonts.poppins(
                  color: _rankColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
          ),
      ]),
    );
  }
}
