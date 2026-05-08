import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models.dart';
import '../../../shared/widgets/widgets.dart';

class CreateTestScreen extends StatefulWidget {
  const CreateTestScreen({super.key});

  @override
  State<CreateTestScreen> createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<CreateTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  int _duration = 60;
  String? _selectedClassId;
  bool _loading = false;
  final List<_QuestionData> _questions = [];

  @override
  void initState() {
    super.initState();
    // Add a sample question
    _questions.add(_QuestionData(
      question: 'Which law states that every action has an equal and opposite reaction?',
      options: ["Newton's First Law", "Newton's Second Law", "Newton's Third Law", "Law of Gravitation"],
      correctIndex: 2,
    ));
  }

  @override
  void dispose() { _titleCtrl.dispose(); super.dispose(); }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please select a class', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Add at least one question', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    setState(() => _loading = true);
    final questions = _questions.map((q) => QuizQuestion(question: q.question, options: q.options, correctIndex: q.correctIndex)).toList();
    await context.read<AppState>().createTest(
      title: _titleCtrl.text.trim(),
      classId: _selectedClassId!,
      durationMinutes: _duration,
      questions: questions,
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Test published!', style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _addQuestion() {
    showDialog(context: context, builder: (_) => _AddQuestionDialog(
      onSave: (q) => setState(() => _questions.add(q)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<AppState>().myClasses;
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
              Text('Create Test', style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),

              // Title
              _Lbl('Test Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                validator: (v) => (v == null || v.isEmpty) ? 'Title required' : null,
                decoration: InputDecoration(
                  hintText: 'e.g. Physics Chapter 4 Test',
                  prefixIcon: const Icon(Symbols.edit, color: AppColors.textMuted, size: 18),
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 16),
              // Assign to class
              _Lbl('Assign to Class'),
              const SizedBox(height: 8),
              Container(
                height: 52, padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _selectedClassId != null ? AppColors.primary : AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedClassId,
                    hint: Text('Select a class', style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 14)),
                    dropdownColor: AppColors.surface2,
                    icon: const Icon(Symbols.keyboard_arrow_down, color: AppColors.textMuted, size: 18),
                    isExpanded: true,
                    items: classes.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Row(children: [
                        Icon(Symbols.science, color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Text(c.name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                      ]),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedClassId = v),
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 16),
              // Duration + Q count row
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _Lbl('Duration'),
                  const SizedBox(height: 8),
                  Container(
                    height: 52, padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _duration,
                        dropdownColor: AppColors.surface2,
                        icon: const SizedBox(),
                        isExpanded: true,
                        items: [30, 45, 60, 90, 120].map((d) => DropdownMenuItem(
                          value: d,
                          child: Row(children: [
                            const Icon(Symbols.timer, color: AppColors.textMuted, size: 18),
                            const SizedBox(width: 10),
                            Text('$d mins', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                          ]),
                        )).toList(),
                        onChanged: (v) => setState(() => _duration = v ?? 60),
                      ),
                    ),
                  ),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _Lbl('Questions'),
                  const SizedBox(height: 8),
                  Container(
                    height: 52, padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                    child: Row(children: [
                      const Icon(Symbols.help, color: AppColors.textMuted, size: 18),
                      const SizedBox(width: 10),
                      Text('${_questions.length}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ])),
              ]).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Questions', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                Text('${_questions.length} added', style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 12)),
              ]),
              const SizedBox(height: 12),

              ..._questions.asMap().entries.map((e) {
                final q = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('Q${e.key + 1}', style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _questions.removeAt(e.key)),
                        child: const Icon(Symbols.delete, color: AppColors.textMuted, size: 18),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text(q.question, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: q.options.asMap().entries.map((opt) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: opt.key == q.correctIndex ? AppColors.successLight : AppColors.surface2,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${String.fromCharCode(65 + opt.key)} ${opt.key == q.correctIndex ? '✓' : ''}',
                        style: GoogleFonts.poppins(
                            color: opt.key == q.correctIndex ? AppColors.success : AppColors.textSecondary,
                            fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    )).toList()),
                  ]),
                ).animate().fadeIn(delay: (e.key * 50).ms);
              }),

              // Add Question button
              GestureDetector(
                onTap: _addQuestion,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surface, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withOpacity(0.27)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Symbols.add, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Add Question', style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _publish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Symbols.publish, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text('Publish Test', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        ]),
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

Widget _Lbl(String t) => Text(t, style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500));

class _QuestionData {
  String question;
  List<String> options;
  int correctIndex;
  _QuestionData({required this.question, required this.options, required this.correctIndex});
}

class _AddQuestionDialog extends StatefulWidget {
  final void Function(_QuestionData) onSave;
  const _AddQuestionDialog({required this.onSave});

  @override
  State<_AddQuestionDialog> createState() => _AddQuestionDialogState();
}

class _AddQuestionDialogState extends State<_AddQuestionDialog> {
  final _qCtrl = TextEditingController();
  final _optCtrls = List.generate(4, (_) => TextEditingController());
  int _correct = 0;

  @override
  void dispose() { _qCtrl.dispose(); for (final c in _optCtrls) c.dispose(); super.dispose(); }

  void _save() {
    if (_qCtrl.text.isEmpty) return;
    final opts = _optCtrls.map((c) => c.text.isEmpty ? 'Option' : c.text).toList();
    widget.onSave(_QuestionData(question: _qCtrl.text, options: opts, correctIndex: _correct));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Add Question', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _qCtrl,
            maxLines: 2,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(hintText: 'Enter question...', contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              filled: true, fillColor: AppColors.surface),
          ),
          const SizedBox(height: 16),
          Text('Options (tap radio to mark correct):', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          ...List.generate(4, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Radio<int>(value: i, groupValue: _correct,
                  activeColor: AppColors.success,
                  onChanged: (v) => setState(() => _correct = v!)),
              Expanded(child: TextFormField(
                controller: _optCtrls[i],
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: '${String.fromCharCode(65 + i)}. Option ${i + 1}',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                  filled: true, fillColor: AppColors.surface),
              )),
            ]),
          )),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
            )),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text('Save', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            )),
          ]),
        ])),
      ),
    );
  }
}
