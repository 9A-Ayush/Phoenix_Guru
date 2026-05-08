import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models.dart';
import '../../../shared/widgets/widgets.dart';

// ── Test Attempt Screen ───────────────────────────────────────────────────────

class TestAttemptScreen extends StatefulWidget {
  final TestModel test;
  const TestAttemptScreen({super.key, required this.test});

  @override
  State<TestAttemptScreen> createState() => _TestAttemptScreenState();
}

class _TestAttemptScreenState extends State<TestAttemptScreen> {
  int _current = 0;
  final Map<String, int> _answers = {};
  bool _submitted = false;
  QuizAttempt? _result;

  QuizQuestion get _question => widget.test.questions[_current];
  bool get _hasAnswer => _answers.containsKey(_question.id);
  double get _progress => (_current + 1) / widget.test.questions.length;

  void _select(int idx) {
    if (_submitted) return;
    setState(() => _answers[_question.id] = idx);
  }

  void _next() {
    if (_current < widget.test.questions.length - 1) {
      setState(() => _current++);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    final attempt = await context.read<AppState>().submitAttempt(
      testId: widget.test.id,
      testTitle: widget.test.title,
      answers: Map.from(_answers),
    );
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TestResultScreen(
      attempt: attempt, test: widget.test,
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          // Top bar
          Container(
            height: 72, padding: const EdgeInsets.symmetric(horizontal: 20),
            color: AppColors.surface,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(widget.test.className, style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              Container(
                height: 36, padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Symbols.timer, color: AppColors.error, size: 16),
                  const SizedBox(width: 6),
                  Text('${widget.test.durationMinutes}:00', style: GoogleFonts.poppins(color: AppColors.error, fontSize: 15, fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
          ),
          // Progress bar
          Stack(children: [
            Container(height: 4, color: AppColors.surface2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: 4, width: MediaQuery.of(context).size.width * _progress,
              color: AppColors.primary,
            ),
          ]),

          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Question ${_current + 1} of ${widget.test.questions.length}',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Q${_current + 1}.', style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(_question.question, style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                ]),
              ),
              const SizedBox(height: 20),
              ..._question.options.asMap().entries.map((e) {
                final selected = _answers[_question.id] == e.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => _select(e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
                      ),
                      child: Row(children: [
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: selected ? Colors.white.withOpacity(0.2) : AppColors.surface2,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(String.fromCharCode(65 + e.key),
                              style: GoogleFonts.poppins(color: selected ? Colors.white : AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Text(e.value, style: GoogleFonts.poppins(
                            color: selected ? Colors.white : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
                        if (selected) const Icon(Symbols.check_circle, color: Colors.white, size: 20),
                      ]),
                    ),
                  ).animate().fadeIn(delay: (e.key * 50).ms),
                );
              }),

              const SizedBox(height: 16),
              // Anti-cheat banner
              Container(
                height: 48, padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.errorLight, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Symbols.security, color: AppColors.error, size: 18),
                  const SizedBox(width: 10),
                  Text('Anti-cheat active  •  Do not leave this screen',
                      style: GoogleFonts.poppins(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500)),
                ]),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: _current < widget.test.questions.length - 1 ? 'Next Question' : 'Submit Test',
                icon: _current < widget.test.questions.length - 1 ? Symbols.arrow_forward : Symbols.check_circle,
                onTap: _hasAnswer ? _next : null,
              ),
            ]),
          )),
        ]),
      ),
    );
  }
}

// ── Test Result Screen ────────────────────────────────────────────────────────

class TestResultScreen extends StatelessWidget {
  final QuizAttempt attempt;
  final TestModel test;
  const TestResultScreen({super.key, required this.attempt, required this.test});

  double get _score {
    if (test.questions.isEmpty) return 0;
    int correct = 0;
    for (final q in test.questions) {
      if (attempt.answers[q.id] == q.correctIndex) correct++;
    }
    return correct / test.questions.length;
  }

  String get _grade {
    final s = _score;
    if (s >= 0.9) return 'A+';
    if (s >= 0.8) return 'A';
    if (s >= 0.7) return 'B';
    if (s >= 0.6) return 'C';
    return 'D';
  }

  Color get _gradeColor {
    final s = _score;
    if (s >= 0.8) return AppColors.success;
    if (s >= 0.6) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final pct = (_score * 100).round();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        Positioned(top: -80, right: -80,
          child: Container(width: 300, height: 300,
            decoration: const BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Color(0x446C47FF), Colors.transparent])))),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const SizedBox(height: 12),
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const AppBackButton(),
                ),
              ]),
              const SizedBox(height: 40),
              // Score circle
              Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _gradeColor.withOpacity(0.15),
                  border: Border.all(color: _gradeColor, width: 3),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_grade, style: GoogleFonts.poppins(color: _gradeColor, fontSize: 40, fontWeight: FontWeight.w800)),
                  Text('$pct%', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ]),
              ).animate().scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text('Test Complete!', style: GoogleFonts.poppins(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700))
                  .animate().fadeIn(delay: 300.ms),
              Text(test.title, style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14))
                  .animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 28),
              // Stats row
              Container(
                height: 72, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  _statItem('${attempt.answers.length}', 'Answered', AppColors.primary),
                  Container(width: 1, height: 40, color: AppColors.border),
                  _statItem('$pct%', 'Score', _gradeColor),
                  Container(width: 1, height: 40, color: AppColors.border),
                  _statItem('#${attempt.rank}', 'Rank', AppColors.warning),
                ]),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 24),
              // Answer review
              Text('Answer Review', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...test.questions.asMap().entries.map((e) {
                final q = e.value;
                final userAns = attempt.answers[q.id];
                final correct = userAns == q.correctIndex;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: correct ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 22, height: 22, decoration: BoxDecoration(
                        color: correct ? AppColors.successLight : AppColors.errorLight, shape: BoxShape.circle),
                        child: Icon(correct ? Symbols.check : Symbols.close, color: correct ? AppColors.success : AppColors.error, size: 14)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(q.question, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13))),
                    ]),
                    const SizedBox(height: 8),
                    Text('Your answer: ${userAns != null ? q.options[userAns] : "Skipped"}',
                        style: GoogleFonts.poppins(color: correct ? AppColors.success : AppColors.error, fontSize: 12)),
                    if (!correct)
                      Text('Correct: ${q.options[q.correctIndex]}',
                          style: GoogleFonts.poppins(color: AppColors.success, fontSize: 12)),
                  ]),
                );
              }),
              const SizedBox(height: 24),
              AppButton(label: 'Back to Home', onTap: () => Navigator.of(context).popUntil((r) => r.isFirst)),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _statItem(String value, String label, Color color) {
    return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(value, style: GoogleFonts.poppins(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
      Text(label, style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11)),
    ]));
  }
}

// ── Quiz Results List Screen ──────────────────────────────────────────────────

class QuizResultsListScreen extends StatelessWidget {
  const QuizResultsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final attempts = context.watch<AppState>().myAttempts;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Row(children: [
              const AppBackButton(),
              const SizedBox(width: 16),
              Text('My Quiz Results', style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 16),
          if (attempts.isNotEmpty) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 72,
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                _stat('${attempts.length}', 'Quizzes', AppColors.primary),
                Container(width: 1, height: 36, color: AppColors.border),
                _stat('82%', 'Avg Score', AppColors.success),
                Container(width: 1, height: 36, color: AppColors.border),
                _stat('#2', 'Best Rank', AppColors.warning),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: attempts.isEmpty
                ? Center(child: Text('No quiz attempts yet', style: GoogleFonts.poppins(color: AppColors.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    itemCount: attempts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final a = attempts[i];
                      return Container(
                        height: 80, padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [
                          Container(width: 50, height: 50, decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(14)),
                              alignment: Alignment.center,
                              child: Text('A', style: GoogleFonts.poppins(color: AppColors.success, fontSize: 20, fontWeight: FontWeight.w700))),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(a.testTitle, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            Container(height: 4, margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                              child: Align(alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(widthFactor: 0.84,
                                  child: Container(decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(2)))))),
                            Text('Rank #${a.rank} of ${a.totalParticipants}', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11)),
                          ])),
                          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('84%', style: GoogleFonts.poppins(color: AppColors.success, fontSize: 18, fontWeight: FontWeight.w700)),
                            Text('84/100', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11)),
                          ]),
                        ]),
                      ).animate().fadeIn(delay: (i * 60).ms);
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _stat(String v, String l, Color c) {
    return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(v, style: GoogleFonts.poppins(color: c, fontSize: 20, fontWeight: FontWeight.w700)),
      Text(l, style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 10)),
    ]));
  }
}
