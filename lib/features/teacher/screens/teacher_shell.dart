import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/screens/login_screen.dart';
import 'create_class_screen.dart';
import 'create_test_screen.dart';
import 'class_detail_screen.dart';
import 'live_quiz_host_screen.dart';
import 'test_results_screen.dart';

// ── Shell ────────────────────────────────────────────────────────────────────

class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _index = 0;

  late final List<Widget> _pages = [
    const TeacherDashboard(),
    const TeacherClassesPage(),
    const TeacherTestsPage(),
    const TeacherQuizPage(),
    const TeacherProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: TeacherTabBar(currentIndex: _index, onTap: (i) => setState(() => _index = i)),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

String _getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning 🌤';
  if (hour < 17) return 'Good Afternoon ☀️';
  if (hour < 21) return 'Good Evening 🌆';
  return 'Good Night 🌙';
}

// ── Dashboard ────────────────────────────────────────────────────────────────

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser!;
    final classes = state.myClasses;
    final tests = state.allTests;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 12),
          // Top bar
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_getGreeting(), style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
              Text(user.name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            ]),
            Row(children: [
              GradientAvatar(initials: user.avatarInitials, radius: 22, fontSize: 16),
              const SizedBox(width: 8),
              Container(
                height: 28, padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Symbols.school, color: AppColors.primary, size: 14),
                  const SizedBox(width: 6),
                  Text('Teacher', style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ]).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 20),
          Row(children: [
            StatCard(icon: Symbols.groups, value: '${classes.length}', label: 'Classes', iconColor: AppColors.primary),
            const SizedBox(width: 12),
            StatCard(icon: Symbols.person, value: '${classes.fold(0, (s, c) => s + c.studentCount)}', label: 'Students', iconColor: AppColors.warning),
            const SizedBox(width: 12),
            StatCard(icon: Symbols.quiz, value: '${tests.length}', label: 'Tests', iconColor: AppColors.success),
          ]).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 24),
          Text('Quick Actions', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))
              .animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: Row(children: [
              _quickAction(context, Symbols.add, 'New Class', AppColors.primary, Colors.white,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateClassScreen()))),
              const SizedBox(width: 12),
              _quickAction(context, Symbols.edit_note, 'New Test', AppColors.warningLight, AppColors.warning,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTestScreen()))),
              const SizedBox(width: 12),
              _quickAction(context, Symbols.live_tv, 'Start Quiz', AppColors.successLight, AppColors.success, () {}),
            ]),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),
          SectionHeader(title: 'My Classes', action: 'See All'),
          const SizedBox(height: 12),
          if (classes.isEmpty)
            _EmptyState(
              icon: Symbols.groups,
              message: 'No classes yet',
              sub: 'Create a class to get started',
              actionLabel: 'Create Class',
              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateClassScreen())),
            )
          else
            ...classes.take(2).toList().asMap().entries.map((e) {
              final cls = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClassDetailScreen(cls: cls))),
                  child: Container(
                    height: 80, padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      Container(width: 48, height: 48,
                          decoration: BoxDecoration(color: _color(e.key).withOpacity(0.13), borderRadius: BorderRadius.circular(14)),
                          child: Icon(_icon(cls.subject), color: _color(e.key), size: 24)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(cls.name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        Text('${cls.studentCount} students  •  ${tests.where((t) => t.classId == cls.id).length} tests',
                            style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
                      ])),
                      const Icon(Symbols.chevron_right, color: AppColors.textMuted, size: 20),
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

  Widget _quickAction(BuildContext ctx, IconData icon, String label, Color bg, Color fg, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: fg, size: 24),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.poppins(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  IconData _icon(String s) {
    if (s.toLowerCase().contains('physics')) return Symbols.science;
    if (s.toLowerCase().contains('math')) return Symbols.calculate;
    if (s.toLowerCase().contains('hist')) return Symbols.history_edu;
    return Symbols.school;
  }

  Color _color(int i) {
    const c = [AppColors.primary, AppColors.warning, AppColors.success, AppColors.accent];
    return c[i % c.length];
  }
}

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
            Text('My Classes', style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateClassScreen())),
              child: Container(
                height: 38, padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Symbols.add, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text('New Class', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: classes.isEmpty
              ? Center(child: _EmptyState(
                  icon: Symbols.groups, message: 'No classes yet',
                  sub: 'Create your first class', actionLabel: 'Create Class',
                  onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateClassScreen()))))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  itemCount: classes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final cls = classes[i];
                    final tests = context.read<AppState>().testsForClass(cls.id);
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClassDetailScreen(cls: cls))),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
                        child: Row(children: [
                          Container(width: 54, height: 54,
                              decoration: BoxDecoration(color: _color(i).withOpacity(0.13), borderRadius: BorderRadius.circular(16)),
                              child: Icon(_icon(cls.subject), color: _color(i), size: 26)),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(cls.name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(cls.teacherName, style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 6),
                            Row(children: [
                              Text('${cls.studentCount} students', style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 11)),
                              const SizedBox(width: 8),
                              Container(
                                height: 18, padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(9)),
                                alignment: Alignment.center,
                                child: Text('Active', style: GoogleFonts.poppins(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w600)),
                              ),
                            ]),
                          ])),
                          const Icon(Symbols.chevron_right, color: AppColors.textMuted, size: 20),
                        ]),
                      ).animate().fadeIn(delay: (i * 60).ms),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  IconData _icon(String s) {
    if (s.toLowerCase().contains('physics')) return Symbols.science;
    if (s.toLowerCase().contains('math')) return Symbols.calculate;
    if (s.toLowerCase().contains('hist')) return Symbols.history_edu;
    return Symbols.school;
  }

  Color _color(int i) {
    const c = [AppColors.primary, AppColors.warning, AppColors.success, AppColors.accent];
    return c[i % c.length];
  }
}

// ── Tests Page ────────────────────────────────────────────────────────────────

class TeacherTestsPage extends StatelessWidget {
  const TeacherTestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tests = context.watch<AppState>().allTests;
    return SafeArea(
      bottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Tests', style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTestScreen())),
              child: Container(
                height: 38, padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Symbols.add, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text('New Test', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: tests.isEmpty
              ? const Center(child: Text('No tests created', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  itemCount: tests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final t = tests[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Expanded(child: Text(t.title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
                          Container(
                            height: 24, padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(8)),
                            child: Text('Upcoming', style: GoogleFonts.poppins(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w600)),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Text(t.className, style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 6),
                        Row(children: [
                          const Icon(Symbols.schedule, color: AppColors.textMuted, size: 14),
                          const SizedBox(width: 4),
                          Text('${t.durationMinutes} mins', style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 12)),
                          const SizedBox(width: 12),
                          const Icon(Symbols.help, color: AppColors.textMuted, size: 14),
                          const SizedBox(width: 4),
                          Text('${t.questionCount} Questions', style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 12)),
                        ]),
                      ]),
                    ).animate().fadeIn(delay: (i * 60).ms);
                  },
                ),
        ),
      ]),
    );
  }
}

// ── Quiz (Live) Page ──────────────────────────────────────────────────────────

class TeacherQuizPage extends StatelessWidget {
  const TeacherQuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Live Quiz', style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              final tests = context.read<AppState>().allTests;
              if (tests.isNotEmpty) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherLiveQuizScreen(test: tests.first)));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create a test first to start a live quiz.')));
              }
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Symbols.live_tv, color: Colors.white, size: 32)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Start Live Quiz', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Host a real-time quiz session', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                ])),
                const Icon(Symbols.arrow_forward, color: Colors.white, size: 22),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          // View Test Results card
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherTestResultsScreen())),
            child: Container(
              height: 76, padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Symbols.bar_chart, color: AppColors.success, size: 24)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Test Results', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('View scores, grades & flagged questions', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
                ])),
                const Icon(Symbols.chevron_right, color: AppColors.textMuted, size: 20),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          Text('How Live Quiz Works', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...[
            (Symbols.settings, AppColors.primary, '1. Select a test', 'Choose a test you have created'),
            (Symbols.wifi_tethering, AppColors.warning, '2. Share PIN', 'Students enter the 6-digit PIN to join'),
            (Symbols.play_arrow, AppColors.success, '3. Start & Control', 'Reveal answers and move to next questions'),
            (Symbols.bar_chart, AppColors.accent, '4. View Results', 'See scores, rankings and flagged answers'),
          ].asMap().entries.map((e) {
            final s = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                height: 64, padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Container(width: 38, height: 38, decoration: BoxDecoration(color: s.$2.withOpacity(0.13), borderRadius: BorderRadius.circular(12)),
                      child: Icon(s.$1, color: s.$2, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(s.$3, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(s.$4, style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11)),
                  ])),
                ]),
              ),
            );
          }),
        ]),
      ),
    );
  }
}

// ── Profile Page ──────────────────────────────────────────────────────────────

class TeacherProfilePage extends StatelessWidget {
  const TeacherProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser!;
    final classes = state.myClasses;
    final tests = state.allTests;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: Column(children: [
          Container(
            height: 240,
            width: double.infinity,
            decoration: const BoxDecoration(gradient: LinearGradient(
                colors: [Color(0xFF1C1240), AppColors.bg], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(height: 40),
              GradientAvatar(initials: user.avatarInitials, radius: 40, fontSize: 28),
              const SizedBox(height: 12),
              Text(user.name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              Text(user.email, style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
            ]),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(children: [
            Container(
              height: 72,
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                _stat('${classes.length}', 'Classes', AppColors.primary),
                Container(width: 1, height: 40, color: AppColors.border),
                _stat('${classes.fold(0, (s, c) => s + c.studentCount)}', 'Students', AppColors.warning),
                Container(width: 1, height: 40, color: AppColors.border),
                _stat('${tests.length}', 'Tests', AppColors.success),
              ]),
            ),
            const SizedBox(height: 16),
            MenuRow(icon: Symbols.person, iconColor: AppColors.primary, label: 'Edit Profile'),
            const SizedBox(height: 10),
            MenuRow(icon: Symbols.notifications, iconColor: AppColors.warning, label: 'Notifications'),
            const SizedBox(height: 10),
            MenuRow(icon: Symbols.lock, iconColor: AppColors.success, label: 'Change Password'),
            const SizedBox(height: 10),
            MenuRow(icon: Symbols.help, iconColor: AppColors.textSecondary, label: 'Help & Support'),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                context.read<AppState>().logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              },
              child: Container(
                height: 52, padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.errorLight, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Symbols.logout, color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Text('Logout', style: GoogleFonts.poppins(color: AppColors.error, fontSize: 15, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
          ])),
        ]),
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(value, style: GoogleFonts.poppins(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
      Text(label, style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11)),
    ]));
  }
}

// ── Empty State Helper ────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({required this.icon, required this.message, required this.sub, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: AppColors.textMuted, size: 52),
      const SizedBox(height: 12),
      Text(message, style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(sub, style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 13), textAlign: TextAlign.center),
      if (actionLabel != null) ...[
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onAction,
          child: Container(
            height: 44, padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(actionLabel!, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    ]);
  }
}
