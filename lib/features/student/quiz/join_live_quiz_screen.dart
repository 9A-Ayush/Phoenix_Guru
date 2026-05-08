import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import 'live_quiz_screens.dart';

class JoinLiveQuizScreen extends StatefulWidget {
  const JoinLiveQuizScreen({super.key});

  @override
  State<JoinLiveQuizScreen> createState() => _JoinLiveQuizScreenState();
}

class _JoinLiveQuizScreenState extends State<JoinLiveQuizScreen> {
  final _pinCtrls = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String? _error;

  String get _pin => _pinCtrls.map((c) => c.text).join();

  void _onDigitChanged(int i, String v) {
    if (v.isNotEmpty && i < 5) _focusNodes[i + 1].requestFocus();
    if (v.isEmpty && i > 0) _focusNodes[i - 1].requestFocus();
    setState(() {});
  }

  Future<void> _join() async {
    if (_pin.length < 6) {
      setState(() => _error = 'Enter the full 6-digit PIN');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LiveQuizAbcdScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        // Top gradient glow
        Positioned(
          top: 0, left: 0, right: 0, height: 300,
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
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(children: [
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: const AppBackButton()),
              const SizedBox(height: 40),

              // Animated icon
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 2),
                ),
                child: const Icon(Symbols.wifi_tethering, color: AppColors.primary, size: 48),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.07, 1.07), duration: 1200.ms, curve: Curves.easeInOut),

              const SizedBox(height: 24),
              Text('Join Live Quiz',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700))
                  .animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 6),
              Text('Enter the PIN shown on your teacher\'s screen',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14))
                  .animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 36),

              // PIN boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 46, height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _pinCtrls[i].text.isNotEmpty ? AppColors.primary : AppColors.border,
                      width: _pinCtrls[i].text.isNotEmpty ? 2 : 1,
                    ),
                  ),
                  child: TextField(
                    controller: _pinCtrls[i],
                    focusNode: _focusNodes[i],
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) => _onDigitChanged(i, v),
                  ),
                )),
              ).animate().fadeIn(delay: 350.ms),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: GoogleFonts.poppins(color: AppColors.error, fontSize: 13),
                    textAlign: TextAlign.center),
              ],

              const SizedBox(height: 28),

              // Join button
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _join,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Symbols.play_arrow, color: Colors.white, size: 22),
                          const SizedBox(width: 8),
                          Text('Join Now', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        ]),
                ),
              ).animate().fadeIn(delay: 450.ms).scale(begin: const Offset(0.95, 0.95)),

              const SizedBox(height: 24),

              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(children: [
                  _infoRow(Symbols.schedule, 'Live for 45 mins'),
                  const Divider(color: AppColors.border, height: 16),
                  _infoRow(Symbols.groups, '18 students already joined'),
                  const Divider(color: AppColors.border, height: 16),
                  _infoRow(Symbols.quiz, '10 questions'),
                ]),
              ).animate().fadeIn(delay: 550.ms),

              const SizedBox(height: 32),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, color: AppColors.primary, size: 18),
      const SizedBox(width: 10),
      Text(text, style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
    ]);
  }
}
