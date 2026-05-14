import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models.dart';
import '../quiz/join_live_quiz_screen.dart';
import '../quiz/quiz_screens.dart';

// ── Quiz / Tests Page ─────────────────────────────────────────────────────────
class StudentQuizPage extends StatelessWidget {
  const StudentQuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tests = context.watch<AppState>().allTests;
    return SafeArea(
      bottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Text('My Tests',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),

        // ── Join Live Quiz banner ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const JoinLiveQuizScreen())),
            child: Container(
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle),
                  child: const Icon(Symbols.wifi_tethering,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Text('Join Live Quiz',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    Text('Enter PIN from your teacher',
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 11)),
                  ]),
                ),
                const Icon(Symbols.arrow_forward, color: Colors.white, size: 18),
              ]),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 12),

        // ── Filter tabs ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            Container(
              height: 36,
              width: 100,
              decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text('Upcoming',
                  style: GoogleFonts.poppins(
                      color: AppColors.bg,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Container(
              height: 36,
              width: 80,
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text('Done',
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary, fontSize: 12)),
            ),
          ]),
        ),

        const SizedBox(height: 12),

        // ── Test list ─────────────────────────────────────────────────────
        Expanded(
          child: tests.isEmpty
              ? Center(
                  child: Text('No tests scheduled',
                      style:
                          GoogleFonts.poppins(color: AppColors.textSecondary)))
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  itemCount: tests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _TestCard(test: tests[i], index: i),
                ),
        ),
      ]),
    );
  }
}

// ── Test Card ─────────────────────────────────────────────────────────────────
class _TestCard extends StatelessWidget {
  final TestModel test;
  final int index;
  const _TestCard({required this.test, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => TestAttemptScreen(test: test))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Text(test.title,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Text(test.isLive ? 'Live' : 'Upcoming',
                  style: GoogleFonts.poppins(
                      color: AppColors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Symbols.schedule, color: AppColors.textSecondary, size: 14),
            const SizedBox(width: 4),
            Text('${test.durationMinutes} mins',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(width: 16),
            const Icon(Symbols.help, color: AppColors.textSecondary, size: 14),
            const SizedBox(width: 4),
            Text('${test.questionCount} Questions',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 12)),
          ]),
        ]),
      ).animate().fadeIn(delay: (index * 60).ms),
    );
  }
}
