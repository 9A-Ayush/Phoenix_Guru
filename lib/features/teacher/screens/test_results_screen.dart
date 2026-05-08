import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';

class TeacherTestResultsScreen extends StatelessWidget {
  const TeacherTestResultsScreen({super.key});

  static const _title = 'Physics Chapter 4 Test';

  static const _students = [
    ('AK', AppColors.primary,   'Ayush Kumar',   100, 'A+', AppColors.success),
    ('RK', AppColors.warning,   'Rohan Kapoor',   80, 'A',  AppColors.success),
    ('PS', AppColors.accent,    'Priya Singh',    73, 'B',  AppColors.warning),
    ('MV', AppColors.success,   'Mohit Verma',    60, 'C',  AppColors.warning),
    ('SA', Color(0xFF1565C0),   'Sneha Agarwal',  46, 'D',  AppColors.error),
    ('NK', Color(0xFF7C3AED),   'Nikhil Kumar',   40, 'D',  AppColors.error),
  ];

  @override
  Widget build(BuildContext context) {
    final avg = _students.fold(0, (s, e) => s + e.$4) ~/ _students.length;
    final highest = _students.map((e) => e.$4).reduce((a, b) => a > b ? a : b);
    final passed = _students.where((e) => e.$4 >= 60).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
            color: AppColors.surface,
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(height: 34, width: 34,
                    decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Symbols.arrow_back, color: Colors.white, size: 18)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                Text('${_students.length} students attempted', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
              ])),
              Container(
                height: 28, padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(9)),
                child: Text('Completed', style: GoogleFonts.poppins(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Summary cards
                Row(children: [
                  _SummaryCard(label: 'Avg Score', value: '$avg%', icon: Symbols.bar_chart, color: AppColors.primary),
                  const SizedBox(width: 10),
                  _SummaryCard(label: 'Highest', value: '$highest%', icon: Symbols.emoji_events, color: AppColors.warning),
                  const SizedBox(width: 10),
                  _SummaryCard(label: 'Passed', value: '$passed/${_students.length}', icon: Symbols.check_circle, color: AppColors.success),
                ]).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 20),

                // Grade distribution bar
                Text('Grade Distribution', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _GradeBar(students: _students).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 20),

                // Student list
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Student Scores', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  Row(children: [
                    const Icon(Symbols.filter_list, color: AppColors.textMuted, size: 16),
                    const SizedBox(width: 4),
                    Text('Sort', style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 12)),
                  ]),
                ]),
                const SizedBox(height: 10),
                ..._students.asMap().entries.map((e) {
                  final s = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border)),
                      child: Row(children: [
                        // Rank
                        SizedBox(width: 22,
                            child: Text('${e.key + 1}',
                                style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center)),
                        const SizedBox(width: 8),
                        CircleAvatar(radius: 18, backgroundColor: s.$2.withOpacity(0.2),
                            child: Text(s.$1, style: GoogleFonts.poppins(color: s.$2, fontSize: 11, fontWeight: FontWeight.w700))),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.$3, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          // Progress bar
                          Stack(children: [
                            Container(height: 5, decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(3))),
                            FractionallySizedBox(
                              widthFactor: s.$4 / 100,
                              child: Container(height: 5, decoration: BoxDecoration(color: s.$6, borderRadius: BorderRadius.circular(3))),
                            ),
                          ]),
                        ])),
                        const SizedBox(width: 10),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('${s.$4}%', style: GoogleFonts.poppins(color: s.$6, fontSize: 16, fontWeight: FontWeight.w700)),
                          Container(
                            height: 18, width: 28,
                            decoration: BoxDecoration(color: s.$6.withOpacity(0.13), borderRadius: BorderRadius.circular(5)),
                            alignment: Alignment.center,
                            child: Text(s.$5, style: GoogleFonts.poppins(color: s.$6, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ]),
                      ]),
                    ).animate().fadeIn(delay: (200 + e.key * 60).ms).slideX(begin: 0.05, end: 0),
                  );
                }),

                const SizedBox(height: 20),

                // Flagged answers section
                Text('Flagged Answers', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Questions where most students answered incorrectly',
                    style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        height: 22, padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(7)),
                        child: Text('Q3', style: GoogleFonts.poppins(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Text('67% got it wrong', style: GoogleFonts.poppins(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const Icon(Symbols.flag, color: AppColors.error, size: 16),
                    ]),
                    const SizedBox(height: 8),
                    Text("Which law states every action has equal and opposite reaction?",
                        style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      height: 26, padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(8)),
                      alignment: Alignment.centerLeft,
                      child: Text("Correct: C — Newton's Third Law",
                          style: GoogleFonts.poppins(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 20),

                // Export / Share row
                Row(children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Symbols.download, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text('Export CSV', style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Symbols.share, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('Share Report', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 72, padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
          Text(label, style: GoogleFonts.poppins(color: color.withOpacity(0.8), fontSize: 10)),
        ]),
      ),
    );
  }
}

class _GradeBar extends StatelessWidget {
  final List students;

  const _GradeBar({required this.students});

  @override
  Widget build(BuildContext context) {
    final gradeCounts = <String, int>{};
    for (final s in students) gradeCounts[s.$5] = (gradeCounts[s.$5] ?? 0) + 1;
    final total = students.length;

    const gradeColors = {'A+': AppColors.success, 'A': AppColors.success, 'B': AppColors.warning, 'C': AppColors.warning, 'D': AppColors.error};

    return Container(
      height: 64, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Row(children: ['A+', 'A', 'B', 'C', 'D'].map((g) {
          final count = gradeCounts[g] ?? 0;
          final frac = total == 0 ? 0.0 : count / total;
          if (frac == 0) return const SizedBox.shrink();
          return Expanded(
            flex: (frac * 100).round(),
            child: Container(
              height: 18,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: gradeColors[g] ?? AppColors.textMuted,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(g, style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
          );
        }).toList()),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['A+', 'A', 'B', 'C', 'D'].map((g) {
              final count = gradeCounts[g] ?? 0;
              return Text('$g:$count', style: GoogleFonts.poppins(
                  color: gradeColors[g]?.withOpacity(0.8) ?? AppColors.textMuted, fontSize: 9));
            }).toList()),
      ]),
    );
  }
}
