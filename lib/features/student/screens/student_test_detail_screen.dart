import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../quiz/quiz_screens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Student Test Detail Screen
// Shows test information, attempts, expiry, and allows starting the test
// ─────────────────────────────────────────────────────────────────────────────

class StudentTestDetailScreen extends StatelessWidget {
  final TestModel test;
  const StudentTestDetailScreen({super.key, required this.test});

  String _formatDateTime(DateTime? d) {
    if (d == null) return 'Not set';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day} ${months[d.month - 1]} ${d.year}, $hour:${d.minute.toString().padLeft(2, '0')} $ampm';
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'No expiry';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final attemptCount = state.myAttempts.where((a) => a.testId == test.id).length;
    final maxAttemptsReached = attemptCount >= test.maxAttempts;
    final isExpired = test.isExpired;
    final isLocked = maxAttemptsReached || isExpired;
    final attemptsLeft = test.maxAttempts - attemptCount;

    // Calculate best score from previous attempts
    final myAttempts = state.myAttempts.where((a) => a.testId == test.id).toList();
    double? bestScore;
    if (myAttempts.isNotEmpty) {
      bestScore = myAttempts.map((a) => a.score(test.questions)).reduce((a, b) => a > b ? a : b);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Background gradient
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    isLocked ? AppColors.error.withOpacity(0.15) : AppColors.primary.withOpacity(0.15),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const AppBackButton(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Test Details',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Test Title Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isLocked 
                                ? [AppColors.error.withOpacity(0.2), AppColors.error.withOpacity(0.05)]
                                : [AppColors.primary.withOpacity(0.2), AppColors.accent.withOpacity(0.05)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isLocked 
                                ? AppColors.error.withOpacity(0.3) 
                                : AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isLocked ? AppColors.errorLight : AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      test.subject.toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        color: isLocked ? AppColors.error : AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isLocked ? AppColors.errorLight : AppColors.successLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isLocked ? Symbols.lock : Symbols.lock_open,
                                          size: 14,
                                          color: isLocked ? AppColors.error : AppColors.success,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          maxAttemptsReached 
                                            ? 'Completed' 
                                            : (isExpired ? 'Expired' : 'Available'),
                                          style: GoogleFonts.poppins(
                                            color: isLocked ? AppColors.error : AppColors.success,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                test.title,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                test.className,
                                style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms),

                        const SizedBox(height: 24),

                        // Test Information
                        Text(
                          'Test Information',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _InfoCard(
                          icon: Symbols.help,
                          label: 'Total Questions',
                          value: '${test.questionCount}',
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 10),

                        _InfoCard(
                          icon: Symbols.schedule,
                          label: 'Duration',
                          value: '${test.durationMinutes} minutes',
                          color: AppColors.accent,
                        ),
                        const SizedBox(height: 10),

                        _InfoCard(
                          icon: Symbols.replay,
                          label: 'Allowed Attempts',
                          value: '${test.maxAttempts}',
                          color: AppColors.warning,
                        ),
                        const SizedBox(height: 10),

                        _InfoCard(
                          icon: Symbols.history,
                          label: 'Attempts Used',
                          value: '$attemptCount / ${test.maxAttempts}',
                          color: attemptCount >= test.maxAttempts ? AppColors.error : AppColors.success,
                        ),
                        const SizedBox(height: 10),

                        if (!isLocked)
                          _InfoCard(
                            icon: Symbols.trending_up,
                            label: 'Attempts Remaining',
                            value: '$attemptsLeft',
                            color: attemptsLeft == 1 ? AppColors.warning : AppColors.success,
                          ),
                        
                        if (!isLocked) const SizedBox(height: 10),

                        if (test.scheduledAt != null)
                          _InfoCard(
                            icon: Symbols.event,
                            label: 'Scheduled At',
                            value: _formatDateTime(test.scheduledAt),
                            color: AppColors.primary,
                          ),
                        
                        if (test.scheduledAt != null) const SizedBox(height: 10),

                        _InfoCard(
                          icon: isExpired ? Symbols.event_busy : Symbols.event_available,
                          label: 'Expires On',
                          value: _formatDate(test.expiresAt),
                          color: isExpired ? AppColors.error : AppColors.textSecondary,
                        ),

                        const SizedBox(height: 24),

                        // Previous Attempts Section
                        if (myAttempts.isNotEmpty) ...[
                          Text(
                            'Your Performance',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.border,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _StatItem(
                                      label: 'Attempts',
                                      value: '$attemptCount',
                                      color: AppColors.primary,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: AppColors.border,
                                    ),
                                    _StatItem(
                                      label: 'Best Score',
                                      value: '${(bestScore! * 100).round()}%',
                                      color: AppColors.success,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 200.ms),

                          const SizedBox(height: 24),
                        ],

                        // Important Notes
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.warning.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Symbols.info,
                                    color: AppColors.warning,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Important Notes',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.warning,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _NoteItem('Anti-cheat system is active during the test'),
                              _NoteItem('Do not leave the test screen'),
                              _NoteItem('Test will be locked after maximum attempts'),
                              if (test.expiresAt != null)
                                _NoteItem('Test expires on ${_formatDate(test.expiresAt)}'),
                            ],
                          ),
                        ).animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: 24),

                        // Start Test Button
                        if (isLocked)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.errorLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.error.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Symbols.lock,
                                  color: AppColors.error,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    maxAttemptsReached
                                      ? 'You have used all ${test.maxAttempts} attempts for this test.'
                                      : 'This test has expired and is no longer available.',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.error,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().shake(duration: 500.ms)
                        else
                          AppButton(
                            label: attemptCount > 0 ? 'Retake Test' : 'Start Test',
                            icon: Symbols.play_arrow,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TestAttemptScreen(test: test),
                                ),
                              );
                            },
                          ).animate().fadeIn(delay: 400.ms),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _NoteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: const BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: AppColors.warning,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Card Widget ──────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0);
  }
}

// ── Stat Item Widget ──────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
