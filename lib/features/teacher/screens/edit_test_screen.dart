import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models.dart';
import '../../../core/providers/app_state.dart';

class EditTestScreen extends StatefulWidget {
  final TestModel test;
  const EditTestScreen({super.key, required this.test});

  @override
  State<EditTestScreen> createState() => _EditTestScreenState();
}

class _EditTestScreenState extends State<EditTestScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late List<_QData> _questions;
  late DateTime? _expiresAt;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.test.title);
    _questions = widget.test.questions
        .map((q) => _QData(
              id: q.id,
              question: q.question,
              options: List<String>.from(q.options),
              correctIndex: q.correctIndex,
            ))
        .toList();
    _expiresAt = widget.test.expiresAt;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt != null && _expiresAt!.isAfter(today)
          ? _expiresAt!
          : today.add(const Duration(days: 1)),
      firstDate: today.add(const Duration(days: 1)),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
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
              textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      setState(() => _error = 'Add at least one question');
      return;
    }
    setState(() { _saving = true; _error = null; });

    final questions = _questions.map((q) => QuizQuestion(
      id: q.id,
      question: q.question,
      options: q.options,
      correctIndex: q.correctIndex,
    )).toList();

    final appState = context.read<AppState>();

    // Update title + questions
    String? err = await appState.updateTest(
      testId: widget.test.id,
      title: _titleCtrl.text.trim(),
      questions: questions,
    );

    // Update expiry if changed
    if (err == null && _expiresAt != widget.test.expiresAt && _expiresAt != null) {
      err = await appState.extendTestExpiry(
        testId: widget.test.id,
        newExpiry: _expiresAt!,
      );
    }

    if (!mounted) return;
    if (err != null) {
      setState(() { _saving = false; _error = err; });
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Test updated!',
            style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (_) => _QuestionDialog(
        onSave: (q) => setState(() => _questions.add(q)),
      ),
    );
  }

  void _editQuestion(int index) {
    showDialog(
      context: context,
      builder: (_) => _QuestionDialog(
        existing: _questions[index],
        onSave: (q) => setState(() => _questions[index] = q),
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
          child: Column(children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              color: AppColors.surface,
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chevron_left_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('Edit Test',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                ),
                GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: _saving
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('Save',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Title
                  _Label('Test Title'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleCtrl,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Title required' : null,
                    decoration: InputDecoration(
                      hintText: 'e.g. Physics Chapter 4 Test',
                      prefixIcon: const Icon(Symbols.edit,
                          color: AppColors.textMuted, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 16),

                  // Expiry date
                  _Label('Expiration Date'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _expiresAt != null
                              ? const Color(0xFF5B2FD4)
                              : AppColors.border,
                          width: _expiresAt != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Icon(Symbols.calendar_month,
                            color: _expiresAt != null
                                ? const Color(0xFF5B2FD4)
                                : AppColors.textMuted,
                            size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _expiresAt != null
                                ? _formatDate(_expiresAt!)
                                : 'No expiry set',
                            style: GoogleFonts.poppins(
                              color: _expiresAt != null
                                  ? Colors.white
                                  : AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Icon(Symbols.edit,
                            color: AppColors.textMuted, size: 16),
                      ]),
                    ),
                  ).animate().fadeIn(delay: 150.ms),

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
                      Text('${_questions.length} total',
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
                      height: 46,
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
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_error!,
                          style: GoogleFonts.poppins(
                              color: AppColors.error, fontSize: 13)),
                    ),
                  ],

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ]),
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
  final String id;
  String question;
  List<String> options;
  int correctIndex;

  _QData({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

// ── Question add/edit dialog ──────────────────────────────────────────────────

class _QuestionDialog extends StatefulWidget {
  final _QData? existing;
  final void Function(_QData) onSave;

  const _QuestionDialog({this.existing, required this.onSave});

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  late final TextEditingController _qCtrl;
  late final List<TextEditingController> _optCtrls;
  late int _correct;

  @override
  void initState() {
    super.initState();
    _qCtrl = TextEditingController(text: widget.existing?.question ?? '');
    _optCtrls = List.generate(4, (i) =>
        TextEditingController(
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
      id: widget.existing?.id ?? UniqueKey().toString(),
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
            Text(widget.existing != null ? 'Edit Question' : 'Add Question',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
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
