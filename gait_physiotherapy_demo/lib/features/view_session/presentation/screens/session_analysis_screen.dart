import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/core/router/app_routes.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:gait_physiotherapy_demo/core/widgets/metric_card.dart';
import 'package:gait_physiotherapy_demo/features/view_session/presentation/widgets/static_waveform_painter.dart';

class Screen613SessionAnalysis extends StatefulWidget {
  final Map<String, dynamic> session;
  final Map<String, dynamic> user;

  const Screen613SessionAnalysis({
    super.key,
    required this.session,
    required this.user,
  });

  @override
  State<Screen613SessionAnalysis> createState() => _Screen613SessionAnalysisState();
}

class _Screen613SessionAnalysisState extends State<Screen613SessionAnalysis> {

  bool _isSaving = false;
  bool _saveSuccess = true; // Initially true since it writes during analysis completion

  Color _scoreColor(int score) {
    if (score >= 85) return AppColors.success;
    if (score >= 70) return AppColors.warning;
    return AppColors.primary;
  }

  void _triggerStorageAction() async {
    setState(() {
      _isSaving = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isSaving = false;
      _saveSuccess = true;
    });

    if (!mounted) return;

    if (_saveSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session data synchronized and stored successfully on wearable & local DB!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data commit failed. Retrying sync with wearable memory address...'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.session['score'] as int;
    final scoreColor = _scoreColor(score);
    final slmText = widget.session['slm_interpretation'] as String;
    final stancePhase = (widget.session['stance_phase'] as num?)?.toDouble() ?? 0.0;
    final swingPhase = (widget.session['swing_phase'] as num?)?.toDouble() ?? 0.0;

    List<double> rawWf = [];
    try {
      final dynamic decoded = jsonDecode(widget.session['raw_waveform'] as String);
      if (decoded is List) {
        rawWf = decoded.map((e) => (e as num).toDouble()).toList();
      }
    } catch (_) {
      // Create fallback points if decoding fails
      rawWf = List.generate(40, (index) => math.sin(index * 0.4) * 1.2);
    }

    return Scaffold(
      body: Column(
        children: [
          // ── Dark Header ───────────────────────────────────────────────
          Container(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Clear history back to dashboard
                            context.goNamed(
                              AppRoutes.home,
                              extra: {'deviceName': widget.user['name']},
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.session['id'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  )),
                              const SizedBox(height: 4),
                              Text('${widget.user['name']}  ·  ${widget.session['date']}',
                                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13)),
                            ],
                          ),
                        ),
                        // Score badge
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: scoreColor, width: 3),
                            color: scoreColor.withOpacity(0.12),
                          ),
                          child: Center(
                            child: Text('$score',
                                style: TextStyle(
                                  color: scoreColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                )),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Tags row
                    Wrap(spacing: 8, children: [
                      _Tag(label: widget.session['label'], color: AppColors.secondary),
                      _Tag(
                        label: widget.session['duration'],
                        color: AppColors.warning,
                        icon: Icons.timer_outlined,
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── SLM Summary Box ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.psychology_outlined, color: AppColors.secondary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SLM INTERPRETATION SUMMARY',
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (slmText.isEmpty)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'No summary for this session',
                                      style: TextStyle(
                                        color: AppColors.navy,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.secondary,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        minimumSize: Size.zero,
                                      ),
                                      child: const Text('Generate', style: TextStyle(fontSize: 11, color: Colors.white)),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  slmText,
                                  style: const TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    height: 1.5,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Waveform ───────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Gait Waveform',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            )),
                        const SizedBox(height: 4),
                        Text('Accelerometer points parsed from wearable SD card text logs',
                            style: TextStyle(color: Colors.black.withOpacity(0.35), fontSize: 12)),
                        const SizedBox(height: 20),
                        CustomPaint(
                          size: const Size(double.infinity, 80),
                          painter: StaticWaveformPainter(color: scoreColor, points: rawWf),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Metrics grid ────────────────────────────────────
                  const Text('Session Metrics',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      )),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      MetricCard(
                        label: 'Stride Length',
                        value: '${widget.session['stride_length']} m',
                        icon: Icons.straighten,
                        color: AppColors.secondary,
                      ),
                      MetricCard(
                        label: 'Cadence',
                        value: '${widget.session['cadence']} spm',
                        icon: Icons.speed,
                        color: AppColors.primary,
                      ),
                      MetricCard(
                        label: 'Balance',
                        value: '${widget.session['balance']}% L / ${(100 - (widget.session['balance'] as int))}% R',
                        icon: Icons.balance,
                        color: AppColors.success,
                      ),
                      MetricCard(
                        label: 'Symmetry',
                        value: '${widget.session['symmetry']}%',
                        icon: Icons.compare_arrows,
                        color: AppColors.warning,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Phase Breakdown ─────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Gait Phase Breakdown',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            )),
                        const SizedBox(height: 4),
                        Text('Comparison of Stance vs Swing phase percentages',
                            style: TextStyle(color: Colors.black.withOpacity(0.35), fontSize: 12)),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 150,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.center,
                              barTouchData: BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      if (value == 0) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            widget.session['label'] ?? 'Gait Cycle',
                                            style: const TextStyle(
                                              color: AppColors.navy,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                    reservedSize: 28,
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      return Text(
                                        '${value.toInt()}%',
                                        style: TextStyle(
                                          color: Colors.black.withOpacity(0.4),
                                          fontSize: 10,
                                        ),
                                      );
                                    },
                                    interval: 20,
                                    reservedSize: 38,
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.black.withOpacity(0.06),
                                    strokeWidth: 1,
                                    dashArray: [4, 4],
                                  );
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              maxY: 100,
                              barGroups: [
                                BarChartGroupData(
                                  x: 0,
                                  barRods: [
                                    BarChartRodData(
                                      toY: stancePhase + swingPhase,
                                      width: 45,
                                      borderRadius: BorderRadius.circular(6),
                                      rodStackItems: [
                                        BarChartRodStackItem(0, stancePhase, AppColors.primary),
                                        BarChartRodStackItem(stancePhase, stancePhase + swingPhase, AppColors.secondary),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Stance Phase ${stancePhase.toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy),
                            ),
                            const SizedBox(width: 20),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Swing Phase ${swingPhase.toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Storage Status Options ──────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _saveSuccess ? AppColors.success.withOpacity(0.08) : AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _saveSuccess ? AppColors.success.withOpacity(0.3) : AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _saveSuccess ? Icons.check_circle_outline : Icons.error_outline,
                              color: _saveSuccess ? AppColors.success : AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _saveSuccess ? 'Successfully Stored (Mobile & Band)' : 'Storage Sync Pending',
                              style: TextStyle(
                                color: _saveSuccess ? AppColors.success : AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (!_saveSuccess)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isSaving ? null : _triggerStorageAction,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5),
                                  )
                                : const Text('Retry Analysis Sync', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Tag({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
        ],
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
