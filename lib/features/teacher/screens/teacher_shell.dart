import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/screens/login_screen.dart';
import 'create_class_screen.dart';
import 'create_test_screen.dart';
import 'class_detail_screen.dart';
import 'live_quiz_host_screen.dart';
import 'live_session_lobby_screen.dart';
import 'create_quiz_screen.dart';
import 'active_sessions_screen.dart';
import 'test_results_screen.dart';
import 'edit_profile_screen.dart';
import 'material_upload_screen.dart';
import 'notifications_screen.dart';
import 'help_support_screen.dart';
import 'edit_test_screen.dart';

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
  final void Function(int) onNavigateToTab;
  
  const TeacherDashboard({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;

    // Guard against null during logout transition
    if (user == null) return const SizedBox.shrink();

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
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bg, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        'T',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
              _quickAction(context, Symbols.live_tv, 'Start Quiz', AppColors.successLight, AppColors.success,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateQuizScreen()))),
            ]),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),
          SectionHeader(
            title: 'My Classes',
            action: 'See All',
            onAction: () => onNavigateToTab(1),
          ),
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

  String _formatDateTime(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final amPm = d.hour >= 12 ? 'PM' : 'AM';
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}, $hour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final tests = context.watch<AppState>().allTests;
    return SafeArea(
      bottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Tests',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            Row(children: [
              // Test Results button
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TeacherTestResultsScreen())),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3))),
                  child: Row(children: [
                    const Icon(Symbols.bar_chart,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 5),
                    Text('Results',
                        style: GoogleFonts.poppins(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              // New Test button
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreateTestScreen())),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Symbols.add, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text('New Test',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: tests.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Symbols.assignment,
                        color: AppColors.textMuted, size: 52),
                    const SizedBox(height: 12),
                    Text('No tests yet',
                        style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Create your first test',
                        style: GoogleFonts.poppins(
                            color: AppColors.textMuted, fontSize: 13)),
                  ]),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 4),
                  itemCount: tests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final t = tests[i];
                    return _TestCard(
                      test: t,
                      formatDateTime: _formatDateTime,
                    ).animate().fadeIn(delay: (i * 60).ms);
                  },
                ),
        ),
      ]),
    );
  }
}

// ── Test card ─────────────────────────────────────────────────────────────────

class _TestCard extends StatelessWidget {
  final TestModel test;
  final String Function(DateTime) formatDateTime;

  const _TestCard({required this.test, required this.formatDateTime});

  Color get _statusColor {
    if (test.isLive) return AppColors.success;
    if (test.isExpired) return AppColors.error;
    return AppColors.warning;
  }

  String get _statusLabel {
    if (test.isLive) return 'Live';
    if (test.isExpired) return 'Expired';
    return 'Upcoming';
  }

  IconData get _statusIcon {
    if (test.isLive) return Symbols.live_tv;
    if (test.isExpired) return Symbols.timer_off;
    return Symbols.schedule;
  }

  void _showMenu(BuildContext context) {
    final appState = context.read<AppState>();
    // Capture navigator & messenger BEFORE showing the sheet,
    // so they survive widget tree rebuilds triggered by Firestore streams.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: false,
      builder: (sheetCtx) => _TestMenuSheet(
        test: test,
        formatDateTime: formatDateTime,
        appState: appState,
        navigator: navigator,
        messenger: messenger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attempts =
        context.read<AppState>().attemptsForTest(test.id);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        // ── Top row ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject icon box
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_statusIcon, color: _statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              // Title + class
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(test.title,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(test.className,
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 12)),
                ]),
              ),
              const SizedBox(width: 8),
              // Three-dot + status badge column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => _showMenu(context),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.more_vert_rounded,
                          color: AppColors.textMuted, size: 18),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_statusLabel,
                        style: GoogleFonts.poppins(
                            color: _statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Divider ───────────────────────────────────────────────────────
        const SizedBox(height: 12),
        const Divider(color: AppColors.border, height: 1),

        // ── Stats row ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _Stat(icon: Symbols.timer, label: '${test.durationMinutes} mins'),
                  _Stat(icon: Symbols.help, label: '${test.questionCount} Qs'),
                  _Stat(icon: Symbols.person, label: '${ attempts.length} done'),
                ],
              ),
              if (test.expiresAt != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Symbols.calendar_month,
                        color: AppColors.textMuted, size: 13),
                    const SizedBox(width: 4),
                    Text(formatDateTime(test.expiresAt!),
                        style: GoogleFonts.poppins(
                            color: test.isExpired
                                ? AppColors.error
                                : AppColors.textMuted,
                            fontSize: 11)),
                  ],
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Stat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: AppColors.textMuted, size: 13),
      const SizedBox(width: 4),
      Text(label,
          style: GoogleFonts.poppins(
              color: AppColors.textMuted, fontSize: 12)),
    ]);
  }
}

// ── Test menu bottom sheet ────────────────────────────────────────────────────

class _TestMenuSheet extends StatelessWidget {
  final TestModel test;
  final String Function(DateTime) formatDateTime;
  final AppState appState;
  final NavigatorState navigator;
  final ScaffoldMessengerState messenger;

  const _TestMenuSheet({
    required this.test,
    required this.formatDateTime,
    required this.appState,
    required this.navigator,
    required this.messenger,
  });

  void _showError(String msg) {
    messenger.showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccess(String msg) {
    messenger.showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),

        // Test info
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Symbols.assignment,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(test.title,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(test.className,
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary, fontSize: 12)),
            ]),
          ),
        ]),

        const SizedBox(height: 16),
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 12),

        // ── Edit Test ─────────────────────────────────────────────────────
        _MenuItem(
          icon: Symbols.edit,
          iconColor: AppColors.primary,
          label: 'Edit Test',
          subtitle: 'Change name, questions or expiry date',
          onTap: () {
            Navigator.pop(context); // close the sheet
            // Small delay to let the sheet fully dismiss
            Future.delayed(const Duration(milliseconds: 150), () {
              navigator.push(
                MaterialPageRoute(builder: (_) => EditTestScreen(test: test)),
              );
            });
          },
        ),
        const SizedBox(height: 8),

        // ── Publish / Unpublish ───────────────────────────────────────────
        _MenuItem(
          icon: test.isLive ? Symbols.pause : Symbols.publish,
          iconColor: test.isLive ? AppColors.warning : AppColors.success,
          label: test.isLive ? 'Unpublish Test' : 'Publish Test',
          subtitle: test.isLive
              ? 'Stop students from taking this test'
              : 'Make this test available to students',
          onTap: () async {
            Navigator.pop(context); // close the sheet
            await Future.delayed(const Duration(milliseconds: 150));
            final err = await appState
                .toggleTestPublish(test.id, isLive: !test.isLive);
            if (err != null) {
              _showError(err);
            } else {
              _showSuccess(test.isLive ? 'Test unpublished' : 'Test published');
            }
          },
        ),
        const SizedBox(height: 8),

        // ── Extend Expiry ─────────────────────────────────────────────────
        _MenuItem(
          icon: Symbols.calendar_month,
          iconColor: const Color(0xFF5B2FD4),
          label: 'Extend Expiry',
          subtitle: test.expiresAt != null
              ? 'Current: ${formatDateTime(test.expiresAt!)}'
              : 'Set a new expiration date',
          onTap: () async {
            Navigator.pop(context); // close the sheet first
            await Future.delayed(const Duration(milliseconds: 150));

            // Use the stable navigator context for the date picker
            final navContext = navigator.context;
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            
            final themeBuilder = (BuildContext ctx, Widget? child) => Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFF5B2FD4),
                  onPrimary: Colors.white,
                  surface: Color(0xFF0A0A0A),
                  onSurface: Colors.white,
                ),
                dialogTheme: const DialogThemeData(
                  backgroundColor: Color(0xFF0A0A0A),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF5B2FD4),
                  ),
                ),
              ),
              child: child!,
            );

            final pickedDate = await showDatePicker(
              context: navContext,
              initialDate: test.expiresAt != null &&
                      test.expiresAt!.isAfter(today)
                  ? test.expiresAt!
                  : today.add(const Duration(days: 1)),
              firstDate: today.add(const Duration(days: 1)),
              lastDate: DateTime(now.year + 2),
              builder: themeBuilder,
            );
            if (pickedDate == null) return;
            
            final initialTime = test.expiresAt != null
                ? TimeOfDay(hour: test.expiresAt!.hour, minute: test.expiresAt!.minute)
                : const TimeOfDay(hour: 23, minute: 59);

            final pickedTime = await showTimePicker(
              context: navContext,
              initialTime: initialTime,
              builder: themeBuilder,
            );
            if (pickedTime == null) return;
            
            final picked = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );

            final err = await appState
                .extendTestExpiry(testId: test.id, newExpiry: picked);
            if (err != null) {
              _showError(err);
            } else {
              _showSuccess('Expiry extended to ${formatDateTime(picked)}');
            }
          },
        ),
        const SizedBox(height: 8),

        // ── Delete ────────────────────────────────────────────────────────
        _MenuItem(
          icon: Symbols.delete,
          iconColor: AppColors.error,
          label: 'Delete Test',
          subtitle: 'Permanently remove this test and all attempts',
          destructive: true,
          onTap: () {
            Navigator.pop(context); // close the sheet
            Future.delayed(const Duration(milliseconds: 150), () {
              showDialog(
                context: navigator.context,
              builder: (dialogCtx) => AlertDialog(
                backgroundColor: AppColors.surface2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text('Delete Test',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
                content: Text(
                  'Delete "${test.title}"?\n\nAll student attempts will also be deleted. This cannot be undone.',
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text('Cancel',
                        style: GoogleFonts.poppins(
                            color: AppColors.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(dialogCtx); // close the dialog
                      final err = await appState.deleteTest(test.id);
                      if (err != null) {
                        _showError(err);
                      } else {
                        _showSuccess('Test deleted');
                      }
                    },
                    child: Text('Delete',
                        style: GoogleFonts.poppins(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
                ),
              );
            });
          },
        ),
      ]),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: destructive ? AppColors.errorLight : AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: destructive
                ? AppColors.error.withValues(alpha: 0.2)
                : AppColors.border,
          ),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      color: destructive ? AppColors.error : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: GoogleFonts.poppins(
                      color: destructive
                          ? AppColors.error.withValues(alpha: 0.7)
                          : AppColors.textSecondary,
                      fontSize: 12)),
            ]),
          ),
          Icon(Symbols.chevron_right,
              color: destructive
                  ? AppColors.error.withValues(alpha: 0.5)
                  : AppColors.textMuted,
              size: 18),
        ]),
      ),
    );
  }
}

// ── Quiz (Live) Page ──────────────────────────────────────────────────────────

String _statusLabel(LiveSessionStatus status) {
  switch (status) {
    case LiveSessionStatus.waiting: return 'Waiting';
    case LiveSessionStatus.active: return 'Live';
    case LiveSessionStatus.showingResult: return 'Showing Result';
    case LiveSessionStatus.ended: return 'Ended';
  }
}

class TeacherQuizPage extends StatelessWidget {
  const TeacherQuizPage({super.key});

  void _pickTest(BuildContext context, List<TestModel> tests) {
    if (tests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Create a test first to start a live quiz.',
            style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Create',
          textColor: Colors.white,
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CreateTestScreen())),
        ),
      ));
      return;
    }

    if (tests.length == 1) {
      _launchSession(context, tests.first);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: false,
      builder: (_) => _TestPickerSheet(
        tests: tests,
        onSelect: (t) {
          Navigator.pop(context);
          _launchSession(context, t);
        },
      ),
    );
  }

  Future<void> _launchSession(BuildContext context, TestModel test) async {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LiveSessionLobbyScreen(test: test),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tests = context.watch<AppState>().allTests;
    final hostId = context.read<AppState>().currentUser?.id ?? '';

    // Stream count of active sessions for the button badge
    final activeCountStream = FirebaseFirestore.instance
        .collection('live_sessions')
        .where('hostId', isEqualTo: hostId)
        .where('status', whereIn: [
          LiveSessionStatus.waiting.name,
          LiveSessionStatus.active.name,
          LiveSessionStatus.showingResult.name,
        ])
        .snapshots()
        .map((snap) => snap.docs.length);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row with title + active sessions button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Live Quiz',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              StreamBuilder<int>(
                stream: activeCountStream,
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActiveSessionsScreen(
                          hostId: hostId,
                          tests: tests,
                        ),
                      ),
                    ),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: count > 0
                            ? AppColors.successLight
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: count > 0
                              ? AppColors.success.withValues(alpha: 0.4)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (count > 0) ...[
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Icon(
                          Symbols.live_tv,
                          color: count > 0
                              ? AppColors.success
                              : AppColors.textMuted,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          count > 0 ? '$count Active' : 'Sessions',
                          style: GoogleFonts.poppins(
                            color: count > 0
                                ? AppColors.success
                                : AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Create new quiz from scratch ──────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CreateQuizScreen())),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF4B2FD4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Symbols.add_circle,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Create New Quiz',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Build questions & launch instantly',
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 12)),
                  ]),
                ),
                const Icon(Symbols.arrow_forward,
                    color: Colors.white, size: 20),
              ]),
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 12),

          // ── Start from existing test ──────────────────────────────────
          GestureDetector(
            onTap: () => _pickTest(context, tests),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Symbols.live_tv,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Start from Test',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      tests.isEmpty
                          ? 'No tests yet — create one first'
                          : '${tests.length} test${tests.length == 1 ? '' : 's'} available',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ]),
                ),
                const Icon(Symbols.arrow_forward,
                    color: AppColors.textMuted, size: 20),
              ]),
            ),
          ).animate().fadeIn(delay: 160.ms),
          const SizedBox(height: 24),
          Text('How Live Quiz Works',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...[
            (Symbols.settings, AppColors.primary, '1. Select a test',
                'Choose a test you have created'),
            (Symbols.wifi_tethering, AppColors.warning, '2. Share PIN',
                'Students enter the 6-digit PIN to join'),
            (Symbols.play_arrow, AppColors.success, '3. Start & Control',
                'Reveal answers and move to next questions'),
            (Symbols.bar_chart, AppColors.accent, '4. View Results',
                'See scores, rankings and flagged answers'),
          ].asMap().entries.map((e) {
            final s = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                        color: s.$2.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(s.$1, color: s.$2, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Text(s.$3,
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      Text(s.$4,
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary, fontSize: 11)),
                    ]),
                  ),
                ]),
              ),
            );
          }),
        ]),
      ),
    );
  }
}

// ── Test picker sheet ─────────────────────────────────────────────────────────

class _TestPickerSheet extends StatelessWidget {
  final List<TestModel> tests;
  final void Function(TestModel) onSelect;

  const _TestPickerSheet({required this.tests, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),
        Text('Select a Test',
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Choose which test to run as a live quiz',
            style: GoogleFonts.poppins(
                color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.45,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: tests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final t = tests[i];
              return GestureDetector(
                onTap: () => onSelect(t),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Symbols.assignment,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(t.title,
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(
                          '${t.className}  •  ${t.questionCount} questions  •  ${t.durationMinutes} mins',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontSize: 11),
                        ),
                      ]),
                    ),
                    const Icon(Symbols.play_arrow,
                        color: AppColors.primary, size: 20),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ── Profile Page ──────────────────────────────────────────────────────────────

class TeacherProfilePage extends StatelessWidget {
  const TeacherProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;

    // Guard against null during logout transition
    if (user == null) return const SizedBox.shrink();

    final classes = state.myClasses;
    final tests = state.allTests;

    return SingleChildScrollView(
        child: Column(children: [
          Container(
            height: 240 + MediaQuery.of(context).padding.top,
            width: double.infinity,
            decoration: const BoxDecoration(gradient: LinearGradient(
                colors: [Color(0xFF1C1240), AppColors.bg], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(height: 40 + MediaQuery.of(context).padding.top),
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  GradientAvatar(initials: user.avatarInitials, radius: 40, fontSize: 28),
                  Positioned(
                    bottom: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9B7BFF), Color(0xFF5B2FD4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.bg, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Symbols.school, color: Colors.white, size: 11),
                        const SizedBox(width: 4),
                        Text('TEACHER',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
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
            MenuRow(icon: Symbols.person, iconColor: AppColors.primary, label: 'Edit Profile',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
            const SizedBox(height: 10),
            MenuRow(icon: Symbols.upload_file, iconColor: AppColors.success, label: 'Upload Material',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaterialUploadScreen()))),
            const SizedBox(height: 10),
            MenuRow(icon: Symbols.notifications, iconColor: AppColors.warning, label: 'Notifications',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
            const SizedBox(height: 10),
            MenuRow(icon: Symbols.help, iconColor: AppColors.textSecondary, label: 'Help & Support',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()))),
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
