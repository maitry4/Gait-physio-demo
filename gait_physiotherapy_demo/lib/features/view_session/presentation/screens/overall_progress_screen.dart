import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gait_physiotherapy_demo/features/session/domain/entities/session_entity.dart';
import 'package:gait_physiotherapy_demo/features/user_management/domain/entities/user_entity.dart';
import 'package:gait_physiotherapy_demo/features/view_session/presentation/providers/view_session_provider.dart';

class Screen612OverallProgress extends ConsumerWidget {
  final UserModel user;
  final List<SessionModel> sessions;

  const Screen612OverallProgress({
    super.key,
    required this.user,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(overallInsightsProvider(user.id));
    final summaryState = ref.watch(patientSummaryProvider(user.id));

    ref.listen<PatientSummaryState>(patientSummaryProvider(user.id), (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.primary,
          ),
        );
        ref.read(patientSummaryProvider(user.id).notifier).clearError();
      }
    });

    return Scaffold(
      body: Column(
        children: [
          // ── Dark Header ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Aggregate Analysis',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${user.name}\'s Progress',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: insightsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Failed to load clinical insights: $err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              data: (insights) {
                final int totalSessions = insights['total_sessions'] as int? ?? 0;
                final double avgCadence = insights['avg_cadence'] as double? ?? 0.0;
                final double avgGaitSpeed = insights['avg_gait_speed'] as double? ?? 0.0;
                final double avgStepTime = insights['avg_step_time'] as double? ?? 0.0;
                final double avgStrideLength = insights['avg_stride_length'] as double? ?? 0.0;
                final double avgStancePct = insights['avg_stance_pct'] as double? ?? 0.0;
                final double avgSwingPct = insights['avg_swing_pct'] as double? ?? 0.0;
                final double avgScore = insights['avg_score'] as double? ?? 0.0;
                final double symmetry = insights['symmetry'] as double? ?? 100.0;

                // ── AI Clinical Progression Analysis Card ──────────────────────────────
                Widget buildAiSummaryCard() {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'AI Clinical Progression Analysis',
                                  style: TextStyle(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            if (summaryState.summary != null && !summaryState.isLoading)
                              IconButton(
                                icon: const Icon(Icons.refresh, color: AppColors.primary, size: 18),
                                onPressed: () => ref
                                    .read(patientSummaryProvider(user.id).notifier)
                                    .generateSummary(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (summaryState.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          )
                        else if (summaryState.summary == null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'No AI progression summary has been generated for this patient yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.4),
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.auto_awesome, size: 18),
                                  label: const Text('Generate AI Progression Summary'),
                                  onPressed: () => ref
                                      .read(patientSummaryProvider(user.id).notifier)
                                      .generateSummary(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            summaryState.summary!,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 13,
                              height: 1.55,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildAiSummaryCard(),
                      const SizedBox(height: 24),

                      // ── Metrics Grid (Central Tendency) ─────────────────────
                      const Text(
                        'Central Tendency Statistics',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GridView.count(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.28,
                        children: [
                          _StatCard(
                            label: 'Mean Symmetry',
                            value: '${symmetry.toStringAsFixed(1)}%',
                            icon: Icons.compare_arrows,
                            color: AppColors.primary,
                          ),
                          _StatCard(
                            label: 'Mean Cadence',
                            value: '${avgCadence.toStringAsFixed(0)} spm',
                            icon: Icons.speed,
                            color: AppColors.secondary,
                          ),
                          _StatCard(
                            label: 'Mean Stride Len',
                            value: '${avgStrideLength.toStringAsFixed(2)} m',
                            icon: Icons.straighten,
                            color: AppColors.success,
                          ),
                          _StatCard(
                            label: 'Mean Gait Speed',
                            value: '${avgGaitSpeed.toStringAsFixed(2)} m/s',
                            icon: Icons.directions_walk,
                            color: Colors.teal,
                          ),
                          _StatCard(
                            label: 'Mean Step Time',
                            value: '${avgStepTime.toStringAsFixed(2)} s',
                            icon: Icons.timer,
                            color: Colors.orange,
                          ),
                          _StatCard(
                            label: 'Mean Score',
                            value: avgScore.toStringAsFixed(1),
                            icon: Icons.score_outlined,
                            color: AppColors.warning,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Stance / Swing Phase Distribution Card ──────────────
                      const Text(
                        'Gait Cycle Phase Distribution',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cycle Breakdown (Averaged)',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.navy),
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                height: 16,
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: (avgStancePct * 100).round().clamp(1, 9900),
                                      child: Container(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Expanded(
                                      flex: (avgSwingPct * 100).round().clamp(1, 9900),
                                      child: Container(
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Stance (${avgStancePct.toStringAsFixed(1)}%)',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navy),
                                ),
                                const SizedBox(width: 20),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Swing (${avgSwingPct.toStringAsFixed(1)}%)',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navy),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Dynamic Trend Visualizer ────────────────────────────
                      const Text(
                        'Historical Progress Line',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Symmetry Trend % (Sessions order)',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.navy),
                                ),
                                Text(
                                  '${sessions.length} sessions logged',
                                  style: TextStyle(color: Colors.black.withOpacity(0.35), fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            CustomPaint(
                              size: const Size(double.infinity, 100),
                              painter: _HistoryTrendPainter(sessions: sessions),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.black.withOpacity(0.38), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTrendPainter extends CustomPainter {
  final List<SessionModel> sessions;

  _HistoryTrendPainter({required this.sessions});

  @override
  void paint(Canvas canvas, Size size) {
    if (sessions.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill;

    final pointPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final path = Path();
    final pointSpacing = sessions.length > 1 ? size.width / (sessions.length - 1) : size.width;

    // Map symmetry range 40% - 100% to fit canvas vertical dimensions
    double getY(int symmetry) {
      final percentage = (symmetry - 40) / 60.0;
      final clamped = percentage.clamp(0.0, 1.0);
      return size.height - (clamped * size.height);
    }

    for (int i = 0; i < sessions.length; i++) {
      final x = i * pointSpacing;
      final y = getY(sessions[i].symmetry);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw connecting lines if more than 1 session
    if (sessions.length > 1) {
      canvas.drawPath(path, paint);

      // Create faded area
      final fillPath = Path()
        ..addPath(path, Offset.zero)
        ..lineTo((sessions.length - 1) * pointSpacing, size.height)
        ..lineTo(0, size.height)
        ..close();

      fillPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.secondary.withOpacity(0.18), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw session dots
    for (int i = 0; i < sessions.length; i++) {
      final x = i * pointSpacing;
      final y = getY(sessions[i].symmetry);
      canvas.drawCircle(Offset(x, y), 5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
