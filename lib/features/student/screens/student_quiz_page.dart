import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models.dart';
import '../quiz/join_live_quiz_screen.dart';
import 'student_test_detail_screen.dart';

// ── Quiz / Tests Page ─────────────────────────────────────────────────────────
class StudentQuizPage extends StatefulWidget {
  const StudentQuizPage({super.key});

  @override
  State<StudentQuizPage> createState() => _StudentQuizPageState();
}

class _StudentQuizPageState extends State<StudentQuizPage> {
  bool _isUpcoming = true;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final myClasses = state.myClasses.map((c) => c.id).toSet();
    final allTests = state.allTests.where((t) => myClasses.contains(t.classId)).toList();
    final myAttempts = state.myAttempts;

    List<TestModel> displayedTests = [];

    if (_isUpcoming) {
      displayedTests = allTests.where((t) {
        if (!t.isPublished) return false;
        if (t.isExpired) return false;
        final attemptCount = myAttempts.where((a) => a.testId == t.id).length;
        return attemptCount < t.maxAttempts;
      }).toList();
    } else {
      displayedTests = allTests.where((t) {
        if (!t.isPublished) return false;
        final attemptCount = myAttempts.where((a) => a.testId == t.id).length;
        final isMaxed = attemptCount >= t.maxAttempts;
        final isExp = t.isExpired;
        return attemptCount > 0 || isMaxed || isExp;
      }).toList();
    }

    return SafeArea(
      bottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Text('My Tests',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),

        // ── Join Live Quiz banner ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const JoinLiveQuizScreen())),
            child: Container(
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle),
                  child: const Icon(Symbols.wifi_tethering,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Text('Join Live Quiz',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    Text('Enter PIN from your teacher',
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 11)),
                  ]),
                ),
                const Icon(Symbols.arrow_forward, color: Colors.white, size: 18),
              ]),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 12),

        // ── Filter tabs ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            GestureDetector(
              onTap: () => setState(() => _isUpcoming = true),
              child: Container(
                height: 36,
                width: 100,
                decoration: BoxDecoration(
                    color: _isUpcoming ? AppColors.warning : AppColors.surface,
                    borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text('Upcoming',
                    style: GoogleFonts.poppins(
                        color: _isUpcoming ? AppColors.bg : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: _isUpcoming ? FontWeight.w600 : FontWeight.normal)),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _isUpcoming = false),
              child: Container(
                height: 36,
                width: 80,
                decoration: BoxDecoration(
                    color: !_isUpcoming ? AppColors.warning : AppColors.surface,
                    borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text('Done',
                    style: GoogleFonts.poppins(
                        color: !_isUpcoming ? AppColors.bg : AppColors.textSecondary, 
                        fontSize: 12,
                        fontWeight: !_isUpcoming ? FontWeight.w600 : FontWeight.normal)),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 12),

        // ── Test list ─────────────────────────────────────────────────────
        Expanded(
          child: displayedTests.isEmpty
              ? Center(
                  child: Text(_isUpcoming ? 'No tests scheduled' : 'No tests completed',
                      style:
                          GoogleFonts.poppins(color: AppColors.textSecondary)))
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  itemCount: displayedTests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _TestCard(test: displayedTests[i], index: i),
                ),
        ),
      ]),
    );
  }
}

// ── Test Card ─────────────────────────────────────────────────────────────────
class _TestCard extends StatelessWidget {
  final TestModel test;
  final int index;
  const _TestCard({required this.test, required this.index});

  String _formatExpiry(DateTime? d) {
    if (d == null) return 'No expiry';
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final attemptCount = state.myAttempts.where((a) => a.testId == test.id).length;
    final maxAttemptsReached = attemptCount >= test.maxAttempts;
    final isExpired = test.isExpired;
    final isLocked = maxAttemptsReached || isExpired;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentTestDetailScreen(test: test),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLocked ? AppColors.error.withOpacity(0.1) : AppColors.primary.withOpacity(0.1)
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(test.subject,
                  style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(test.title,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ]),
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                  color: isLocked ? AppColors.errorLight : AppColors.successLight,
                  borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Text(
                  maxAttemptsReached 
                    ? 'Completed' 
                    : (isExpired ? 'Expired' : 'Available'),
                  style: GoogleFonts.poppins(
                      color: isLocked ? AppColors.error : AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _Meta(Symbols.schedule, '${test.durationMinutes}m'),
            const SizedBox(width: 12),
            _Meta(Symbols.help, '${test.questionCount} Qs'),
            const SizedBox(width: 12),
            _Meta(Symbols.history, '$attemptCount/${test.maxAttempts} Tries'),
          ]),
          if (test.expiresAt != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Symbols.event_busy, color: isExpired ? AppColors.error : AppColors.textMuted, size: 12),
              const SizedBox(width: 4),
              Text(
                'Expires: ${_formatExpiry(test.expiresAt)}',
                style: GoogleFonts.poppins(
                    color: isExpired ? AppColors.error : AppColors.textMuted, 
                    fontSize: 11),
              ),
            ]),
          ],
        ]),
      ).animate().fadeIn(delay: (index * 60).ms),
    );
  }

  Widget _Meta(IconData icon, String label) => Row(children: [
    Icon(icon, color: AppColors.textSecondary, size: 14),
    const SizedBox(width: 4),
    Text(label, style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
  ]);
}
