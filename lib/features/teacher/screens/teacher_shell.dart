import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import 'teacher_dashboard.dart';
import 'teacher_classes_page.dart';
import 'teacher_tests_page.dart';
import 'teacher_quiz_page.dart';
import 'teacher_profile_page.dart';

// ── Shell ────────────────────────────────────────────────────────────────────

class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      TeacherDashboard(onNavigateToTab: (index) => setState(() => _index = index)),
      const TeacherClassesPage(),
      const TeacherTestsPage(),
      const TeacherQuizPage(),
      const TeacherProfilePage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: TeacherTabBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
