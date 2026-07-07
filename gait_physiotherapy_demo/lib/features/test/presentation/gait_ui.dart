// gait_ui.dart
// Flutter screen that reads the hardcoded TXT file, runs gait analysis,
// and displays the metrics – including a SPARC gauge and stance/swing bar
// that mirror the Python matplotlib plots.

import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/features/test/data/csv_loader.dart';
import 'package:gait_physiotherapy_demo/features/test/data/gait_analysis.dart';
import 'dart:math' as math;

// ---------------------------------------------------------------------------
// Hardcoded file path – change this to match your device / asset location.
// ---------------------------------------------------------------------------
const String kGaitFilePath =
    'assets/final1.txt';
// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------
class GaitScreen extends StatefulWidget {
  const GaitScreen({super.key});

  @override
  State<GaitScreen> createState() => _GaitScreenState();
}

class _GaitScreenState extends State<GaitScreen> {
  GaitMetrics? _metrics;
  bool _loading = false;
  String? _error;
  String? _statusLine; // sampling rate / duration info

  Future<void> _runAnalysis() async {
    setState(() {
      _loading = true;
      _error = null;
      _metrics = null;
      _statusLine = null;
    });

    try {
      final dataset = await CsvLoader.load(kGaitFilePath);
      final analyzer = const GaitAnalyzer(height: 1.75);
      final metrics = analyzer.analyze(dataset);

      setState(() {
        _metrics = metrics;
        _statusLine =
            'Sampling Rate: ${dataset.samplingRate.toStringAsFixed(2)} Hz  |  '
            'Duration: ${dataset.durationSeconds.toStringAsFixed(2)} s';
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A6B8A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Clinical Gait Analyser',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── File path card ──────────────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Data Source',
                      style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 1.1)),
                  const SizedBox(height: 6),
                  Text(
                    kGaitFilePath,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Color(0xFF444444)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Analyse button ──────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _loading ? null : _runAnalysis,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.directions_walk_rounded),
              label: Text(_loading ? 'Analysing…' : 'Analyse Gait'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A6B8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            // ── Error ───────────────────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 16),
              _Card(
                color: const Color(0xFFFFEBEE),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!+"here",
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Status line ─────────────────────────────────────────────────
            if (_statusLine != null) ...[
              const SizedBox(height: 16),
              _Card(
                color: const Color(0xFFE8F5E9),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Colors.green),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _statusLine!,
                        style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Results ─────────────────────────────────────────────────────
            if (_metrics != null) ...[
              const SizedBox(height: 20),
              _SectionLabel('Summary'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricTile(
                    icon: Icons.directions_walk,
                    label: 'Steps',
                    value: '${_metrics!.stepCount}',
                  ),
                  _MetricTile(
                    icon: Icons.speed,
                    label: 'Cadence',
                    value:
                        '${_metrics!.avgCadence.toStringAsFixed(1)} spm',
                  ),
                  _MetricTile(
                    icon: Icons.timer_outlined,
                    label: 'Step Time',
                    value:
                        '${_metrics!.avgStepTime.toStringAsFixed(3)} s',
                  ),
                  _MetricTile(
                    icon: Icons.arrow_forward,
                    label: 'Gait Speed',
                    value:
                        '${_metrics!.avgGaitSpeed.toStringAsFixed(3)} m/s',
                  ),
                  _MetricTile(
                    icon: Icons.bolt,
                    label: 'Avg Impact',
                    value:
                        '${_metrics!.avgImpact.toStringAsFixed(3)} g',
                  ),
                ],
              ),

              // ── SPARC gauge (mirrors Python SPARC note) ─────────────────
              const SizedBox(height: 20),
              _SectionLabel('Movement Smoothness (SPARC)'),
              const SizedBox(height: 8),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _metrics!.avgSparc.toStringAsFixed(3),
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: _sparcColor(_metrics!.avgSparc)),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _sparcLabel(_metrics!.avgSparc),
                          style: TextStyle(
                              color:
                                  _sparcColor(_metrics!.avgSparc),
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _SparcBar(sparc: _metrics!.avgSparc),
                    const SizedBox(height: 6),
                    const Text(
                      '−2 to −4 → healthy walking   '
                      '< −6 → jittery / fatigue',
                      style: TextStyle(
                          fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ),

              // ── Stance / Swing bar (mirrors Plot 2) ─────────────────────
              const SizedBox(height: 20),
              _SectionLabel('Gait Cycle Composition'),
              const SizedBox(height: 8),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stance ${_metrics!.stancePct.toStringAsFixed(1)}%  '
                      '·  Swing ${_metrics!.swingPct.toStringAsFixed(1)}%',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    _PhaseBar(
                        stancePct: _metrics!.stancePct,
                        swingPct: _metrics!.swingPct),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _Legend(
                            color: const Color(0xFF4682B4),
                            label: 'Stance'),
                        const SizedBox(width: 16),
                        _Legend(
                            color: const Color(0xFF87CEEB),
                            label: 'Swing'),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Detailed timing ─────────────────────────────────────────
              const SizedBox(height: 20),
              _SectionLabel('Detailed Timing'),
              const SizedBox(height: 8),
              _Card(
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1.5),
                  },
                  children: [
                    _tableRow('Avg Stride Time',
                        '${_metrics!.avgStrideTime.toStringAsFixed(3)} s'),
                    _tableRow('Avg Stance Time',
                        '${_metrics!.avgStanceTime.toStringAsFixed(3)} s'),
                    _tableRow('Avg Swing Time',
                        '${_metrics!.avgSwingTime.toStringAsFixed(3)} s'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  TableRow _tableRow(String label, String value) {
    return TableRow(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(label,
            style: const TextStyle(color: Colors.black54, fontSize: 13)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    ]);
  }

  Color _sparcColor(double sparc) {
    if (sparc >= -4) return Colors.green;
    if (sparc >= -6) return Colors.orange;
    return Colors.redAccent;
  }

  String _sparcLabel(double sparc) {
    if (sparc >= -4) return 'Smooth (healthy walking)';
    if (sparc >= -6) return 'Moderate irregularity';
    return 'Jittery / fatigue pattern';
  }
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  final Widget child;
  final Color? color;

  const _Card({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Color(0xFF1A6B8A)),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1A6B8A), size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(color: Colors.black45, fontSize: 11)),
        ],
      ),
    );
  }
}

/// Horizontal bar mirroring the matplotlib Phase Composition plot.
class _PhaseBar extends StatelessWidget {
  final double stancePct;
  final double swingPct;

  const _PhaseBar({required this.stancePct, required this.swingPct});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final total = stancePct + swingPct;
      final stanceFrac = total > 0 ? stancePct / total : 0.6;
      final swingFrac = 1 - stanceFrac;
      final totalW = constraints.maxWidth;

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              _BarSegment(
                width: totalW * stanceFrac,
                color: const Color(0xFF4682B4),
                label: 'Stance\n${stancePct.toStringAsFixed(1)}%',
                textColor: Colors.white,
              ),
              _BarSegment(
                width: totalW * swingFrac,
                color: const Color(0xFF87CEEB),
                label: 'Swing\n${swingPct.toStringAsFixed(1)}%',
                textColor: Colors.black87,
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _BarSegment extends StatelessWidget {
  final double width;
  final Color color;
  final String label;
  final Color textColor;

  const _BarSegment({
    required this.width,
    required this.color,
    required this.label,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: color,
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor),
      ),
    );
  }
}

/// SPARC bar: maps range 0 to −10 onto a coloured progress indicator.
class _SparcBar extends StatelessWidget {
  final double sparc;
  const _SparcBar({required this.sparc});

  @override
  Widget build(BuildContext context) {
    // Clamp to [−10, 0]; 0 = best, −10 = worst.
    final clamped = sparc.clamp(-10.0, 0.0);
    final fraction = (clamped.abs() / 10.0).clamp(0.0, 1.0);

    final color = fraction < 0.4
        ? Colors.green
        : fraction < 0.7
            ? Colors.orange
            : Colors.redAccent;

    return LayoutBuilder(builder: (_, constraints) {
      return Stack(
        children: [
          Container(
            height: 12,
            width: constraints.maxWidth,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          Container(
            height: 12,
            width: constraints.maxWidth * fraction,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      );
    });
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 14,
            height: 14,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}