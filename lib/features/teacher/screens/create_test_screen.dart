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
  String? _selectedSubject;
  int _duration = 60;
  String? _selectedClassId;
  DateTime? _expiresAt;   // stores full date + time
  int _maxAttempts = 1;
  bool _isPublished = true;
  bool _loading = false;
  final List<_QuestionData> _questions = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() { _titleCtrl.dispose(); super.dispose(); }

  // ── Date + time picker ────────────────────────────────────────────────────

  ThemeData get _calendarTheme => ThemeData.dark().copyWith(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF5B2FD4),
      onPrimary: Colors.white,
      surface: Color(0xFF0A0A0A),
      onSurface: Colors.white,
      secondary: Color(0xFF5B2FD4),
      onSecondary: Colors.white,
      tertiary: Color(0xFF5B2FD4),
      onTertiary: Colors.white,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF0A0A0A)),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF5B2FD4),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: const Color(0xFF0A0A0A),
      hourMinuteColor: const Color(0xFF5B2FD4),
      hourMinuteTextColor: Colors.white,
      dayPeriodColor: const Color(0xFF5B2FD4),
      dayPeriodTextColor: Colors.white,
      dialHandColor: const Color(0xFF5B2FD4),
      dialBackgroundColor: const Color(0xFF1A1A1A),
      dialTextColor: Colors.white,
      entryModeIconColor: const Color(0xFF5B2FD4),
      helpTextStyle: GoogleFonts.poppins(color: Colors.white),
    ),
  );

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Step 1 — pick date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? today.add(const Duration(days: 1)),
      firstDate: today.add(const Duration(days: 1)),
      lastDate: DateTime(now.year + 2),
      builder: (_, child) => Theme(data: _calendarTheme, child: child!),
    );
    if (pickedDate == null || !mounted) return;

    // Step 2 — pick time
    final initialTime = _expiresAt != null
        ? TimeOfDay(hour: _expiresAt!.hour, minute: _expiresAt!.minute)
        : const TimeOfDay(hour: 23, minute: 59);

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (_, child) => Theme(data: _calendarTheme, child: child!),
    );
    if (pickedTime == null) return;

    setState(() {
      _expiresAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  String _formatDateTime(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}  •  $h:$m';
  }

  // ── Publish ───────────────────────────────────────────────────────────────

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) { _showError('Please select a class'); return; }
    if (_expiresAt == null)       { _showError('Please set an expiration date & time'); return; }
    if (_questions.isEmpty)       { _showError('Add at least one question'); return; }
    if (_questions.length > 30)   { _showError('Maximum 30 questions per test'); return; }

    setState(() => _loading = true);
    final questions = _questions.map((q) => QuizQuestion(
      question: q.question,
      options: q.options,
      correctIndex: q.correctIndex,
    )).toList();

    await context.read<AppState>().createTest(
      title: _titleCtrl.text.trim(),
      subject: _selectedSubject ?? 'General',
      classId: _selectedClassId!,
      durationMinutes: _duration,
      questions: questions,
      expiresAt: _expiresAt,
      maxAttempts: _maxAttempts,
      isPublished: _isPublished,
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isPublished ? 'Test published!' : 'Test saved to drafts!',
          style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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
      builder: (_) => _AddQuestionDialog(
        onSave: (q) => setState(() => _questions.add(q)),
      ),
    );
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
              // Subject
              _Lbl('Subject'),
              const SizedBox(height: 8),
              Container(
                height: 52, padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _selectedSubject != null ? AppColors.primary : AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSubject,
                    hint: Text('Select Subject', style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 14)),
                    dropdownColor: AppColors.surface2,
                    icon: const Icon(Symbols.keyboard_arrow_down, color: AppColors.textMuted, size: 18),
                    isExpanded: true,
                    items: ['Physics', 'Chemistry', 'Mathematics', 'Biology', 'General'].map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedSubject = v),
                  ),
                ),
              ).animate().fadeIn(delay: 120.ms),

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

              const SizedBox(height: 16),

              // Expiration Date & Time
              _Lbl('Expiration Date & Time *'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDateTime,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 52,
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
                    Icon(
                      Symbols.calendar_month,
                      color: _expiresAt != null
                          ? const Color(0xFF5B2FD4)
                          : AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _expiresAt != null
                            ? _formatDateTime(_expiresAt!)
                            : 'Select date & time',
                        style: GoogleFonts.poppins(
                          color: _expiresAt != null
                              ? Colors.white
                              : AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_expiresAt != null)
                      GestureDetector(
                        onTap: () => setState(() => _expiresAt = null),
                        child: const Icon(Icons.close_rounded,
                            color: AppColors.textMuted, size: 18),
                      )
                    else
                      const Icon(Symbols.chevron_right,
                          color: AppColors.textMuted, size: 18),
                  ]),
                ),
              ).animate().fadeIn(delay: 230.ms).slideY(begin: 0.15, end: 0),

              if (_expiresAt != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Symbols.info, color: AppColors.textMuted, size: 13),
                  const SizedBox(width: 6),
                  Text(
                    'Test expires on ${_formatDateTime(_expiresAt!)}',
                    style: GoogleFonts.poppins(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                ]),
              ],

              const SizedBox(height: 16),

              // Allowed Attempts
              _Lbl('Allowed Attempts'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [1, 2].map((val) {
                    final selected = _maxAttempts == val;
                    return GestureDetector(
                      onTap: () => setState(() => _maxAttempts = val),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: selected
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 12)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  val == 1
                                      ? '1 Attempt  —  Single try'
                                      : '2 Attempts  —  Best score counts',
                                  style: GoogleFonts.poppins(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  val == 1
                                      ? 'Student gets one chance only'
                                      : 'Student can retry once, highest score saved',
                                  style: GoogleFonts.poppins(
                                      color: AppColors.textMuted,
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Selected',
                                  style: GoogleFonts.poppins(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.15, end: 0),

              const SizedBox(height: 20),

              // Publish Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  const Icon(Symbols.publish, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Publish Immediately', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('Students will see this test right away', style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 11)),
                    ]),
                  ),
                  Switch(
                    value: _isPublished,
                    onChanged: (v) => setState(() => _isPublished = v),
                    activeColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withOpacity(0.3),
                  ),
                ]),
              ).animate().fadeIn(delay: 280.ms),

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
