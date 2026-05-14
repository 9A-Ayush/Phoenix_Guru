import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import 'create_class_screen.dart';
import 'class_detail_screen.dart';
import 'teacher_helpers.dart';

// ── Classes Page ─────────────────────────────────────────────────────────────

class TeacherClassesPage extends StatelessWidget {
  const TeacherClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<AppState>().myClasses;
    return SafeArea(
      bottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('My Classes',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const CreateClassScreen())),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Symbols.add, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text('New Class',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: classes.isEmpty
              ? Center(
                  child: TeacherEmptyState(
                      icon: Symbols.groups,
                      message: 'No classes yet',
                      sub: 'Create your first class',
                      actionLabel: 'Create Class',
                      onAction: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const CreateClassScreen()))))
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  itemCount: classes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final cls = classes[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => ClassDetailScreen(cls: cls))),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18)),
                        child: Row(children: [
                          Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                  color: teacherColor(i)
                                      .withValues(alpha: 0.13),
                                  borderRadius: BorderRadius.circular(16)),
                              child: Icon(subjectIcon(cls.subject),
                                  color: teacherColor(i), size: 26)),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                            Text(cls.name,
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(cls.teacherName,
                                style: GoogleFonts.poppins(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                            const SizedBox(height: 6),
                            Row(children: [
                              Text('${cls.studentCount} students',
                                  style: GoogleFonts.poppins(
                                      color: AppColors.textMuted,
                                      fontSize: 11)),
                              const SizedBox(width: 8),
                              Container(
                                height: 18,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                                decoration: BoxDecoration(
                                    color: AppColors.successLight,
                                    borderRadius: BorderRadius.circular(9)),
                                alignment: Alignment.center,
                                child: Text('Active',
                                    style: GoogleFonts.poppins(
                                        color: AppColors.success,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ]),
                          ])),
                          const Icon(Symbols.chevron_right,
                              color: AppColors.textMuted, size: 20),
                        ]),
                      ).animate().fadeIn(delay: (i * 60).ms),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
