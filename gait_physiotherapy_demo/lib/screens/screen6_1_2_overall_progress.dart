import 'package:flutter/material.dart';
import 'screen6_1_1_session_list.dart';

class Screen612OverallProgress extends StatelessWidget {
  final Map<String, dynamic> user;
  const Screen612OverallProgress({super.key, required this.user});

  // Fake trend data points (0-100)
  static const List<double> _trend = [68, 74, 72, 79, 87, 91];
  static const List<String> _labels = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1D2E),
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
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white, size: 18),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => Screen611SessionList(user: user),
                          )),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4E6A).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.list_alt_rounded,
                                    color: Color(0xFFFF4E6A), size: 16),
                                SizedBox(width: 6),
                                Text('Sessions',
                                    style: TextStyle(
                                      color: Color(0xFFFF4E6A),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(user['name'],
                        style: const TextStyle(
                          color: Colors.white, fontSize: 24,
                          fontWeight: FontWeight.w700, letterSpacing: -0.3,
                        )),
                    Text('Overall Progress Analysis',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.45), fontSize: 14)),
                    const SizedBox(height: 8),
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
                  // ── Stat cards row ──────────────────────────────────
                  Row(children: [
                    _StatCard(label: 'Sessions', value: '6',
                        icon: Icons.event_note, color: const Color(0xFF6C63FF)),
                    const SizedBox(width: 12),
                    _StatCard(label: 'Avg Score', value: '79',
                        icon: Icons.star_outline_rounded,
                        color: const Color(0xFFFFBF00)),
                    const SizedBox(width: 12),
                    _StatCard(label: 'Trend', value: '+23',
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFF00C48C)),
                  ]),

                  const SizedBox(height: 24),

                  // ── Progress chart ──────────────────────────────────
                  const Text('Gait Score Trend',
                      style: TextStyle(
                        color: Color(0xFF1A1D2E),
                        fontWeight: FontWeight.w700, fontSize: 16,
                      )),
                  const SizedBox(height: 4),
                  Text('Across all recorded sessions',
                      style: TextStyle(
                          color: Colors.black.withOpacity(0.38), fontSize: 12)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 14, offset: const Offset(0, 5),
                      )],
                    ),
                    child: _LineChart(data: _trend, labels: _labels),
                  ),

                  const SizedBox(height: 24),

                  // ── Metric breakdown ────────────────────────────────
                  const Text('Metric Breakdown',
                      style: TextStyle(
                        color: Color(0xFF1A1D2E),
                        fontWeight: FontWeight.w700, fontSize: 16,
                      )),
                  const SizedBox(height: 14),
                  _MetricBar(label: 'Stride Length', value: 0.82,
                      color: const Color(0xFF6C63FF)),
                  const SizedBox(height: 12),
                  _MetricBar(label: 'Cadence', value: 0.74,
                      color: const Color(0xFFFF4E6A)),
                  const SizedBox(height: 12),
                  _MetricBar(label: 'Balance Index', value: 0.91,
                      color: const Color(0xFF00C48C)),
                  const SizedBox(height: 12),
                  _MetricBar(label: 'Step Symmetry', value: 0.67,
                      color: const Color(0xFFFFBF00)),

                  const SizedBox(height: 24),

                  // ── Physician note ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D2E),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded,
                            color: Color(0xFFFFBF00), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Clinical Insight',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700, fontSize: 14,
                                  )),
                              const SizedBox(height: 5),
                              Text(
                                'Patient shows consistent improvement in balance and stride. '
                                'Step symmetry needs further focus. '
                                'Recommend continued physiotherapy 3× per week.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 12.5, height: 1.5,
                                ),
                              ),
                            ],
                          ),
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

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label, required this.value,
    required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 3),
          )],
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(
            color: color, fontWeight: FontWeight.w800, fontSize: 20,
          )),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
            color: Colors.black.withOpacity(0.4), fontSize: 11,
          ), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ── Metric bar ────────────────────────────────────────────────────────────────
class _MetricBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MetricBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(
            color: Color(0xFF1A1D2E), fontWeight: FontWeight.w600, fontSize: 13,
          )),
          Text('${(value * 100).toInt()}%',
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ── Simple line chart (custom painter) ───────────────────────────────────────
class _LineChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  const _LineChart({required this.data, required this.labels});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: CustomPaint(
        painter: _LineChartPainter(data: data, labels: labels),
        size: Size.infinite,
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  _LineChartPainter({required this.data, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final minVal = 50.0;
    final maxVal = 100.0;
    final chartH = size.height - 24;
    final stepX = size.width / (data.length - 1);

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = chartH * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Gradient fill
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = chartH * (1 - (data[i] - minVal) / (maxVal - minVal));
      points.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(points.first.dx, chartH);
    for (final p in points) fillPath.lineTo(p.dx, p.dy);
    fillPath.lineTo(points.last.dx, chartH);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.25),
            const Color(0xFF6C63FF).withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, chartH)),
    );

    // Line
    final linePaint = Paint()
      ..color = const Color(0xFF6C63FF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final cp1 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i - 1].dy);
      final cp2 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots
    for (final p in points) {
      canvas.drawCircle(p, 5, Paint()..color = const Color(0xFF6C63FF));
      canvas.drawCircle(p, 3, Paint()..color = Colors.white);
    }

    // Labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < labels.length; i++) {
      tp.text = TextSpan(
        text: labels[i],
        style: TextStyle(
            color: Colors.black.withOpacity(0.35), fontSize: 10),
      );
      tp.layout();
      tp.paint(canvas,
          Offset(i * stepX - tp.width / 2, chartH + 8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}