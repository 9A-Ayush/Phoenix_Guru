import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';

// ── Live Quiz ABCD Screen (Screen 11) ────────────────────────────────────────

class LiveQuizAbcdScreen extends StatefulWidget {
  const LiveQuizAbcdScreen({super.key});

  @override
  State<LiveQuizAbcdScreen> createState() => _LiveQuizAbcdScreenState();
}

class _LiveQuizAbcdScreenState extends State<LiveQuizAbcdScreen> with SingleTickerProviderStateMixin {
  int? _selected;
  int _timeLeft = 8;
  late final AnimationController _timerCtrl;

  static const _question = 'Which law states that every action has an equal and opposite reaction?';
  static const _options = [
    ("Newton's First Law", AppColors.quizA),
    ("Newton's Second Law", AppColors.quizB),
    ("Newton's Third Law", AppColors.quizC),
    ("Law of Gravitation", AppColors.quizD),
  ];

  @override
  void initState() {
    super.initState();
    _timerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..forward();
    _startTimer();
  }

  void _startTimer() async {
    while (_timeLeft > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _timeLeft--);
    }
  }

  @override
  void dispose() { _timerCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        // gradient header
        Positioned(
          top: 0, left: 0, right: 0, height: 280,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.bg],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Question 3 of 10',
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                Container(
                  height: 28, padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Symbols.star, color: AppColors.warning, size: 14),
                    const SizedBox(width: 4),
                    Text('240 pts', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            // Timer circle
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.13),
                border: Border.all(color: Colors.white.withOpacity(0.33), width: 3),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$_timeLeft'.padLeft(2, '0'),
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                Text('SEC', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 9)),
              ]),
            ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.elasticOut),

            const SizedBox(height: 8),
            Text('Look at the projector screen!',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500)),

            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: [
                  ..._options.asMap().entries.map((e) {
                    final i = e.key;
                    final label = String.fromCharCode(65 + i);
                    final isSelected = _selected == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: _selected == null ? () => setState(() => _selected = i) : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 80,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: isSelected ? e.value.$2 : e.value.$2.withOpacity(isSelected ? 1 : 0.85),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isSelected ? [BoxShadow(color: e.value.$2.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 6))] : [],
                          ),
                          child: Row(children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                              alignment: Alignment.center,
                              child: Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: Text(e.value.$1,
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
                            if (isSelected) const Icon(Symbols.check_circle, color: Colors.white, size: 22),
                          ]),
                        ),
                      ).animate().fadeIn(delay: (200 + i * 80).ms).slideX(begin: 0.15, end: 0),
                    );
                  }),
                  const SizedBox(height: 12),
                  // Rank card
                  Container(
                    height: 52, padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      const Icon(Symbols.leaderboard, color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Text('Your Rank', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text('#4 of 24', style: GoogleFonts.poppins(color: AppColors.warning, fontSize: 15, fontWeight: FontWeight.w700)),
                    ]),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 8),
                  Text('Tap your answer before time runs out!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 12))
                      .animate().fadeIn(delay: 700.ms),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Quiz Leaderboard Screen (Screen 14) ──────────────────────────────────────

class QuizLeaderboardScreen extends StatelessWidget {
  const QuizLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        Positioned(
          top: 0, left: 0, right: 0, height: 320,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1C1240), AppColors.bg],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              const SizedBox(height: 8),
              Text('Leaderboard',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700))
                  .animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 4),
              Text('Physics Quiz  •  After Q3',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13))
                  .animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 24),
              // Podium
              SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 2nd place
                    _PodiumColumn(rank: 2, initials: 'RK', name: 'Rohan', pts: '480 pts',
                        color: const Color(0xFF1565C0), height: 156, avatarSize: 44, fontSize: 20)
                        .animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
                    const SizedBox(width: 6),
                    // 1st place
                    _PodiumColumn(rank: 1, initials: 'AK', name: 'Ayush', pts: '620 pts',
                        color: AppColors.primary, height: 174, avatarSize: 52, fontSize: 24,
                        crown: true, isYou: false)
                        .animate().fadeIn(delay: 100.ms).slideY(begin: 0.3, end: 0),
                    const SizedBox(width: 6),
                    // 3rd place
                    _PodiumColumn(rank: 3, initials: 'SP', name: 'Sanya', pts: '410 pts',
                        color: const Color(0xFFE65100), height: 140, avatarSize: 40, fontSize: 14)
                        .animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Align(alignment: Alignment.centerLeft,
                child: Text('All Students',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
              const SizedBox(height: 12),

              // Rank rows
              ..._buildRankRows(context),

              const SizedBox(height: 20),
              // Next button
              Container(
                height: 54,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Next Question', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  const Icon(Symbols.arrow_forward, color: Colors.white, size: 20),
                ]),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 8),
              Text('Waiting for teacher to continue...',
                  style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 12))
                  .animate().fadeIn(delay: 700.ms),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ]),
    );
  }

  List<Widget> _buildRankRows(BuildContext context) {
    final data = [
      (4, 'MV', const Color(0xFF22C55E), 'Mohit Verma', '390 pts', false),
      (5, 'AK', AppColors.primary, 'Ayush Kumar', '340 pts', true),
      (6, 'PS', const Color(0xFFFF6B6B), 'Priya Singh', '310 pts', false),
    ];
    return data.asMap().entries.map((e) {
      final d = e.value;
      final isYou = d.$6;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          height: 56, padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isYou ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: isYou ? Border.all(color: AppColors.primary.withOpacity(0.33)) : null,
          ),
          child: Row(children: [
            SizedBox(width: 18,
                child: Text('${d.$1}',
                    style: GoogleFonts.poppins(
                        color: isYou ? AppColors.primary : AppColors.textMuted,
                        fontSize: 15, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center)),
            const SizedBox(width: 10),
            CircleAvatar(radius: 17, backgroundColor: d.$3.withOpacity(0.2),
                child: Text(d.$2, style: GoogleFonts.poppins(color: d.$3, fontSize: 11, fontWeight: FontWeight.w700))),
            const SizedBox(width: 10),
            Expanded(child: Text(d.$4,
                style: GoogleFonts.poppins(
                    color: isYou ? AppColors.primary : Colors.white,
                    fontSize: 14, fontWeight: isYou ? FontWeight.w600 : FontWeight.w500))),
            if (isYou) Container(
              height: 20, width: 34,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
              alignment: Alignment.center,
              child: Text('You', style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Text(d.$5, style: GoogleFonts.poppins(
                color: isYou ? AppColors.primary : AppColors.textSecondary,
                fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ).animate().fadeIn(delay: (400 + e.key * 80).ms),
      );
    }).toList();
  }
}

class _PodiumColumn extends StatelessWidget {
  final int rank;
  final String initials, name, pts;
  final Color color;
  final double height, avatarSize;
  final double fontSize;
  final bool crown, isYou;

  const _PodiumColumn({
    required this.rank, required this.initials, required this.name, required this.pts,
    required this.color, required this.height, required this.avatarSize, required this.fontSize,
    this.crown = false, this.isYou = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        if (crown) Icon(Symbols.workspace_premium, color: AppColors.warning, size: 22),
        CircleAvatar(
          radius: avatarSize / 2,
          backgroundColor: color,
          child: Text(initials,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: avatarSize * 0.3, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 4),
        Text(name, style: GoogleFonts.poppins(color: crown ? AppColors.warning : Colors.white, fontSize: 12, fontWeight: crown ? FontWeight.w700 : FontWeight.w600)),
        Text(pts, style: GoogleFonts.poppins(color: crown ? AppColors.warning : AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          height: height * 0.35,
          decoration: BoxDecoration(
            color: crown
                ? null
                : color,
            gradient: crown ? LinearGradient(colors: [AppColors.primary, AppColors.warning], begin: Alignment.topCenter, end: Alignment.bottomCenter) : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          alignment: Alignment.center,
          child: Text('$rank',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
