import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models.dart';
import 'create_quiz_screen.dart';
import 'create_test_screen.dart';
import 'live_session_lobby_screen.dart';
import 'active_sessions_screen.dart';

// ── Quiz (Live) Page ──────────────────────────────────────────────────────────

class TeacherQuizPage extends StatelessWidget {
  const TeacherQuizPage({super.key});

  void _pickTest(BuildContext context, List<TestModel> tests) {
    if (tests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Create a test first to start a live quiz.',
            style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LiveSessionLobbyScreen(test: test)));
  }

  @override
  Widget build(BuildContext context) {
    final tests = context.watch<AppState>().allTests;
    final hostId = context.read<AppState>().currentUser?.id ?? '';

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
          // ── Header ────────────────────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
                          hostId: hostId, tests: tests),
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
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Icon(Symbols.live_tv,
                          color: count > 0
                              ? AppColors.success
                              : AppColors.textMuted,
                          size: 15),
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
          ]),
          const SizedBox(height: 20),

          // ── Create new quiz ───────────────────────────────────────────────
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
                  width: 56,
                  height: 56,
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

          // ── Start from existing test ──────────────────────────────────────
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
                  width: 56,
                  height: 56,
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

          // ── How it works ──────────────────────────────────────────────────
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
                    width: 38,
                    height: 38,
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

// ── Test Picker Sheet ─────────────────────────────────────────────────────────

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
          width: 40,
          height: 4,
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
              maxHeight: MediaQuery.of(context).size.height * 0.45),
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
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12)),
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
                              color: AppColors.textSecondary, fontSize: 11),
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
