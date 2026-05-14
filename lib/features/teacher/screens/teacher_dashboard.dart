import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../shared/widgets/widgets.dart';
import 'create_class_screen.dart';
import 'create_test_screen.dart';
import 'create_quiz_screen.dart';
import 'class_detail_screen.dart';
import 'teacher_helpers.dart';

// ── Dashboard ────────────────────────────────────────────────────────────────

class TeacherDashboard extends StatelessWidget {
  final void Function(int) onNavigateToTab;

  const TeacherDashboard({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;

    if (user == null) return const SizedBox.shrink();

    final classes = state.myClasses;
    final tests = state.allTests;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 12),

          // ── Top bar ──────────────────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(getGreeting(),
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary, fontSize: 13)),
              Text(user.name,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
            ]),
            Stack(
              clipBehavior: Clip.none,
              children: [
                GradientAvatar(
                    initials: user.avatarInitials, radius: 22, fontSize: 16),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bg, width: 2),
                    ),
                    child: Center(
                      child: Text('T',
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
                icon: Symbols.groups,
                value: '${classes.length}',
                label: 'Classes',
                iconColor: AppColors.primary),
            const SizedBox(width: 12),
            StatCard(
                icon: Symbols.person,
                value: '${classes.fold(0, (s, c) => s + c.studentCount)}',
                label: 'Students',
                iconColor: AppColors.warning),
            const SizedBox(width: 12),
            StatCard(
                icon: Symbols.quiz,
                value: '${tests.length}',
                label: 'Tests',
                iconColor: AppColors.success),
          ]).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 24),
          Text('Quick Actions',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700))
              .animate()
              .fadeIn(delay: 150.ms),
          const SizedBox(height: 12),

          // ── Quick actions ────────────────────────────────────────────────
          SizedBox(
            height: 80,
            child: Row(children: [
              _quickAction(
                  context, Symbols.add, 'New Class', AppColors.primary,
                  Colors.white,
                  () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const CreateClassScreen()))),
              const SizedBox(width: 12),
              _quickAction(
                  context, Symbols.edit_note, 'New Test',
                  AppColors.warningLight, AppColors.warning,
                  () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const CreateTestScreen()))),
              const SizedBox(width: 12),
              _quickAction(
                  context, Symbols.live_tv, 'Start Quiz',
                  AppColors.successLight, AppColors.success,
                  () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const CreateQuizScreen()))),
            ]),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          // ── My Classes ───────────────────────────────────────────────────
          SectionHeader(
            title: 'My Classes',
            action: 'See All',
            onAction: () => onNavigateToTab(1),
          ),
          const SizedBox(height: 12),
          if (classes.isEmpty)
            TeacherEmptyState(
              icon: Symbols.groups,
              message: 'No classes yet',
              sub: 'Create a class to get started',
              actionLabel: 'Create Class',
              onAction: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const CreateClassScreen())),
            )
          else
            ...classes.take(2).toList().asMap().entries.map((e) {
              final cls = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => ClassDetailScreen(cls: cls))),
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                              color: teacherColor(e.key)
                                  .withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(14)),
                          child: Icon(subjectIcon(cls.subject),
                              color: teacherColor(e.key), size: 24)),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            Text(cls.name,
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            Text(
                                '${cls.studentCount} students  •  ${tests.where((t) => t.classId == cls.id).length} tests',
                                style: GoogleFonts.poppins(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                          ])),
                      const Icon(Symbols.chevron_right,
                          color: AppColors.textMuted, size: 20),
                    ]),
                  ),
                ).animate().fadeIn(delay: (300 + e.key * 80).ms),
              );
            }),

          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _quickAction(BuildContext ctx, IconData icon, String label, Color bg,
      Color fg, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: fg, size: 24),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}
