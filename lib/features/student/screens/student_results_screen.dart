import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models.dart';
import '../../../shared/widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Student Results Screen — Shows all quiz and test results
// ─────────────────────────────────────────────────────────────────────────────

class StudentResultsScreen extends StatefulWidget {
  const StudentResultsScreen({super.key});

  @override
  State<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends State<StudentResultsScreen> {
  bool _showQuizzes = true; // true = quizzes, false = tests

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final allAttempts = state.myAttempts;
    final allTests = state.allTests;

    // Separate quiz attempts (live_quiz) from test attempts
    final quizAttempts = allAttempts.where((a) {
      final test = allTests.firstWhere((t) => t.id == a.testId, 
          orElse: () => TestModel(
            title: '', 
            subject: '', 
            classId: '', 
            className: '', 
            durationMinutes: 0, 
            questions: []
          ));
      return test.classId == 'live_quiz';
    }).toList();

    final testAttempts = allAttempts.where((a) {
      final test = allTests.firstWhere((t) => t.id == a.testId, 
          orElse: () => TestModel(
            title: '', 
            subject: '', 
            classId: '', 
            className: '', 
            durationMinutes: 0, 
            questions: []
          ));
      return test.classId != 'live_quiz';
    }).toList();

    final displayedAttempts = _showQuizzes ? quizAttempts : testAttempts;

    // Calculate stats
    double avgScore = 0;
    int bestRank = 0;
    if (displayedAttempts.isNotEmpty) {
      final ranked = displayedAttempts.where((a) => a.totalParticipants > 0).toList();
      if (ranked.isNotEmpty) {
        final avgPct = ranked
                .map((a) => 1.0 - ((a.rank - 1) / a.totalParticipants))
                .reduce((a, b) => a + b) /
            ranked.length;
        avgScore = avgPct * 100;
        bestRank = ranked.map((a) => a.rank).reduce((a, b) => a < b ? a : b);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Results',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'View your quiz and test performance',
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Filter tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showQuizzes = true),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: _showQuizzes ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          Icon(
                            Symbols.wifi_tethering,
                            color: _showQuizzes ? Colors.white : AppColors.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Live Quizzes',
                            style: GoogleFonts.poppins(
                              color: _showQuizzes ? Colors.white : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: _showQuizzes ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => setState(() => _showQuizzes = false),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: !_showQuizzes ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          Icon(
                            Symbols.assignment,
                            color: !_showQuizzes ? Colors.white : AppColors.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tests',
                            style: GoogleFonts.poppins(
                              color: !_showQuizzes ? Colors.white : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: !_showQuizzes ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats card
            if (displayedAttempts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: _showQuizzes ? 'Quizzes' : 'Tests',
                        value: '${displayedAttempts.length}',
                        color: AppColors.primary,
                      ),
                      Container(width: 1, height: 40, color: AppColors.border),
                      _StatItem(
                        label: 'Avg Score',
                        value: avgScore > 0 ? '${avgScore.round()}%' : 'N/A',
                        color: AppColors.success,
                      ),
                      Container(width: 1, height: 40, color: AppColors.border),
                      _StatItem(
                        label: 'Best Rank',
                        value: bestRank > 0 ? '#$bestRank' : 'N/A',
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
              ),

            if (displayedAttempts.isNotEmpty) const SizedBox(height: 16),

            // Results list
            Expanded(
              child: displayedAttempts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showQuizzes ? Symbols.wifi_tethering : Symbols.assignment,
                            color: AppColors.textMuted,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _showQuizzes ? 'No quiz results yet' : 'No test results yet',
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _showQuizzes
                                ? 'Join a live quiz to see your results here'
                                : 'Complete a test to see your results here',
                            style: GoogleFonts.poppins(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      itemCount: displayedAttempts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final attempt = displayedAttempts[i];
                        final test = allTests.firstWhere(
                          (t) => t.id == attempt.testId,
                          orElse: () => TestModel(
                            title: attempt.testTitle,
                            subject: 'Unknown',
                            classId: '',
                            className: '',
                            durationMinutes: 0,
                            questions: [],
                          ),
                        );
                        return _ResultCard(
                          attempt: attempt,
                          test: test,
                          index: i,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
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
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ── Result Card Widget ────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final QuizAttempt attempt;
  final TestModel test;
  final int index;

  const _ResultCard({
    required this.attempt,
    required this.test,
    required this.index,
  });

  double get _score {
    if (test.questions.isEmpty) return 0;
    int correct = 0;
    for (final q in test.questions) {
      if (attempt.answers[q.id] == q.correctIndex) correct++;
    }
    return correct / test.questions.length;
  }

  String get _grade {
    final s = _score;
    if (s >= 0.9) return 'A+';
    if (s >= 0.8) return 'A';
    if (s >= 0.7) return 'B';
    if (s >= 0.6) return 'C';
    return 'D';
  }

  Color get _gradeColor {
    final s = _score;
    if (s >= 0.8) return AppColors.success;
    if (s >= 0.6) return AppColors.warning;
    return AppColors.error;
  }

  Color get _rankColor {
    if (attempt.totalParticipants <= 0) return AppColors.textSecondary;
    final pct = 1.0 - ((attempt.rank - 1) / attempt.totalParticipants);
    if (pct >= 0.75) return AppColors.success;
    if (pct >= 0.5) return AppColors.warning;
    return AppColors.error;
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final pct = (_score * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _gradeColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Grade badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _gradeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _gradeColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _grade,
                      style: GoogleFonts.poppins(
                        color: _gradeColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: GoogleFonts.poppins(
                        color: _gradeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Test info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.subject,
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      attempt.testTitle,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      test.className,
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniStat(
                  icon: Symbols.check_circle,
                  label: 'Score',
                  value: '$pct%',
                  color: _gradeColor,
                ),
                Container(width: 1, height: 30, color: AppColors.border),
                _MiniStat(
                  icon: Symbols.emoji_events,
                  label: 'Rank',
                  value: attempt.totalParticipants > 0 ? '#${attempt.rank}' : 'N/A',
                  color: _rankColor,
                ),
                Container(width: 1, height: 30, color: AppColors.border),
                _MiniStat(
                  icon: Symbols.calendar_today,
                  label: 'Date',
                  value: _formatDate(attempt.completedAt),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: -0.1, end: 0);
  }
}

// ── Mini Stat Widget ──────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.textMuted,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
