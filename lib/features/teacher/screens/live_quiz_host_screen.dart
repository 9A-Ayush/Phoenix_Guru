import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models.dart';
import '../../../shared/widgets/widgets.dart';

class TeacherLiveQuizScreen extends StatefulWidget {
  final TestModel test;
  
  const TeacherLiveQuizScreen({super.key, required this.test});

  @override
  State<TeacherLiveQuizScreen> createState() => _TeacherLiveQuizScreenState();
}

class _TeacherLiveQuizScreenState extends State<TeacherLiveQuizScreen> {
  bool _revealed = false;
  int _questionIndex = 0; // Starts at first question


  @override
  Widget build(BuildContext context) {
    if (widget.test.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Quiz')),
        body: const Center(child: Text('This test has no questions.')),
      );
    }
    
    final currentQuestion = widget.test.questions[_questionIndex];
    final correctIndex = currentQuestion.correctIndex;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            color: AppColors.surface,
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 34, width: 34,
                  decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Symbols.close, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.test.title + ' — Live', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                Text('Question ${_questionIndex + 1} of ${widget.test.questions.length}', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
              ])),
              // Live badge
              Container(
                height: 28, padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(9)),
                child: Row(children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('LIVE', style: GoogleFonts.poppins(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('attempts')
                  .where('testId', isEqualTo: widget.test.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final attempts = snapshot.data!.docs
                    .map((d) => QuizAttempt.fromMap(d.data() as Map<String, dynamic>))
                    .toList();
                
                // Calculate counts for the current question
                final List<int> counts = List.filled(currentQuestion.options.length, 0);
                int totalAnswers = 0;
                
                final List<Map<String, dynamic>> studentResponses = [];
                
                for (var attempt in attempts) {
                  if (attempt.answers.containsKey(currentQuestion.id)) {
                    final selectedIdx = attempt.answers[currentQuestion.id]!;
                    if (selectedIdx >= 0 && selectedIdx < counts.length) {
                      counts[selectedIdx]++;
                      totalAnswers++;
                      
                      // Find student info (in a real app, you might fetch student details, but we'll use placeholder or studentId)
                      studentResponses.add({
                        'studentId': attempt.userId,
                        'name': attempt.userName,
                        'selectedIndex': selectedIdx,
                      });
                    }
                  }
                }
                
                return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                // Progress bar
                Row(children: List.generate(widget.test.questions.length, (i) => Expanded(
                  child: Container(
                    height: 5, margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i <= _questionIndex ? AppColors.primary : AppColors.surface2,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ))),
                const SizedBox(height: 16),

                // Question card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        height: 24, padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                        child: Text('Q${_questionIndex + 1}', style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      const Spacer(),
                      const Icon(Symbols.timer, color: AppColors.textMuted, size: 16),
                      const SizedBox(width: 4),
                      Text('${widget.test.durationMinutes}m', style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 12)),
                    ]),
                    const SizedBox(height: 10),
                    Text(currentQuestion.question, style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                  ]),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 16),

                const SizedBox(height: 16),

                // Answer distribution bars
                Text('Answer Distribution', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                ...List.generate(currentQuestion.options.length, (i) {
                  final label = String.fromCharCode(65 + i);
                  final count = counts[i];
                  final frac = totalAnswers == 0 ? 0.0 : count / totalAnswers;
                  final isCorrect = i == correctIndex;
                  final barColor = _revealed
                      ? (isCorrect ? AppColors.success : AppColors.error.withOpacity(0.6))
                      : _barColor(i);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(color: barColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          alignment: Alignment.center,
                          child: Text(label, style: GoogleFonts.poppins(color: barColor, fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Stack(children: [
                          Container(height: 28, decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(8))),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            height: 28,
                            width: MediaQuery.of(context).size.width * 0.55 * frac,
                            decoration: BoxDecoration(color: barColor.withOpacity(0.75), borderRadius: BorderRadius.circular(8)),
                          ),
                        ])),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 28,
                          child: Text('$count', style: GoogleFonts.poppins(
                              color: _revealed && isCorrect ? AppColors.success : Colors.white,
                              fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                        if (_revealed && isCorrect) const Icon(Symbols.check_circle, color: AppColors.success, size: 18),
                      ]),
                    ]),
                  ).animate().fadeIn(delay: (i * 80).ms);
                }),

                const SizedBox(height: 16),

                // Stats row
                Row(children: [
                  _statChip(Symbols.check, '${counts.isEmpty ? 0 : counts[correctIndex]}', 'Correct', AppColors.success),
                  const SizedBox(width: 8),
                  _statChip(Symbols.close, '${totalAnswers - (counts.isEmpty ? 0 : counts[correctIndex])}', 'Wrong', AppColors.error),
                  const SizedBox(width: 8),
                  _statChip(Symbols.person, '$totalAnswers', 'Answered', AppColors.primary),
                ]).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 20),

                // Student response list
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Student Responses', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  Text('$totalAnswers', style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 12)),
                ]),
                const SizedBox(height: 10),
                _StudentResponseList(revealed: _revealed, correctIndex: correctIndex, responses: studentResponses),

                const SizedBox(height: 20),

                // Action buttons
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _revealed = !_revealed),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: _revealed ? AppColors.surface2 : AppColors.success,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(_revealed ? Symbols.visibility_off : Symbols.visibility, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(_revealed ? 'Hide Answer' : 'Reveal Answer',
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_questionIndex < widget.test.questions.length - 1) {
                          setState(() {
                            _questionIndex++;
                            _revealed = false;
                          });
                        } else {
                          // End of test
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(_questionIndex < widget.test.questions.length - 1 ? 'Next' : 'Finish', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Icon(_questionIndex < widget.test.questions.length - 1 ? Symbols.arrow_forward : Symbols.check, color: Colors.white, size: 18),
                        ]),
                      ),
                    ),
                  ),
                ]).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 20),
              ]),
            );
          },
        ),
          ),
        ]),
      ),
    );
  }

  Color _barColor(int i) {
    const colors = [AppColors.quizA, AppColors.quizB, AppColors.quizC, AppColors.quizD];
    return colors[i];
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        height: 52,
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(value, style: GoogleFonts.poppins(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
          ]),
          Text(label, style: GoogleFonts.poppins(color: color.withOpacity(0.8), fontSize: 10)),
        ]),
      ),
    );
  }
}

class _StudentResponseList extends StatelessWidget {
  final bool revealed;
  final int correctIndex;
  final List<Map<String, dynamic>> responses;

  const _StudentResponseList({required this.revealed, required this.correctIndex, required this.responses});

  Color _studentColor(int index) {
    const colors = [AppColors.primary, AppColors.warning, AppColors.accent, AppColors.success, Color(0xFF1565C0)];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (responses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No responses yet.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    
    return Column(
      children: responses.asMap().entries.map((e) {
        final s = e.value;
        final selectedIdx = s['selectedIndex'] as int;
        final ans = String.fromCharCode(65 + selectedIdx);
        final isCorrect = selectedIdx == correctIndex;
        final name = s['name'] as String? ?? 'Student';
        final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
        final color = _studentColor(e.key);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 50, padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              CircleAvatar(radius: 15, backgroundColor: color.withOpacity(0.2),
                  child: Text(initials, style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: FontWeight.w700))),
              const SizedBox(width: 10),
              Expanded(child: Text(name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
              Container(
                height: 26, width: 34,
                decoration: BoxDecoration(
                  color: revealed
                      ? (isCorrect ? AppColors.successLight : AppColors.errorLight)
                      : AppColors.surface2,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(ans, style: GoogleFonts.poppins(
                    color: revealed ? (isCorrect ? AppColors.success : AppColors.error) : AppColors.textSecondary,
                    fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ]),
          ).animate().fadeIn(delay: (e.key * 50).ms),
        );
      }).toList(),
    );
  }
}
