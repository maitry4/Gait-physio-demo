import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../providers/session_provider.dart';
import 'screen5_4_analysis_processing.dart';

class Screen5NewSession extends ConsumerStatefulWidget {
  final UserModel user;

  const Screen5NewSession({super.key, required this.user});

  @override
  ConsumerState<Screen5NewSession> createState() => _Screen5NewSessionState();
}

class _Screen5NewSessionState extends ConsumerState<Screen5NewSession> {
  bool _simulateTransferFailure = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final sessionState = ref.read(sessionProvider);
      if (sessionState.isRecording && sessionState.activeRecordingUserId == widget.user.id) {
        // Seamless resumption, do not restart timers
      } else {
        ref.read(sessionProvider.notifier).startRecording(widget.user.id);
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);
    final points = sessionState.liveWaveformPoints;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1D2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // ── Active Patient info ─────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACTIVE RECORDING',
                        style: TextStyle(
                          color: Color(0xFFFF4E6A),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  // Failure Simulator switch
                  Row(
                    children: [
                      const Icon(Icons.bug_report, size: 16, color: Color(0xFFFF4E6A)),
                      const SizedBox(width: 4),
                      const Text(
                        'Simulate Error',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      Checkbox(
                        value: _simulateTransferFailure,
                        activeColor: const Color(0xFFFF4E6A),
                        onChanged: (val) {
                          setState(() {
                            _simulateTransferFailure = val ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(),

              // ── Telemetry Indicators (Timer & Steps) ───────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _TelemetryIndicator(
                    label: 'ELAPSED TIME',
                    value: _formatDuration(sessionState.recordDurationSeconds),
                    icon: Icons.timer_outlined,
                  ),
                  Container(
                    height: 50,
                    width: 1,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  _TelemetryIndicator(
                    label: 'DETECTED STEPS',
                    value: '${sessionState.stepCount}',
                    icon: Icons.directions_walk,
                  ),
                ],
              ),

              const Spacer(),

              // ── Simulated Waveform Graph ────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF252840),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'IMU Stream (Accelerometer)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00C48C),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Streaming (50Hz)',
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    CustomPaint(
                      size: const Size(double.infinity, 120),
                      painter: _LiveWaveformPainter(points: points),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Stop Recording Button ────────────────────────────────────
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Screen54AnalysisProcessing(
                        user: widget.user,
                        simulateFailure: _simulateTransferFailure,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4E6A),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4E6A).withOpacity(0.4),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.stop, color: Colors.white, size: 36),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Stop session and compile data',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TelemetryIndicator extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TelemetryIndicator({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6C63FF), size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 26,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _LiveWaveformPainter extends CustomPainter {
  final List<double> points;

  _LiveWaveformPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFFFF4E6A)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final midY = size.height / 2;
    final spacing = size.width / 30; // Max 30 points

    for (int i = 0; i < points.length; i++) {
      final x = i * spacing;
      // Map wave values (typically -3 to 3) to fits vertical boundaries
      final y = midY - (points[i] * (size.height * 0.2));
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Dynamic gradient area under curve
    final fillPath = Path()
      ..addPath(path, Offset.zero)
      ..lineTo((points.length - 1) * spacing, midY)
      ..lineTo(0, midY)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF4E6A), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}