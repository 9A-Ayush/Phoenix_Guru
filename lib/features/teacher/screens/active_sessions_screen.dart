import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models.dart';
import '../../../core/services/quiz_service.dart';
import 'live_session_lobby_screen.dart';

class ActiveSessionsScreen extends StatefulWidget {
  final String hostId;
  final List<TestModel> tests;

  const ActiveSessionsScreen({
    super.key,
    required this.hostId,
    required this.tests,
  });

  @override
  State<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends State<ActiveSessionsScreen> {
  final QuizService _svc = QuizService();
  final Set<String> _selected = {};
  bool _selectionMode = false;
  bool _closing = false;

  String _statusLabel(LiveSessionStatus s) {
    switch (s) {
      case LiveSessionStatus.waiting:       return 'Waiting';
      case LiveSessionStatus.active:        return 'Live';
      case LiveSessionStatus.showingResult: return 'Showing Result';
      case LiveSessionStatus.ended:         return 'Ended';
    }
  }

  Color _statusColor(LiveSessionStatus s) {
    switch (s) {
      case LiveSessionStatus.active:        return AppColors.error;
      case LiveSessionStatus.showingResult: return AppColors.warning;
      default:                              return AppColors.success;
    }
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
        if (_selected.isEmpty) _selectionMode = false;
      } else {
        _selected.add(id);
      }
    });
  }

  void _enterSelectionMode(String id) {
    setState(() {
      _selectionMode = true;
      _selected.add(id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selected.clear();
    });
  }

  Future<void> _closeSessions(List<String> ids) async {
    if (_closing) return;
    setState(() => _closing = true);
    for (final id in ids) {
      await _svc.endSession(id);
    }
    if (!mounted) return;
    setState(() { _closing = false; _selected.clear(); _selectionMode = false; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        '${ids.length} session${ids.length > 1 ? 's' : ''} closed',
        style: GoogleFonts.poppins(color: Colors.white),
      ),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSingleCloseMenu(BuildContext ctx, LiveSession session) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      useRootNavigator: false,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Session info
          Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Symbols.live_tv,
                  color: AppColors.success, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.testTitle,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('PIN: ${session.pin}  •  ${session.participantCount} joined',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            )),
          ]),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          // Close option
          GestureDetector(
            onTap: () {
              Navigator.pop(ctx);
              _closeSessions([session.id]);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Symbols.stop_circle,
                      color: AppColors.error, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Close Session',
                        style: GoogleFonts.poppins(
                            color: AppColors.error,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text('End this live session permanently',
                        style: GoogleFonts.poppins(
                            color: AppColors.error.withValues(alpha: 0.7),
                            fontSize: 12)),
                  ],
                )),
                Icon(Symbols.chevron_right,
                    color: AppColors.error.withValues(alpha: 0.5), size: 18),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('live_sessions')
        .where('hostId', isEqualTo: widget.hostId)
        .where('status', whereIn: [
          LiveSessionStatus.waiting.name,
          LiveSessionStatus.active.name,
          LiveSessionStatus.showingResult.name,
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => LiveSession.fromMap(d.data()))
            .toList());

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: StreamBuilder<List<LiveSession>>(
          stream: stream,
          builder: (context, snapshot) {
            final sessions = snapshot.data ?? [];

            return Column(children: [
              // ── Header ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                color: AppColors.surface,
                child: Row(children: [
                  GestureDetector(
                    onTap: _selectionMode
                        ? _exitSelectionMode
                        : () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _selectionMode
                            ? Icons.close_rounded
                            : Icons.chevron_left_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectionMode
                              ? '${_selected.length} selected'
                              : 'Active Sessions',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${sessions.length} session${sessions.length == 1 ? '' : 's'} running',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Select all button in selection mode
                  if (_selectionMode)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selected.length == sessions.length) {
                            _selected.clear();
                          } else {
                            _selected.addAll(sessions.map((s) => s.id));
                          }
                        });
                      },
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _selected.length == sessions.length
                              ? 'Deselect All'
                              : 'Select All',
                          style: GoogleFonts.poppins(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ]),
              ),

              // ── Session list ─────────────────────────────────────────
              Expanded(
                child: sessions.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                          const Icon(Symbols.live_tv,
                              color: AppColors.textMuted, size: 52),
                          const SizedBox(height: 12),
                          Text('No active sessions',
                              style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Start a quiz to see sessions here',
                              style: GoogleFonts.poppins(
                                  color: AppColors.textMuted, fontSize: 13)),
                        ]),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: sessions.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final s = sessions[i];
                          final isSelected = _selected.contains(s.id);
                          final test = widget.tests
                              .where((t) => t.id == s.testId)
                              .firstOrNull;
                          final statusColor = _statusColor(s.status);

                          return GestureDetector(
                            onTap: () {
                              if (_selectionMode) {
                                _toggleSelect(s.id);
                              } else if (test != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LiveSessionLobbyScreen(
                                      test: test,
                                      existingSession: s,
                                    ),
                                  ),
                                );
                              }
                            },
                            onLongPress: () {
                              if (!_selectionMode) {
                                _showSingleCloseMenu(context, s);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.08)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(children: [
                                // Checkbox in selection mode
                                if (_selectionMode) ...[
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 22, height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textMuted,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check_rounded,
                                            color: Colors.white, size: 14)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                // Icon
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Symbols.live_tv,
                                      color: statusColor, size: 22),
                                ),
                                const SizedBox(width: 14),
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(s.testTitle,
                                          style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 3),
                                      Row(children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: statusColor
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _statusLabel(s.status),
                                            style: GoogleFonts.poppins(
                                                color: statusColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'PIN: ${s.pin}  •  ${s.participantCount} joined',
                                          style: GoogleFonts.poppins(
                                              color: AppColors.textSecondary,
                                              fontSize: 11),
                                        ),
                                      ]),
                                    ],
                                  ),
                                ),
                                if (!_selectionMode)
                                  const Icon(Symbols.chevron_right,
                                      color: AppColors.textMuted, size: 18),
                              ]),
                            ).animate().fadeIn(delay: (i * 50).ms),
                          );
                        },
                      ),
              ),

              // ── Close selected button ────────────────────────────────
              if (_selectionMode && _selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _closing
                          ? null
                          : () => _closeSessions(_selected.toList()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _closing
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Symbols.stop_circle,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Close ${_selected.length} Session${_selected.length > 1 ? 's' : ''}',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }
}
