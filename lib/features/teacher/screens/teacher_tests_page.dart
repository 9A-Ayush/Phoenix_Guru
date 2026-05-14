import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models.dart';
import 'create_test_screen.dart';
import 'test_results_screen.dart';
import 'edit_test_screen.dart';
import 'teacher_helpers.dart';

// ── Tests Page ────────────────────────────────────────────────────────────────

class TeacherTestsPage extends StatelessWidget {
  const TeacherTestsPage({super.key});

  String _formatDateTime(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
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
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const TeacherTestResultsScreen())),
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
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const CreateTestScreen())),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  itemCount: tests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final t = tests[i];
                    return TestCard(
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

// ── Test Card ─────────────────────────────────────────────────────────────────

class TestCard extends StatelessWidget {
  final TestModel test;
  final String Function(DateTime) formatDateTime;

  const TestCard({super.key, required this.test, required this.formatDateTime});

  Color get _statusColor {
    if (test.isPublished) return AppColors.success;
    if (test.isExpired) return AppColors.error;
    return AppColors.warning;
  }

  String get _statusLabel {
    if (test.isPublished) return 'Published';
    if (test.isExpired) return 'Expired';
    return 'Pending';
  }

  IconData get _statusIcon {
    if (test.isPublished) return Symbols.check_circle;
    if (test.isExpired) return Symbols.timer_off;
    return Symbols.schedule;
  }

  void _showMenu(BuildContext context) {
    final appState = context.read<AppState>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: false,
      builder: (sheetCtx) => TestMenuSheet(
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
    final attempts = context.read<AppState>().attemptsForTest(test.id);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_statusIcon, color: _statusColor, size: 22),
            ),
            const SizedBox(width: 12),
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
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              GestureDetector(
                onTap: () => _showMenu(context),
                child: Container(
                  width: 32,
                  height: 32,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        const Divider(color: AppColors.border, height: 1),
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
                  _Stat(
                      icon: Symbols.timer,
                      label: '${test.durationMinutes} mins'),
                  _Stat(
                      icon: Symbols.help,
                      label: '${test.questionCount} Qs'),
                  _Stat(
                      icon: Symbols.person,
                      label: '${attempts.length} done'),
                ],
              ),
              if (test.expiresAt != null)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Symbols.calendar_month,
                      color: AppColors.textMuted, size: 13),
                  const SizedBox(width: 4),
                  Text(formatDateTime(test.expiresAt!),
                      style: GoogleFonts.poppins(
                          color: test.isExpired
                              ? AppColors.error
                              : AppColors.textMuted,
                          fontSize: 11)),
                ]),
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
          style:
              GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 12)),
    ]);
  }
}

// ── Test Menu Sheet ───────────────────────────────────────────────────────────

class TestMenuSheet extends StatelessWidget {
  final TestModel test;
  final String Function(DateTime) formatDateTime;
  final AppState appState;
  final NavigatorState navigator;
  final ScaffoldMessengerState messenger;

  const TestMenuSheet({
    super.key,
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
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Container(
            width: 42,
            height: 42,
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

        // Edit
        TeacherMenuItem(
          icon: Symbols.edit,
          iconColor: AppColors.primary,
          label: 'Edit Test',
          subtitle: 'Change name, questions or expiry date',
          onTap: () {
            Navigator.pop(context);
            Future.delayed(const Duration(milliseconds: 150), () {
              navigator.push(
                  MaterialPageRoute(
                      builder: (_) => EditTestScreen(test: test)));
            });
          },
        ),
        const SizedBox(height: 8),

        // Publish / Unpublish
        TeacherMenuItem(
          icon: test.isPublished ? Symbols.pause : Symbols.publish,
          iconColor: test.isPublished ? AppColors.warning : AppColors.success,
          label: test.isPublished ? 'Unpublish Test' : 'Publish Test',
          subtitle: test.isPublished
              ? 'Stop students from taking this test'
              : 'Make this test available to students',
          onTap: () async {
            Navigator.pop(context);
            await Future.delayed(const Duration(milliseconds: 150));
            final err = await appState.toggleTestPublish(test.id,
                isPublished: !test.isPublished);
            if (err != null) {
              _showError(err);
            } else {
              _showSuccess(
                  test.isPublished ? 'Test unpublished' : 'Test published');
            }
          },
        ),
        const SizedBox(height: 8),

        // Extend Expiry
        TeacherMenuItem(
          icon: Symbols.calendar_month,
          iconColor: const Color(0xFF5B2FD4),
          label: 'Extend Expiry',
          subtitle: test.expiresAt != null
              ? 'Current: ${formatDateTime(test.expiresAt!)}'
              : 'Set a new expiration date',
          onTap: () async {
            Navigator.pop(context);
            await Future.delayed(const Duration(milliseconds: 150));

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
                    backgroundColor: Color(0xFF0A0A0A)),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF5B2FD4)),
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
                ? TimeOfDay(
                    hour: test.expiresAt!.hour,
                    minute: test.expiresAt!.minute)
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

            final err = await appState.extendTestExpiry(
                testId: test.id, newExpiry: picked);
            if (err != null) {
              _showError(err);
            } else {
              _showSuccess('Expiry extended to ${formatDateTime(picked)}');
            }
          },
        ),
        const SizedBox(height: 8),

        // Delete
        TeacherMenuItem(
          icon: Symbols.delete,
          iconColor: AppColors.error,
          label: 'Delete Test',
          subtitle: 'Permanently remove this test and all attempts',
          destructive: true,
          onTap: () {
            Navigator.pop(context);
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
                        Navigator.pop(dialogCtx);
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
