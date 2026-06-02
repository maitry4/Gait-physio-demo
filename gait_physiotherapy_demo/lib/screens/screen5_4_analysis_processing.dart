import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../models/user_model.dart';
import '../providers/session_provider.dart';
import 'screen6_1_3_session_analysis.dart';
import 'screen4_home_menu.dart';

class Screen54AnalysisProcessing extends ConsumerStatefulWidget {
  final UserModel user;
  final bool simulateFailure;

  const Screen54AnalysisProcessing({
    super.key,
    required this.user,
    required this.simulateFailure,
  });

  @override
  ConsumerState<Screen54AnalysisProcessing> createState() => _Screen54AnalysisProcessingState();
}

class _Screen54AnalysisProcessingState extends ConsumerState<Screen54AnalysisProcessing>
    with TickerProviderStateMixin {
  late AnimationController _rotateCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runAnalysis();
      });
    }
  }

  Future<void> _runAnalysis() async {
    final notifier = ref.read(sessionProvider.notifier);
    await notifier.stopRecordingAndAnalyze(widget.user.id, simulateFailure: widget.simulateFailure);
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);
    final hasError = sessionState.errorMessage != null;
    final isProcessing = sessionState.isSyncingFromDevice;

    if (hasError) {
      return _buildFailureView(sessionState.errorMessage!);
    }

    if (!isProcessing && sessionState.currentSessionAnalysis != null) {
      // Automatic redirection to results once compiled
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Screen613SessionAnalysis(
              session: sessionState.currentSessionAnalysis!.toMap(),
              user: widget.user.toMap(),
            ),
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1D2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Center(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Rotating Rings
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _rotateCtrl,
                          builder: (_, __) => Transform.rotate(
                            angle: _rotateCtrl.value * 2 * math.pi,
                            child: CustomPaint(
                              size: const Size(220, 220),
                              painter: _DashedCirclePainter(
                                color: const Color(0xFFFF4E6A).withOpacity(0.4),
                                strokeWidth: 2,
                                dashCount: 20,
                              ),
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _rotateCtrl,
                          builder: (_, __) => Transform.rotate(
                            angle: -_rotateCtrl.value * 2 * math.pi * 0.6,
                            child: CustomPaint(
                              size: const Size(170, 170),
                              painter: _DashedCirclePainter(
                                color: const Color(0xFF6C63FF).withOpacity(0.35),
                                strokeWidth: 1.5,
                                dashCount: 14,
                              ),
                            ),
                          ),
                        ),
                        ScaleTransition(
                          scale: _pulseAnim,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [Color(0xFFFF4E6A), Color(0xFFD63855)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF4E6A).withOpacity(0.5),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 44),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  const Text(
                    'Compiling Telemetry',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    sessionState.syncStatusMessage.isNotEmpty
                        ? sessionState.syncStatusMessage
                        : 'Contacting wearable storage module...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 14,
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFailureView(String errorMessage) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E101D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4E6A).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.assignment_late_outlined, size: 48, color: Color(0xFFFF4E6A)),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Data Sync Failed',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Verify the wearable is active, and try retrieving records again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(sessionProvider.notifier).clearError();
                  _runAnalysis();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4E6A),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Text(
                      'Retry Telemetry Retrieve',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  ref.read(sessionProvider.notifier).clearError();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Screen4HomeMenu(deviceName: widget.user.name),
                    ),
                    (route) => false,
                  );
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: const Center(
                    child: Text(
                      'Cancel (Go to Dashboard)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int dashCount;

  _DashedCirclePainter({required this.color, required this.strokeWidth, required this.dashCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;
    final dashAngle = (2 * math.pi) / dashCount;
    final gapFraction = 0.4;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
