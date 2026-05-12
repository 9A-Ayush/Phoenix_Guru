import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models.dart';
import '../../../core/providers/app_state.dart';

// ── Entry point ───────────────────────────────────────────────────────────────
// Can be opened from TeacherQuizPage (shows all tests) or from a specific test.

class TeacherTestResultsScreen extends StatelessWidget {
  /// If provided, shows results for this specific test only.
  /// If null, shows a list of all tests to pick from.
  final TestModel? test;

  const TeacherTestResultsScreen({super.key, this.test});

  @override
  Widget build(BuildContext context) {
    if (test != null) {
      return _TestResultDetail(test: test!);
    }
    return const _TestPicker();
  }
}

// ── Test picker (when no test is pre-selected) ────────────────────────────────

class _TestPicker extends StatelessWidget {
  const _TestPicker();

  @override
  Widget build(BuildContext context) {
    final tests = context.watch<AppState>().allTests;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          _Header(title: 'Test Results', subtitle: '${tests.length} tests'),
          Expanded(
            child: tests.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Symbols.bar_chart, color: AppColors.textMuted, size: 52),
                      const SizedBox(height: 12),
                      Text('No tests yet',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Create and publish a test first',
                          style: GoogleFonts.poppins(
                              color: AppColors.textMuted, fontSize: 13)),
                    ]),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: tests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final t = tests[i];
                      final attempts = context
                          .read<AppState>()
                          .attemptsForTest(t.id);
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                _TestResultDetail(test: t),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(children: [
                            Container(
                              width: 46, height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Symbols.assignment,
                                  color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(t.title,
                                        style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(t.className,
                                        style: GoogleFonts.poppins(
                                            color: AppColors.textSecondary,
                                            fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      const Icon(Symbols.person,
                                          color: AppColors.textMuted,
                                          size: 13),
                                      const SizedBox(width: 4),
                                      Text(
                                          '${attempts.length} attempted',
                                          style: GoogleFonts.poppins(
                                              color: AppColors.textMuted,
                                              fontSize: 11)),
                                      const SizedBox(width: 10),
                                      const Icon(Symbols.help,
                                          color: AppColors.textMuted,
                                          size: 13),
                                      const SizedBox(width: 4),
                                      Text(
                                          '${t.questionCount} questions',
                                          style: GoogleFonts.poppins(
                                              color: AppColors.textMuted,
                                              fontSize: 11)),
                                    ]),
                                  ]),
                            ),
                            const Icon(Symbols.chevron_right,
                                color: AppColors.textMuted, size: 20),
                          ]),
                        ).animate().fadeIn(delay: (i * 60).ms),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}

// ── Detail view for a specific test ──────────────────────────────────────────

class _TestResultDetail extends StatelessWidget {
  final TestModel test;
  const _TestResultDetail({required this.test});

  String _grade(double score) {
    if (score >= 0.9) return 'A+';
    if (score >= 0.8) return 'A';
    if (score >= 0.7) return 'B';
    if (score >= 0.6) return 'C';
    return 'D';
  }

  Color _gradeColor(String g) {
    if (g == 'A+' || g == 'A') return AppColors.success;
    if (g == 'B' || g == 'C') return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final attempts = context.watch<AppState>().attemptsForTest(test.id);

    // Compute per-attempt scores
    final scored = attempts.map((a) {
      final s = a.score(test.questions);
      return (
        attempt: a,
        score: s,
        pct: (s * 100).round(),
        grade: _grade(s),
      );
    }).toList()
      ..sort((a, b) => b.pct.compareTo(a.pct));

    final avg = scored.isEmpty
        ? 0
        : scored.fold(0, (s, e) => s + e.pct) ~/ scored.length;
    final highest = scored.isEmpty ? 0 : scored.first.pct;
    final passed = scored.where((e) => e.pct >= 60).length;

    // Flagged questions: answered wrong by >50% of students
    final flagged = test.questions.where((q) {
      if (attempts.isEmpty) return false;
      final wrong =
          attempts.where((a) => a.answers[q.id] != q.correctIndex).length;
      return wrong / attempts.length > 0.5;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          _Header(
            title: test.title,
            subtitle: '${attempts.length} students attempted',
            badge: attempts.isNotEmpty ? 'Completed' : 'No attempts',
            badgeColor:
                attempts.isNotEmpty ? AppColors.success : AppColors.textMuted,
          ),
          Expanded(
            child: attempts.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Symbols.hourglass_empty,
                          color: AppColors.textMuted, size: 52),
                      const SizedBox(height: 12),
                      Text('No attempts yet',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Students haven\'t submitted this test yet',
                          style: GoogleFonts.poppins(
                              color: AppColors.textMuted, fontSize: 13)),
                    ]),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary cards — use intrinsic height, no fixed height
                          IntrinsicHeight(
                            child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  _SummaryCard(
                                      label: 'Avg Score',
                                      value: '$avg%',
                                      icon: Symbols.bar_chart,
                                      color: AppColors.primary),
                                  const SizedBox(width: 10),
                                  _SummaryCard(
                                      label: 'Highest',
                                      value: '$highest%',
                                      icon: Symbols.emoji_events,
                                      color: AppColors.warning),
                                  const SizedBox(width: 10),
                                  _SummaryCard(
                                      label: 'Passed',
                                      value:
                                          '$passed/${scored.length}',
                                      icon: Symbols.check_circle,
                                      color: AppColors.success),
                                ]),
                          ).animate().fadeIn(duration: 400.ms),

                          const SizedBox(height: 20),

                          // Grade distribution
                          Text('Grade Distribution',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          _GradeBar(scored: scored)
                              .animate()
                              .fadeIn(delay: 100.ms),

                          const SizedBox(height: 20),

                          // Student scores
                          Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Student Scores',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700)),
                                Text('${scored.length} total',
                                    style: GoogleFonts.poppins(
                                        color: AppColors.textMuted,
                                        fontSize: 12)),
                              ]),
                          const SizedBox(height: 10),

                          ...scored.asMap().entries.map((e) {
                            final i = e.key;
                            final s = e.value;
                            final initials = s.attempt.userName
                                .split(' ')
                                .take(2)
                                .map((w) => w.isNotEmpty
                                    ? w[0].toUpperCase()
                                    : '')
                                .join();
                            final avatarColors = [
                              AppColors.primary,
                              AppColors.warning,
                              AppColors.accent,
                              AppColors.success,
                              const Color(0xFF1565C0),
                              const Color(0xFF7C3AED),
                            ];
                            final avatarColor =
                                avatarColors[i % avatarColors.length];
                            final gradeColor =
                                _gradeColor(s.grade);

                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 10),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  border: Border.all(
                                      color: AppColors.border),
                                ),
                                child: Row(children: [
                                  // Rank
                                  SizedBox(
                                    width: 22,
                                    child: Text('${i + 1}',
                                        style: GoogleFonts.poppins(
                                            color: AppColors.textMuted,
                                            fontSize: 13,
                                            fontWeight:
                                                FontWeight.w700),
                                        textAlign: TextAlign.center),
                                  ),
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: avatarColor
                                        .withValues(alpha: 0.2),
                                    child: Text(initials,
                                        style: GoogleFonts.poppins(
                                            color: avatarColor,
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(s.attempt.userName,
                                              style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                          const SizedBox(height: 4),
                                          Stack(children: [
                                            Container(
                                              height: 5,
                                              decoration: BoxDecoration(
                                                  color:
                                                      AppColors.surface2,
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(3)),
                                            ),
                                            FractionallySizedBox(
                                              widthFactor:
                                                  s.score.clamp(0, 1),
                                              child: Container(
                                                height: 5,
                                                decoration: BoxDecoration(
                                                    color: gradeColor,
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                                3)),
                                              ),
                                            ),
                                          ]),
                                        ]),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text('${s.pct}%',
                                            style: GoogleFonts.poppins(
                                                color: gradeColor,
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.w700)),
                                        Container(
                                          height: 18,
                                          width: 28,
                                          decoration: BoxDecoration(
                                            color: gradeColor
                                                .withValues(alpha: 0.13),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(s.grade,
                                              style: GoogleFonts.poppins(
                                                  color: gradeColor,
                                                  fontSize: 10,
                                                  fontWeight:
                                                      FontWeight.w700)),
                                        ),
                                      ]),
                                ]),
                              ).animate().fadeIn(
                                  delay: (200 + i * 60).ms).slideX(
                                  begin: 0.05, end: 0),
                            );
                          }),

                          // Flagged questions
                          if (flagged.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Text('Flagged Questions',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                                'Answered incorrectly by more than 50% of students',
                                style: GoogleFonts.poppins(
                                    color: AppColors.textMuted,
                                    fontSize: 12)),
                            const SizedBox(height: 10),
                            ...flagged.asMap().entries.map((e) {
                              final q = e.value;
                              final wrongCount = attempts
                                  .where((a) =>
                                      a.answers[q.id] != q.correctIndex)
                                  .length;
                              final wrongPct = attempts.isEmpty
                                  ? 0
                                  : (wrongCount / attempts.length * 100)
                                      .round();
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    border: Border.all(
                                        color: AppColors.error
                                            .withValues(alpha: 0.2)),
                                  ),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Container(
                                            height: 22,
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8),
                                            decoration: BoxDecoration(
                                                color: AppColors.errorLight,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        7)),
                                            child: Text(
                                                'Q${test.questions.indexOf(q) + 1}',
                                                style: GoogleFonts.poppins(
                                                    color: AppColors.error,
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('$wrongPct% got it wrong',
                                              style: GoogleFonts.poppins(
                                                  color: AppColors.error,
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                          const Spacer(),
                                          const Icon(Symbols.flag,
                                              color: AppColors.error,
                                              size: 16),
                                        ]),
                                        const SizedBox(height: 8),
                                        Text(q.question,
                                            style: GoogleFonts.poppins(
                                                color: AppColors.textPrimary,
                                                fontSize: 13)),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                              color: AppColors.successLight,
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: Text(
                                              'Correct: ${String.fromCharCode(65 + q.correctIndex)} — ${q.options[q.correctIndex]}',
                                              style: GoogleFonts.poppins(
                                                  color: AppColors.success,
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        ),
                                      ]),
                                ).animate().fadeIn(
                                    delay: (600 + e.key * 80).ms),
                              );
                            }),
                          ],

                          const SizedBox(height: 20),

                          // Export / Share
                          Row(children: [
                            Expanded(
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppColors.border)),
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(Symbols.download,
                                          color: AppColors.primary,
                                          size: 18),
                                      const SizedBox(width: 8),
                                      Text('Export CSV',
                                          style: GoogleFonts.poppins(
                                              color: AppColors.primary,
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.w600)),
                                    ]),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius:
                                        BorderRadius.circular(14)),
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(Symbols.share,
                                          color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Share Report',
                                          style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.w600)),
                                    ]),
                              ),
                            ),
                          ]).animate().fadeIn(delay: 700.ms),

                          const SizedBox(height: 24),
                        ]),
                  ),
          ),
        ]),
      ),
    );
  }
}

// ── Shared header ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;

  const _Header({
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1C1240), AppColors.bg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 36, width: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.chevron_left_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              if (badge != null)
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? AppColors.success)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(badge!,
                      style: GoogleFonts.poppins(
                          color: badgeColor ?? AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Title + subtitle
          Text(title,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(subtitle,
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
// ── Summary card — uses intrinsic height, no fixed height ─────────────────────

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // ← key fix: don't expand vertically
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            Text(label,
                style: GoogleFonts.poppins(
                    color: color.withValues(alpha: 0.8), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ── Grade distribution bar ────────────────────────────────────────────────────

class _GradeBar extends StatelessWidget {
  final List<({QuizAttempt attempt, double score, int pct, String grade})>
      scored;

  const _GradeBar({required this.scored});

  @override
  Widget build(BuildContext context) {
    final gradeCounts = <String, int>{};
    for (final s in scored) {
      gradeCounts[s.grade] = (gradeCounts[s.grade] ?? 0) + 1;
    }
    final total = scored.length;

    const gradeColors = {
      'A+': AppColors.success,
      'A': AppColors.success,
      'B': AppColors.warning,
      'C': AppColors.warning,
      'D': AppColors.error,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Row(children: ['A+', 'A', 'B', 'C', 'D'].map((g) {
          final count = gradeCounts[g] ?? 0;
          final frac = total == 0 ? 0.0 : count / total;
          if (frac == 0) return const SizedBox.shrink();
          return Expanded(
            flex: (frac * 100).round().clamp(1, 100),
            child: Container(
              height: 18,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: gradeColors[g] ?? AppColors.textMuted,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(g,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700)),
            ),
          );
        }).toList()),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['A+', 'A', 'B', 'C', 'D'].map((g) {
            final count = gradeCounts[g] ?? 0;
            return Text('$g:$count',
                style: GoogleFonts.poppins(
                    color: (gradeColors[g] ?? AppColors.textMuted)
                        .withValues(alpha: 0.8),
                    fontSize: 9));
          }).toList(),
        ),
      ]),
    );
  }
}
