import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/services/quiz_service.dart';
import 'live_quiz_host_screen.dart';

class LiveSessionLobbyScreen extends StatefulWidget {
  final TestModel test;
  const LiveSessionLobbyScreen({super.key, required this.test});

  @override
  State<LiveSessionLobbyScreen> createState() => _LiveSessionLobbyScreenState();
}

class _LiveSessionLobbyScreenState extends State<LiveSessionLobbyScreen> {
  final QuizService _svc = QuizService();

  LiveSession? _session;
  List<LiveParticipant> _participants = [];
  StreamSubscription? _sessionSub;
  StreamSubscription? _participantsSub;
  bool _starting = false;
  bool _creating = true;

  @override
  void initState() {
    super.initState();
    _createSession();
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _participantsSub?.cancel();
    super.dispose();
  }

  Future<void> _createSession() async {
    final user = context.read<AppState>().currentUser!;
    final session = await _svc.startSession(
      test: widget.test,
      hostId: user.id,
      hostName: user.name,
    );
    if (!mounted) return;
    setState(() { _session = session; _creating = false; });
    _listenSession(session.id);
    _listenParticipants(session.id);
  }

  void _listenSession(String id) {
    _sessionSub = _svc.sessionStream(id).listen((s) {
      if (!mounted) return;
      if (s != null) setState(() => _session = s);
    });
  }

  void _listenParticipants(String id) {
    _participantsSub = _svc.participantsStream(id).listen((list) {
      if (!mounted) return;
      setState(() => _participants = list);
    });
  }

  Future<void> _startQuiz() async {
    if (_session == null || _starting) return;
    setState(() => _starting = true);
    await _svc.nextQuestion(_session!.id, 0);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherLiveQuizScreen(
          test: widget.test,
          session: _session!,
        ),
      ),
    );
  }

  Future<void> _toggleLock() async {
    if (_session == null) return;
    await _svc.toggleLock(_session!.id, locked: !_session!.isLocked);
  }

  Future<void> _endSession() async {
    if (_session == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('End Session',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Cancel this quiz session?',
            style: GoogleFonts.poppins(
                color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('End',
                style: GoogleFonts.poppins(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _svc.endSession(_session!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  void _copyPin() {
    if (_session == null) return;
    Clipboard.setData(ClipboardData(text: _session!.pin));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('PIN copied!',
          style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_creating) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Creating session...',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 14)),
          ]),
        ),
      );
    }

    final session = _session!;
    final count = _participants.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1C1240), AppColors.bg],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _endSession,
                    child: Container(
                      height: 36, width: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  // Live badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ).animate(onPlay: (c) => c.repeat())
                          .fadeOut(duration: 800.ms)
                          .then()
                          .fadeIn(duration: 800.ms),
                      const SizedBox(width: 6),
                      Text('LOBBY',
                          style: GoogleFonts.poppins(
                              color: AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  // Lock button
                  GestureDetector(
                    onTap: _toggleLock,
                    child: Container(
                      height: 36, width: 36,
                      decoration: BoxDecoration(
                        color: session.isLocked
                            ? AppColors.warningLight
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: session.isLocked
                              ? AppColors.warning
                              : AppColors.border,
                        ),
                      ),
                      child: Icon(
                        session.isLocked
                            ? Symbols.lock
                            : Symbols.lock_open,
                        color: session.isLocked
                            ? AppColors.warning
                            : AppColors.textMuted,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(widget.test.title,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),

              const SizedBox(height: 16),

              // PIN display
              GestureDetector(
                onTap: _copyPin,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Column(children: [
                    Text('JOIN PIN',
                        style: GoogleFonts.poppins(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: session.pin.split('').map((d) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 36, height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(d,
                            style: GoogleFonts.poppins(
                                color: AppColors.primary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                      )).toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Symbols.content_copy,
                          color: AppColors.textMuted, size: 13),
                      const SizedBox(width: 4),
                      Text('Tap to copy',
                          style: GoogleFonts.poppins(
                              color: AppColors.textMuted, fontSize: 11)),
                    ]),
                  ]),
                ),
              ).animate().scale(
                  begin: const Offset(0.9, 0.9),
                  duration: 400.ms,
                  curve: Curves.easeOut),
            ]),
          ),

          // ── Participant count ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Symbols.groups,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('$count joined',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ]),
                Text('${widget.test.questionCount} questions',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),

          // ── Participant list ─────────────────────────────────────────────
          Expanded(
            child: _participants.isEmpty
                ? Center(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      const Icon(Symbols.wifi_tethering,
                          color: AppColors.textMuted, size: 48),
                      const SizedBox(height: 12),
                      Text('Waiting for students...',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Share the PIN above',
                          style: GoogleFonts.poppins(
                              color: AppColors.textMuted, fontSize: 13)),
                    ]),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _participants.length,
                    itemBuilder: (_, i) {
                      final p = _participants[i];
                      final colors = [
                        AppColors.primary,
                        AppColors.warning,
                        AppColors.accent,
                        AppColors.success,
                        const Color(0xFF1565C0),
                        const Color(0xFF7C3AED),
                      ];
                      final color = colors[i % colors.length];
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                color.withValues(alpha: 0.2),
                            child: Text(p.avatarInitials,
                                style: GoogleFonts.poppins(
                                    color: color,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.name.split(' ').first,
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ).animate().scale(
                          begin: const Offset(0.5, 0.5),
                          duration: 300.ms,
                          curve: Curves.easeOut);
                    },
                  ),
          ),

          // ── Start button ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (_starting || count == 0) ? null : _startQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  disabledBackgroundColor: AppColors.surface2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _starting
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            count == 0
                                ? Symbols.hourglass_empty
                                : Symbols.play_arrow,
                            color: count == 0
                                ? AppColors.textMuted
                                : Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            count == 0
                                ? 'Waiting for players...'
                                : 'Start Quiz  ($count)',
                            style: GoogleFonts.poppins(
                              color: count == 0
                                  ? AppColors.textMuted
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
