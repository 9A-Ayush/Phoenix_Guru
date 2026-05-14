import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import 'student_dashboard.dart';
import 'student_classes_page.dart';
import 'student_material_page.dart';
import 'student_quiz_page.dart';
import 'student_profile_page.dart';

// ── Shell ─────────────────────────────────────────────────────────────────────
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});
  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      StudentDashboard(onTabChange: (i) => setState(() => _index = i)),
      const StudentClassesPage(),
      const StudentMaterialPage(),
      const StudentQuizPage(),
      StudentProfilePage(onTabChange: (i) => setState(() => _index = i)),
    ];
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: StudentTabBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
