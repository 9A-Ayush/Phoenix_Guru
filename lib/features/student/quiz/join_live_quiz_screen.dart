import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/services/quiz_service.dart';
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
  final QuizService _svc = QuizService();

  bool _loading = false;
  String? _error;
  LiveSession? _previewSession;
  TestModel? _previewTest;

  String get _pin => _pinCtrls.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _pinCtrls) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int i, String v) {
    if (v.isNotEmpty && i < 5) _focusNodes[i + 1].requestFocus();
    if (v.isEmpty && i > 0) _focusNodes[i - 1].requestFocus();
    setState(() {
      _error = null;
      _previewSession = null;
      _previewTest = null;
    });
    // Auto-lookup when all 6 digits entered
    if (_pin.length == 6) _lookupSession();
  }

  Future<void> _lookupSession() async {
    final pin = _pin;
    if (pin.length < 6) return;
    setState(() { _loading = true; _error = null; });

    LiveSession? session;
    try {
      session = await _svc.findSessionByPin(pin);
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _error = e.toString().replaceAll('Exception: ', ''); });
      }
      return;
    }
    if (!mounted) return;

    if (session == null) {
      setState(() { _loading = false; _error = 'No active session found for this PIN'; });
      return;
    }

    if (session.isLocked) {
      setState(() { _loading = false; _error = 'This session is locked by the host'; });
      return;
    }

    if (session.isEnded) {
      setState(() { _loading = false; _error = 'This session has already ended'; });
      return;
    }

    // Fetch the test
    final appState = context.read<AppState>();
    TestModel? test;
    try {
      test = appState.allTests.firstWhere((t) => t.id == session!.testId);
    } catch (_) {
      // Not in local cache — fetch from Firestore directly
      try {
        final doc = await FirebaseFirestore.instance
            .collection('tests')
            .doc(session.testId)
            .get();
        if (doc.exists && doc.data() != null) {
          test = TestModel.fromMap(doc.data()!);
        }
      } catch (e) {
        if (mounted) {
          setState(() { _loading = false; _error = 'Could not load quiz data'; });
        }
        return;
      }
    }

    if (!mounted) return;

    if (test == null) {
      setState(() { _loading = false; _error = 'Quiz not found'; });
      return;
    }

    setState(() {
      _loading = false;
      _previewSession = session;
      _previewTest = test;
    });
  }

  Future<void> _join() async {
    final pin = _pin;
    if (pin.length < 6) {
      setState(() => _error = 'Enter the full 6-digit PIN');
      return;
    }

    setState(() { _loading = true; _error = null; });

    // Capture context-dependent values before async gap
    final appState = context.read<AppState>();
    final user = appState.currentUser!;

    LiveSession? session = _previewSession;
    TestModel? test = _previewTest;

    // If no preview yet, look up now
    if (session == null) {
      try {
        session = await _svc.findSessionByPin(pin);
      } catch (e) {
        if (mounted) {
          setState(() { _loading = false; _error = e.toString().replaceAll('Exception: ', ''); });
        }
        return;
      }
      if (!mounted) return;

      if (session == null) {
        setState(() { _loading = false; _error = 'No active session found for this PIN'; });
        return;
      }

      if (session.isLocked) {
        setState(() { _loading = false; _error = 'This session is locked by the host'; });
        return;
      }

      if (session.isEnded) {
        setState(() { _loading = false; _error = 'This session has already ended'; });
        return;
      }

      // Fetch test
      try {
        test = appState.allTests.firstWhere((t) => t.id == session!.testId);
      } catch (_) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('tests')
              .doc(session.testId)
              .get();
          if (doc.exists && doc.data() != null) {
            test = TestModel.fromMap(doc.data()!);
          }
        } catch (e) {
          if (mounted) {
            setState(() { _loading = false; _error = 'Could not load quiz data'; });
          }
          return;
        }
      }

      if (!mounted) return;
      if (test == null) {
        setState(() { _loading = false; _error = 'Quiz not found'; });
        return;
      }
    }

    // Join the session
    final err = await _svc.joinSession(
      sessionId: session.id,
      userId: user.id,
      name: user.name,
      avatarInitials: user.avatarInitials,
    );

    if (!mounted) return;

    if (err != null && err != 'already joined') {
      setState(() { _loading = false; _error = err; });
      return;
    }

    setState(() => _loading = false);

    // Navigate to the live quiz screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LiveQuizAbcdScreen(),
      ),
    );
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
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(children: [
              const SizedBox(height: 12),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: AppBackButton()),
              const SizedBox(height: 40),

              // Animated icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.4), width: 2),
                ),
                child: const Icon(Symbols.wifi_tethering,
                    color: AppColors.primary, size: 48),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.07, 1.07),
                      duration: 1200.ms,
                      curve: Curves.easeInOut),

              const SizedBox(height: 24),
              Text('Join Live Quiz',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700))
                  .animate()
                  .fadeIn(delay: 200.ms),
              const SizedBox(height: 6),
              Text("Enter the PIN shown on your teacher's screen",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 14))
                  .animate()
                  .fadeIn(delay: 300.ms),

              const SizedBox(height: 36),

              // PIN boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  6,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 46,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _pinCtrls[i].text.isNotEmpty
                            ? AppColors.primary
                            : AppColors.border,
                        width: _pinCtrls[i].text.isNotEmpty ? 2 : 1,
                      ),
                    ),
                    child: TextField(
                      controller: _pinCtrls[i],
                      focusNode: _focusNodes[i],
                      maxLength: 1,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (v) => _onDigitChanged(i, v),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 350.ms),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: GoogleFonts.poppins(
                        color: AppColors.error, fontSize: 13),
                    textAlign: TextAlign.center),
              ],

              const SizedBox(height: 28),

              // Join button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _join,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Symbols.play_arrow,
                                color: Colors.white, size: 22),
                            const SizedBox(width: 8),
                            Text('Join Now',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                ),
              ).animate().fadeIn(delay: 450.ms).scale(
                  begin: const Offset(0.95, 0.95)),

              const SizedBox(height: 24),

              // Info card — shows real session data if found, else placeholder
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: _previewSession != null && _previewTest != null
                    ? Column(children: [
                        _infoRow(Symbols.quiz, _previewTest!.title),
                        const Divider(color: AppColors.border, height: 16),
                        _infoRow(Symbols.groups,
                            '${_previewSession!.participantCount} students joined'),
                        const Divider(color: AppColors.border, height: 16),
                        _infoRow(Symbols.help,
                            '${_previewTest!.questionCount} questions'),
                      ])
                    : Column(children: [
                        _infoRow(Symbols.schedule, 'Enter PIN to see quiz info'),
                        const Divider(color: AppColors.border, height: 16),
                        _infoRow(Symbols.groups, 'Waiting for PIN...'),
                        const Divider(color: AppColors.border, height: 16),
                        _infoRow(Symbols.quiz, 'Live quiz session'),
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
      Expanded(
        child: Text(text,
            style: GoogleFonts.poppins(
                color: AppColors.textSecondary, fontSize: 13)),
      ),
    ]);
  }
}
