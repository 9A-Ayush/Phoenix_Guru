import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../shared/widgets/widgets.dart';
import '../quiz/join_live_quiz_screen.dart';
import '../quiz/quiz_screens.dart';
import 'package:provider/provider.dart';

class StudentDashboard extends StatelessWidget {
  final void Function(int)? onTabChange;
  const StudentDashboard({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;
    if (user == null) return const SizedBox.shrink();
    final classes = state.myClasses;
    final tests = state.allTests;
    final payment = state.getStudentPayment(user.id);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 12),

          // ── Top bar ──────────────────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_getGreeting(),
                  style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
              Text(user.name,
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            ]),
            Stack(
              clipBehavior: Clip.none,
              children: [
                GradientAvatar(initials: user.avatarInitials, radius: 22, fontSize: 16),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bg, width: 2),
                    ),
                    child: Center(
                      child: Text('S',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ]).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 20),

          // ── Stat cards ───────────────────────────────────────────────────
          Row(children: [
            StatCard(
                icon: Symbols.menu_book,
                value: '${classes.length}',
                label: 'Classes',
                iconColor: AppColors.primary),
            const SizedBox(width: 12),
            StatCard(
                icon: Symbols.assignment,
                value: '${tests.length}',
                label: 'Tests Due',
                iconColor: AppColors.warning),
            const SizedBox(width: 12),
            StatCard(
                icon: Symbols.payments,
                value: payment?.statusLabel ?? 'N/A',
                label: 'Fee',
                iconColor: payment == null
                    ? AppColors.textMuted
                    : payment.isPaid
                        ? AppColors.success
                        : payment.isOverdue
                            ? AppColors.error
                            : AppColors.warning),
          ]).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 20),

          // ── Live quiz banner ─────────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const JoinLiveQuizScreen())),
            child: Container(
              height: 90,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(11)),
                        child: Row(children: [
                          Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('LIVE NOW',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ]),
                      ),
                      const SizedBox(height: 4),
                      Text('Join a Live Quiz',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      Text('Enter PIN from your teacher',
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 12)),
                    ]),
                Container(
                  width: 72,
                  height: 38,
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Text('Join',
                      style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // ── My Classes ───────────────────────────────────────────────────
          SectionHeader(
            title: 'My Classes',
            action: 'See All',
            onAction: () => onTabChange?.call(1),
          ),
          const SizedBox(height: 12),
          if (classes.isEmpty)
            Center(
                child: Text('Join a class to get started!',
                    style: GoogleFonts.poppins(color: AppColors.textSecondary)))
          else
            ...classes.take(2).toList().asMap().entries.map((e) {
              final cls = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ClassListTile(
                  icon: _sIcon(cls.subject),
                  iconColor: _sColor(e.key),
                  name: cls.name,
                  subtitle: '${cls.teacherName} • ${cls.studentCount} students',
                ).animate().fadeIn(delay: (300 + e.key * 80).ms).slideX(begin: 0.1, end: 0),
              );
            }),

          const SizedBox(height: 24),

          // ── Upcoming Tests ───────────────────────────────────────────────
          SectionHeader(
            title: 'Upcoming Tests',
            action: 'See All',
            onAction: () => onTabChange?.call(3),
          ),
          const SizedBox(height: 12),
          if (tests.isEmpty)
            Text('No upcoming tests',
                style: GoogleFonts.poppins(color: AppColors.textSecondary))
          else
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => TestAttemptScreen(test: tests.first))),
              child: Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.2))),
                child: Row(children: [
                  Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Symbols.quiz,
                          color: AppColors.warning, size: 22)),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Text(tests.first.title,
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        Text(
                            '${tests.first.durationMinutes} mins  •  ${tests.first.questionCount} Qs',
                            style: GoogleFonts.poppins(
                                color: AppColors.warning, fontSize: 12)),
                      ])),
                  const Icon(Symbols.chevron_right,
                      color: AppColors.textMuted, size: 20),
                ]),
              ).animate().fadeIn(delay: 450.ms),
            ),

          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌤';
    if (hour < 17) return 'Good Afternoon ☀️';
    if (hour < 21) return 'Good Evening 🌆';
    return 'Good Night 🌙';
  }

  IconData _sIcon(String s) {
    if (s.toLowerCase().contains('physics')) return Symbols.science;
    if (s.toLowerCase().contains('math')) return Symbols.calculate;
    if (s.toLowerCase().contains('hist')) return Symbols.history_edu;
    return Symbols.school;
  }

  Color _sColor(int i) {
    const c = [AppColors.primary, AppColors.warning, AppColors.success, AppColors.accent];
    return c[i % c.length];
  }
}
