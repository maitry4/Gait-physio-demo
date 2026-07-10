import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gait_physiotherapy_demo/core/router/app_router.dart';
import 'package:gait_physiotherapy_demo/features/session/presentation/providers/session_provider.dart';
import 'package:gait_physiotherapy_demo/features/session/presentation/widgets/live_waveform_painter.dart';
import 'package:gait_physiotherapy_demo/features/user_management/domain/entities/user_entity.dart';

class Screen5NewSession extends ConsumerStatefulWidget {
  final UserModel user;

  const Screen5NewSession({super.key, required this.user});

  @override
  ConsumerState<Screen5NewSession> createState() => _Screen5NewSessionState();
}

class _Screen5NewSessionState extends ConsumerState<Screen5NewSession> {


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
      backgroundColor: AppColors.navy,
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
                          color: AppColors.primary,
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
                  color: AppColors.surfaceDark,
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
                                color: AppColors.success,
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
                      painter: LiveWaveformPainter(points: points),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Stop Recording Button ────────────────────────────────────
              GestureDetector(
                onTap: () {
                  context.pushReplacementNamed(
                    AppRoutes.analysisProcessing,
                    extra: {
                      'user': widget.user,
                    },
                  );
                },
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
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
        Icon(icon, color: AppColors.secondary, size: 24),
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
