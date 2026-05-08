import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models.dart';
import '../../../shared/widgets/widgets.dart';

class ClassDetailScreen extends StatefulWidget {
  final ClassModel cls;
  const ClassDetailScreen({super.key, required this.cls});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  int _tab = 0;

  static const _students = [
    ('AK', AppColors.primary, 'Ayush Kumar', 'Last active: Today', '84%', AppColors.success),
    ('RK', AppColors.warning, 'Rohan Kapoor', 'Last active: Yesterday', '76%', AppColors.warning),
    ('PS', AppColors.accent, 'Priya Singh', 'Last active: 2 days ago', '91%', AppColors.success),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          // Header area
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1C1240), AppColors.bg],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const AppBackButton(),
              const SizedBox(height: 20),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 56, height: 56,
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Symbols.science, color: AppColors.primary, size: 28)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.cls.name,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  Text('${widget.cls.studentCount} students  •  ${widget.cls.teacherName}',
                      style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
                ])),
              ]),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: widget.cls.classCode));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Code copied!', style: GoogleFonts.poppins(color: Colors.white)),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                },
                child: Container(
                  height: 30, padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Symbols.key, color: AppColors.primary, size: 14),
                    const SizedBox(width: 8),
                    Text('Class Code: ${widget.cls.classCode}',
                        style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              // Tabs
              Row(children: ['Students', 'Tests', 'Material'].asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _tab = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _tab == e.key ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(e.value, style: GoogleFonts.poppins(
                        color: _tab == e.key ? Colors.white : AppColors.textSecondary,
                        fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              )).toList()),
            ]),
          ),

          // Content
          Expanded(child: _tab == 0
              ? _StudentsTab(students: _students, classId: widget.cls.id)
              : _tab == 1
              ? const _TestsTab()
              : const _MaterialTab()),
        ]),
      ),
    );
  }
}

class _StudentsTab extends StatelessWidget {
  final List<(String, Color, String, String, String, Color)> students;
  final String classId;

  const _StudentsTab({required this.students, required this.classId});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: students.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i == students.length) {
          return Container(
            height: 52,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Symbols.person_add, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Add Student', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ]),
          );
        }
        final s = students[i];
        return Container(
          height: 64, padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            CircleAvatar(radius: 18, backgroundColor: s.$2.withOpacity(0.2),
                child: Text(s.$1, style: GoogleFonts.poppins(color: s.$2, fontSize: 12, fontWeight: FontWeight.w700))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(s.$3, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(s.$4, style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11)),
            ])),
            Text(s.$5, style: GoogleFonts.poppins(color: s.$6, fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
        ).animate().fadeIn(delay: (i * 60).ms);
      },
    );
  }
}

class _TestsTab extends StatelessWidget {
  const _TestsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No tests for this class', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}

class _MaterialTab extends StatelessWidget {
  const _MaterialTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No materials uploaded', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}
