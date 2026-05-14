import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models.dart';
import '../../../shared/widgets/widgets.dart';
import 'live_session_lobby_screen.dart';

// ── Create Quiz Screen ────────────────────────────────────────────────────────
// A lightweight quiz builder for live sessions.
// Unlike CreateTestScreen, this has no class/expiry/attempts fields —
// it's purely for building a live quiz to launch immediately.

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  int _timerSeconds = 20; // per-question timer
  bool _loading = false;
  final List<_QData> _questions = [];

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (_) => _QuizQuestionDialog(
        onSave: (q) => setState(() => _questions.add(q)),
      ),
    );
  }

  void _editQuestion(int index) {
    showDialog(
      context: context,
      builder: (_) => _QuizQuestionDialog(
        existing: _questions[index],
        onSave: (q) => setState(() => _questions[index] = q),
      ),
    );
  }

  Future<void> _launch() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      _showError('Add at least one question');
      return;
    }
    if (_questions.length > 30) {
      _showError('Maximum 30 questions per quiz');
      return;
    }

    setState(() => _loading = true);

    // Build a TestModel from the quiz data (reuses existing model)
    // classId/className are empty since this is a standalone live quiz
    final appState = context.read<AppState>();
    final user = appState.currentUser!;

    final questions = _questions.map((q) => QuizQuestion(
      question: q.question,
      options: q.options,
      correctIndex: q.correctIndex,
    )).toList();

    // Create a temporary test doc in Firestore so the session can reference it
    final test = TestModel(
      title: _titleCtrl.text.trim(),
      subject: 'Live Quiz',
      classId: 'live_quiz',
      className: 'Live Quiz',
      durationMinutes: (_timerSeconds * questions.length) ~/ 60 + 1,
      questions: questions,
      isLive: true,
    );

    try {
      await appState.firestoreInstance
          .collection('tests')
          .doc(test.id)
          .set(test.toMap());
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Failed to save quiz. Check your connection.');
      return;
    }

    if (!mounted) return;
    setState(() => _loading = false);

    // Navigate to lobby — lobby creates the live session
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LiveSessionLobbyScreen(test: test),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 12),
              const AppBackButton(),
              const SizedBox(height: 20),

              // Heading
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Symbols.live_tv,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Create Live Quiz',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  Text('Launch instantly — no class needed',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 12)),
                ]),
              ]).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 28),

              // Quiz title
              _Label('Quiz Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title required' : null,
                decoration: InputDecoration(
                  hintText: 'e.g. Newton\'s Laws Quick Quiz',
                  prefixIcon: const Icon(Symbols.edit,
                      color: AppColors.textMuted, size: 18),
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.15, end: 0),

              const SizedBox(height: 16),

              // Timer per question
              _Label('Time per Question'),
              const SizedBox(height: 8),
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _timerSeconds,
                    dropdownColor: AppColors.surface2,
                    icon: const Icon(Symbols.keyboard_arrow_down,
                        color: AppColors.textMuted, size: 18),
                    isExpanded: true,
                    items: [10, 15, 20, 30, 45, 60].map((s) => DropdownMenuItem(
                      value: s,
                      child: Row(children: [
                        const Icon(Symbols.timer,
                            color: AppColors.textMuted, size: 18),
                        const SizedBox(width: 12),
                        Text('$s seconds',
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 14)),
                      ]),
                    )).toList(),
                    onChanged: (v) =>
                        setState(() => _timerSeconds = v ?? 20),
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.15, end: 0),

              const SizedBox(height: 24),

              // Questions header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Questions',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  Text('${_questions.length} added',
                      style: GoogleFonts.poppins(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),

              // Question list
              ..._questions.asMap().entries.map((e) {
                final i = e.key;
                final q = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Container(
                        height: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text('Q${i + 1}',
                            style: GoogleFonts.poppins(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _editQuestion(i),
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Symbols.edit,
                              color: AppColors.textMuted, size: 15),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _questions.removeAt(i)),
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Symbols.delete,
                              color: AppColors.error, size: 15),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(q.question,
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: q.options.asMap().entries.map((opt) {
                        final isCorrect = opt.key == q.correctIndex;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? AppColors.successLight
                                : AppColors.surface2,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${String.fromCharCode(65 + opt.key)}${isCorrect ? ' ✓' : ''}',
                            style: GoogleFonts.poppins(
                                color: isCorrect
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                  ]),
                ).animate().fadeIn(delay: (i * 40).ms);
              }),

              // Add question button
              GestureDetector(
                onTap: _addQuestion,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    const Icon(Symbols.add,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Add Question',
                        style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 20),

              // Launch button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _launch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Symbols.rocket_launch,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('Launch Quiz',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ).animate().fadeIn(delay: 350.ms),

              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.poppins(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500));
}

class _QData {
  String question;
  List<String> options;
  int correctIndex;

  _QData({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

// ── Question dialog ───────────────────────────────────────────────────────────

class _QuizQuestionDialog extends StatefulWidget {
  final _QData? existing;
  final void Function(_QData) onSave;

  const _QuizQuestionDialog({this.existing, required this.onSave});

  @override
  State<_QuizQuestionDialog> createState() => _QuizQuestionDialogState();
}

class _QuizQuestionDialogState extends State<_QuizQuestionDialog> {
  late final TextEditingController _qCtrl;
  late final List<TextEditingController> _optCtrls;
  late int _correct;

  @override
  void initState() {
    super.initState();
    _qCtrl = TextEditingController(text: widget.existing?.question ?? '');
    _optCtrls = List.generate(4, (i) => TextEditingController(
        text: (widget.existing?.options.length ?? 0) > i
            ? widget.existing!.options[i]
            : ''));
    _correct = widget.existing?.correctIndex ?? 0;
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    for (final c in _optCtrls) c.dispose();
    super.dispose();
  }

  void _save() {
    if (_qCtrl.text.trim().isEmpty) return;
    final opts = _optCtrls
        .map((c) => c.text.trim().isEmpty ? 'Option' : c.text.trim())
        .toList();
    widget.onSave(_QData(
      question: _qCtrl.text.trim(),
      options: opts,
      correctIndex: _correct,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(
              widget.existing != null ? 'Edit Question' : 'Add Question',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _qCtrl,
              maxLines: 2,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Enter question...',
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2)),
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
            const SizedBox(height: 14),
            Text('Options — tap radio to mark correct',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            ...List.generate(4, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Radio<int>(
                  value: i,
                  groupValue: _correct,
                  activeColor: AppColors.success,
                  onChanged: (v) => setState(() => _correct = v!),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _optCtrls[i],
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText:
                          '${String.fromCharCode(65 + i)}. Option ${i + 1}',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.primary)),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                ),
              ]),
            )),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Save',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
