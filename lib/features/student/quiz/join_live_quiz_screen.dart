import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
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

class _JoinLiveQuizScreenState extends State<JoinLiveQuizScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final QuizService _svc = QuizService();

  bool _loading = false;
  String? _error;
  LiveSession? _previewSession;
  TestModel? _previewTest;
  bool _showScanner = false;

  // Tab: 0 = PIN, 1 = QR
  int _inputTab = 0;

  // Scanner & permission state
  MobileScannerController? _scannerController;
  bool _cameraPermGranted = false;
  bool _cameraPermDenied = false;
  bool _scanProcessed = false;

  String get _pin =>
      _ctrl.text.replaceAll(RegExp(r'[^0-9]'), '');

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  /// Re-opens the keyboard even if it was previously dismissed.
  void _showKeyboard() {
    if (_focus.hasFocus) {
      SystemChannels.textInput.invokeMethod('TextInput.show');
    } else {
      FocusScope.of(context).requestFocus(_focus);
    }
  }

  void _onChanged(String v) {
    final clean = v.replaceAll(RegExp(r'[^0-9]'), '');
    final pin = clean.length > 6 ? clean.substring(0, 6) : clean;
    if (pin != _ctrl.text) {
      _ctrl.value = TextEditingValue(
        text: pin,
        selection: TextSelection.collapsed(offset: pin.length),
      );
    }
    setState(() {
      _error = null;
      _previewSession = null;
      _previewTest = null;
    });
    if (pin.length == 6) _lookupSession();
  }

  void _handleQrDetected(String data) {
    // Teacher QR format: phoenixguru://join?pin=XXXXXX
    String? pin;
    if (data.contains('pin=')) {
      pin = data.split('pin=').last.trim();
    } else if (RegExp(r'^\d{6}$').hasMatch(data.trim())) {
      pin = data.trim();
    }
    if (pin == null || pin.length != 6) {
      setState(() => _error = 'Invalid QR code');
      return;
    }

    // Switch to PIN tab and auto-fill
    setState(() {
      _inputTab = 0;
      _showScanner = false;
    });
    _ctrl.text = pin;
    _onChanged(pin);
  }

  Future<void> _lookupSession() async {
    final pin = _pin;
    if (pin.length < 6) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    LiveSession? session;
    try {
      session = await _svc.findSessionByPin(pin);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
      return;
    }
    if (!mounted) return;

    if (session == null) {
      setState(() {
        _loading = false;
        _error = 'No active session found for this PIN';
      });
      return;
    }

    if (session.isLocked) {
      setState(() {
        _loading = false;
        _error = 'This session is locked by the host';
      });
      return;
    }

    if (session.isEnded) {
      setState(() {
        _loading = false;
        _error = 'This session has already ended';
      });
      return;
    }

    // Fetch the test
    final appState = context.read<AppState>();
    TestModel? test;
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
          setState(() {
            _loading = false;
            _error = 'Could not load quiz data';
          });
        }
        return;
      }
    }

    if (!mounted) return;

    if (test == null) {
      setState(() {
        _loading = false;
        _error = 'Quiz not found';
      });
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

    setState(() {
      _loading = true;
      _error = null;
    });

    final appState = context.read<AppState>();
    final user = appState.currentUser!;

    LiveSession? session = _previewSession;
    TestModel? test = _previewTest;

    if (session == null) {
      try {
        session = await _svc.findSessionByPin(pin);
      } catch (e) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = e.toString().replaceAll('Exception: ', '');
          });
        }
        return;
      }
      if (!mounted) return;

      if (session == null) {
        setState(() {
          _loading = false;
          _error = 'No active session found for this PIN';
        });
        return;
      }

      if (session.isLocked) {
        setState(() {
          _loading = false;
          _error = 'This session is locked by the host';
        });
        return;
      }

      if (session.isEnded) {
        setState(() {
          _loading = false;
          _error = 'This session has already ended';
        });
        return;
      }

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
            setState(() {
              _loading = false;
              _error = 'Could not load quiz data';
            });
          }
          return;
        }
      }

      if (!mounted) return;
      if (test == null) {
        setState(() {
          _loading = false;
          _error = 'Quiz not found';
        });
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
      setState(() {
        _loading = false;
        _error = err;
      });
      return;
    }

    setState(() => _loading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LiveQuizAbcdScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pin = _pin;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        // Top gradient glow
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 320,
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
                  alignment: Alignment.centerLeft, child: AppBackButton()),
              const SizedBox(height: 32),

              // ── Animated Icon ──────────────────────────────────────────────
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 2),
                ),
                child: const Icon(Symbols.wifi_tethering,
                    color: AppColors.primary, size: 44),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.06, 1.06),
                      duration: 1200.ms,
                      curve: Curves.easeInOut),

              const SizedBox(height: 20),
              Text('Join Live Quiz',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700))
                  .animate()
                  .fadeIn(delay: 200.ms),
              const SizedBox(height: 4),
              Text("Enter the PIN or scan the QR code",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 13))
                  .animate()
                  .fadeIn(delay: 300.ms),

              const SizedBox(height: 28),

              // ── PIN / QR tab switcher ──────────────────────────────────────
              Container(
                height: 44,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  _buildTabBtn(0, 'Enter PIN', Symbols.pin),
                  const SizedBox(width: 4),
                  _buildTabBtn(1, 'Scan QR', Symbols.qr_code_scanner),
                ]),
              ).animate().fadeIn(delay: 320.ms),

              const SizedBox(height: 24),

              // ── Content area ───────────────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _inputTab == 0
                    ? _buildPinInput(pin)
                    : _buildQrScanner(),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Symbols.error,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: GoogleFonts.poppins(
                              color: AppColors.error, fontSize: 12)),
                    ),
                  ]),
                ),
              ],

              const SizedBox(height: 20),

              // ── Session preview card ───────────────────────────────────────
              if (_previewSession != null && _previewTest != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Column(children: [
                    Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Symbols.check_circle,
                            color: AppColors.success, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Session Found!',
                                  style: GoogleFonts.poppins(
                                      color: AppColors.success,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              Text(_previewTest!.title,
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ]),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 12),
                    Row(children: [
                      _miniStat(Symbols.groups,
                          '${_previewSession!.participantCount} joined'),
                      const SizedBox(width: 20),
                      _miniStat(Symbols.help,
                          '${_previewTest!.questionCount} questions'),
                    ]),
                  ]),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 20),

              // ── Join button ────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
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

              // ── How it works ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How to join',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      _howToRow(
                          '1', 'Get the 6-digit PIN from your teacher'),
                      const SizedBox(height: 8),
                      _howToRow(
                          '2', 'Or scan the QR code shown on screen'),
                      const SizedBox(height: 8),
                      _howToRow(
                          '3', 'Wait in the lobby until the quiz starts'),
                    ]),
              ).animate().fadeIn(delay: 550.ms),

              const SizedBox(height: 32),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Tab button ──────────────────────────────────────────────────────────────
  // ── Camera permission + scanner init ──────────────────────────────────────
  Future<void> _requestCameraAndStartScanner() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted) {
      setState(() {
        _cameraPermGranted = true;
        _cameraPermDenied = false;
        _scanProcessed = false;
      });
      _initScanner();
    } else {
      setState(() {
        _cameraPermGranted = false;
        _cameraPermDenied = true;
      });
    }
  }

  void _initScanner() {
    _scannerController?.dispose();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    setState(() => _showScanner = true);
  }

  Widget _buildTabBtn(int index, String label, IconData icon) {
    final active = _inputTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _inputTab = index);
          if (index == 1) {
            _requestCameraAndStartScanner();
          } else {
            // Switching to PIN tab — stop scanner
            _scannerController?.stop();
            setState(() => _showScanner = false);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: double.infinity,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon,
                color: active ? Colors.white : AppColors.textMuted, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    color: active ? Colors.white : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  // ── PIN input (Join Class style boxes with hidden TextField) ────────────────
  Widget _buildPinInput(String pin) {
    return Column(
      key: const ValueKey('pin_input'),
      children: [
        // 6 display boxes
        GestureDetector(
          onTap: _showKeyboard,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              final filled = i < pin.length;
              final active = i == pin.length && pin.length < 6;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 46,
                height: 60,
                decoration: BoxDecoration(
                  color: filled
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: filled
                        ? AppColors.primary
                        : active
                            ? AppColors.primary.withValues(alpha: 0.6)
                            : AppColors.border,
                    width: filled ? 2 : (active ? 2 : 1),
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              spreadRadius: 0),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  filled ? pin[i] : '',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700),
                ),
              );
            }),
          ),
        ),

        // Hidden text field that captures keyboard input
        SizedBox(
          height: 0,
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            autofocus: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style:
                const TextStyle(color: Colors.transparent, fontSize: 1),
            cursorColor: Colors.transparent,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              counterText: '',
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: _onChanged,
          ),
        ),
      ],
    );
  }

  // ── QR Scanner ─────────────────────────────────────────────────────────────
  Widget _buildQrScanner() {
    // Permission denied state
    if (_cameraPermDenied) {
      return Column(
        key: const ValueKey('qr_denied'),
        children: [
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Symbols.no_photography,
                            color: AppColors.error, size: 28),
                      ),
                      const SizedBox(height: 16),
                      Text('Camera Permission Required',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                          'Allow camera access in settings to scan QR codes',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () => openAppSettings(),
                          icon: const Icon(Symbols.settings, size: 18),
                          label: Text('Open Settings',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ]),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey('qr_input'),
      children: [
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3), width: 2),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(children: [
            if (_showScanner && _scannerController != null)
              MobileScanner(
                controller: _scannerController!,
                onDetect: (capture) {
                  if (_scanProcessed) return;
                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final data = barcodes.first.rawValue;
                    if (data != null && data.isNotEmpty) {
                      _scanProcessed = true;
                      _handleQrDetected(data);
                    }
                  }
                },
              )
            else
              Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Starting camera...',
                          style: GoogleFonts.poppins(
                              color: AppColors.textMuted, fontSize: 12)),
                    ]),
              ),

            // Overlay corners for visual polish
            Positioned.fill(
              child: CustomPaint(painter: _ScannerOverlayPainter()),
            ),

            // "Scanning..." label at bottom
            if (_showScanner)
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Point camera at QR code',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        Text('Scan the QR code displayed on your teacher\'s screen',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _miniStat(IconData icon, String text) {
    return Row(children: [
      Icon(icon, color: AppColors.primary, size: 16),
      const SizedBox(width: 6),
      Text(text,
          style: GoogleFonts.poppins(
              color: AppColors.textSecondary, fontSize: 12)),
    ]);
  }

  Widget _howToRow(String num, String text) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(7),
        ),
        alignment: Alignment.center,
        child: Text(num,
            style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text,
            style: GoogleFonts.poppins(
                color: AppColors.textMuted, fontSize: 12)),
      ),
    ]);
  }
}

// ── Scanner overlay with corner brackets ─────────────────────────────────────
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const margin = 40.0;
    const cornerLen = 28.0;
    const left = margin;
    const top = margin;
    final right = size.width - margin;
    final bottom = size.height - margin;

    // Top-left
    canvas.drawLine(Offset(left, top + cornerLen), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLen, top), paint);

    // Top-right
    canvas.drawLine(
        Offset(right - cornerLen, top), Offset(right, top), paint);
    canvas.drawLine(
        Offset(right, top), Offset(right, top + cornerLen), paint);

    // Bottom-left
    canvas.drawLine(
        Offset(left, bottom - cornerLen), Offset(left, bottom), paint);
    canvas.drawLine(
        Offset(left, bottom), Offset(left + cornerLen, bottom), paint);

    // Bottom-right
    canvas.drawLine(
        Offset(right - cornerLen, bottom), Offset(right, bottom), paint);
    canvas.drawLine(
        Offset(right, bottom), Offset(right, bottom - cornerLen), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
