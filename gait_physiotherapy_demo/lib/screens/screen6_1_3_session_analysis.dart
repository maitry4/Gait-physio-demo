import 'package:flutter/material.dart';

class Screen613SessionAnalysis extends StatelessWidget {
  final Map<String, dynamic> session;
  final Map<String, dynamic> user;

  const Screen613SessionAnalysis({
    super.key, required this.session, required this.user,
  });

  Color _scoreColor(int score) {
    if (score >= 85) return const Color(0xFF00C48C);
    if (score >= 70) return const Color(0xFFFFBF00);
    return const Color(0xFFFF4E6A);
  }

  @override
  Widget build(BuildContext context) {
    final score = session['score'] as int;
    final scoreColor = _scoreColor(score);

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
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(session['id'],
                                  style: const TextStyle(
                                    color: Colors.white, fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  )),
                              const SizedBox(height: 4),
                              Text('${user['name']}  ·  ${session['date']}',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.45),
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                        // Score badge
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: scoreColor, width: 3),
                            color: scoreColor.withOpacity(0.12),
                          ),
                          child: Center(
                            child: Text('$score',
                                style: TextStyle(
                                  color: scoreColor,
                                  fontWeight: FontWeight.w800, fontSize: 20,
                                )),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Tags row
                    Wrap(spacing: 8, children: [
                      _Tag(label: session['label'], color: const Color(0xFF6C63FF)),
                      _Tag(label: session['duration'], color: const Color(0xFFFFBF00),
                          icon: Icons.timer_outlined),
                    ]),
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
                  // ── Waveform placeholder ────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 14, offset: const Offset(0, 5),
                      )],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Gait Waveform',
                            style: TextStyle(
                              color: Color(0xFF1A1D2E),
                              fontWeight: FontWeight.w700, fontSize: 15,
                            )),
                        const SizedBox(height: 4),
                        Text('Accelerometer data over session',
                            style: TextStyle(
                                color: Colors.black.withOpacity(0.35),
                                fontSize: 12)),
                        const SizedBox(height: 16),
                        CustomPaint(
                          size: const Size(double.infinity, 80),
                          painter: _WaveformPainter(
                              color: scoreColor, score: score),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Metrics grid ────────────────────────────────────
                  const Text('Session Metrics',
                      style: TextStyle(
                        color: Color(0xFF1A1D2E),
                        fontWeight: FontWeight.w700, fontSize: 16,
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
                      _MetricCard(label: 'Stride Length', value: '1.24 m',
                          icon: Icons.straighten, color: const Color(0xFF6C63FF)),
                      _MetricCard(label: 'Cadence', value: '112 spm',
                          icon: Icons.speed, color: const Color(0xFFFF4E6A)),
                      _MetricCard(label: 'Balance', value: '${score - 5}%',
                          icon: Icons.balance, color: const Color(0xFF00C48C)),
                      _MetricCard(label: 'Symmetry', value: '${score - 14}%',
                          icon: Icons.compare_arrows, color: const Color(0xFFFFBF00)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Phase breakdown ─────────────────────────────────
                  const Text('Gait Phase Breakdown',
                      style: TextStyle(
                        color: Color(0xFF1A1D2E),
                        fontWeight: FontWeight.w700, fontSize: 16,
                      )),
                  const SizedBox(height: 14),
                  _PhaseBar(label: 'Stance Phase', value: 0.62,
                      color: const Color(0xFF6C63FF)),
                  const SizedBox(height: 10),
                  _PhaseBar(label: 'Swing Phase', value: 0.38,
                      color: const Color(0xFFFF4E6A)),
                  const SizedBox(height: 10),
                  _PhaseBar(label: 'Double Support', value: 0.22,
                      color: const Color(0xFF00C48C)),

                  const SizedBox(height: 20),

                  // ── Notes ───────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D2E),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.note_alt_outlined,
                            color: Color(0xFF6C63FF), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Session Notes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700, fontSize: 14,
                                  )),
                              const SizedBox(height: 5),
                              Text(
                                'Patient demonstrated improved left-right symmetry '
                                'compared to previous session. Mild fatigue observed '
                                'in final 5 minutes. Recommend shorter intervals.',
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
        Text(label, style: TextStyle(
          color: color, fontSize: 11, fontWeight: FontWeight.w600,
        )),
      ]),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label, required this.value,
    required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8, offset: const Offset(0, 3),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(
              color: color, fontWeight: FontWeight.w800, fontSize: 17,
            )),
            Text(label, style: TextStyle(
              color: Colors.black.withOpacity(0.38),
              fontSize: 11, height: 1.3,
            )),
          ]),
        ],
      ),
    );
  }
}

class _PhaseBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _PhaseBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(
          color: Color(0xFF1A1D2E), fontWeight: FontWeight.w600, fontSize: 13,
        )),
        Text('${(value * 100).toInt()}%', style: TextStyle(
          color: color, fontWeight: FontWeight.w700, fontSize: 13,
        )),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: value, minHeight: 8,
          backgroundColor: color.withOpacity(0.12),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    ]);
  }
}

// ── Waveform painter ──────────────────────────────────────────────────────────
class _WaveformPainter extends CustomPainter {
  final Color color;
  final int score;
  _WaveformPainter({required this.color, required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final mid = size.height / 2;
    path.moveTo(0, mid);

    // Pseudo-sinusoidal waveform based on score
    final amplitude = size.height * 0.35 * (score / 100);
    final segments = 40;
    for (int i = 0; i <= segments; i++) {
      final x = (i / segments) * size.width;
      final phase = i / segments * 6 * 3.14159;
      final y = mid + amplitude * (i % 3 == 0 ? 0.4 : 1.0) *
          (i % 2 == 0 ? 1 : -1) *
          (0.5 + 0.5 * (i / segments));
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // Faded fill
    final fillPath = Path()..addPath(path, Offset.zero)
      ..lineTo(size.width, mid)
      ..lineTo(0, mid)
      ..close();
    canvas.drawPath(fillPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.18), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}