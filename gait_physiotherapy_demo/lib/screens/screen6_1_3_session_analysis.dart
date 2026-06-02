import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'screen4_home_menu.dart';

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
  bool _simulateSaveFailure = false;
  bool _isSaving = false;
  bool _saveSuccess = true; // Initially true since it writes during analysis completion

  Color _scoreColor(int score) {
    if (score >= 85) return const Color(0xFF00C48C);
    if (score >= 70) return const Color(0xFFFFBF00);
    return const Color(0xFFFF4E6A);
  }

  void _triggerStorageAction() async {
    setState(() {
      _isSaving = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isSaving = false;
      _saveSuccess = !_simulateSaveFailure;
    });

    if (!mounted) return;

    if (_saveSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session data synchronized and stored successfully on wearable & local DB!'),
          backgroundColor: Color(0xFF00C48C),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data commit failed. Retrying sync with wearable memory address...'),
          backgroundColor: Color(0xFFFF4E6A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.session['score'] as int;
    final scoreColor = _scoreColor(score);
    final slmText = widget.session['slm_interpretation'] as String;

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
                          onTap: () {
                            // Clear history back to dashboard
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Screen4HomeMenu(deviceName: widget.user['name']),
                              ),
                              (route) => false,
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
                        // Storage simulation checkboxes for debugging
                        Row(
                          children: [
                            Checkbox(
                              value: _simulateSaveFailure,
                              activeColor: const Color(0xFFFF4E6A),
                              onChanged: (val) {
                                setState(() {
                                  _simulateSaveFailure = val ?? false;
                                });
                              },
                            ),
                            const Text('Simulate Error', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ],
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
                      _Tag(label: widget.session['label'], color: const Color(0xFF6C63FF)),
                      _Tag(
                        label: widget.session['duration'],
                        color: const Color(0xFFFFBF00),
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
                      color: const Color(0xFF6C63FF).withOpacity(0.09),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.psychology_outlined, color: Color(0xFF6C63FF), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SLM INTERPRETATION SUMMARY',
                                style: TextStyle(
                                  color: Color(0xFF6C63FF),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                slmText,
                                style: const TextStyle(
                                  color: Color(0xFF1A1D2E),
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
                              color: Color(0xFF1A1D2E),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            )),
                        const SizedBox(height: 4),
                        Text('Accelerometer points parsed from wearable SD card text logs',
                            style: TextStyle(color: Colors.black.withOpacity(0.35), fontSize: 12)),
                        const SizedBox(height: 20),
                        CustomPaint(
                          size: const Size(double.infinity, 80),
                          painter: _StaticWaveformPainter(color: scoreColor, points: rawWf),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Metrics grid ────────────────────────────────────
                  const Text('Session Metrics',
                      style: TextStyle(
                        color: Color(0xFF1A1D2E),
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
                      _MetricCard(
                        label: 'Stride Length',
                        value: '${widget.session['stride_length']} m',
                        icon: Icons.straighten,
                        color: const Color(0xFF6C63FF),
                      ),
                      _MetricCard(
                        label: 'Cadence',
                        value: '${widget.session['cadence']} spm',
                        icon: Icons.speed,
                        color: const Color(0xFFFF4E6A),
                      ),
                      _MetricCard(
                        label: 'Balance',
                        value: '${widget.session['balance']}% L / ${(100 - (widget.session['balance'] as int))}% R',
                        icon: Icons.balance,
                        color: const Color(0xFF00C48C),
                      ),
                      _MetricCard(
                        label: 'Symmetry',
                        value: '${widget.session['symmetry']}%',
                        icon: Icons.compare_arrows,
                        color: const Color(0xFFFFBF00),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Phase Breakdown ─────────────────────────────────
                  const Text('Gait Phase Breakdown',
                      style: TextStyle(
                        color: Color(0xFF1A1D2E),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      )),
                  const SizedBox(height: 14),
                  _PhaseBar(
                    label: 'Stance Phase',
                    value: widget.session['stance_phase'] as double,
                    color: const Color(0xFF6C63FF),
                  ),
                  const SizedBox(height: 10),
                  _PhaseBar(
                    label: 'Swing Phase',
                    value: widget.session['swing_phase'] as double,
                    color: const Color(0xFFFF4E6A),
                  ),
                  const SizedBox(height: 10),
                  _PhaseBar(
                    label: 'Double Support',
                    value: widget.session['double_support'] as double,
                    color: const Color(0xFF00C48C),
                  ),

                  const SizedBox(height: 24),

                  // ── Storage Status Options ──────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _saveSuccess ? const Color(0xFF00C48C).withOpacity(0.08) : const Color(0xFFFF4E6A).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _saveSuccess ? const Color(0xFF00C48C).withOpacity(0.3) : const Color(0xFFFF4E6A).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _saveSuccess ? Icons.check_circle_outline : Icons.error_outline,
                              color: _saveSuccess ? const Color(0xFF00C48C) : const Color(0xFFFF4E6A),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _saveSuccess ? 'Successfully Stored (Mobile & Band)' : 'Storage Sync Pending',
                              style: TextStyle(
                                color: _saveSuccess ? const Color(0xFF00C48C) : const Color(0xFFFF4E6A),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (!_saveSuccess || _simulateSaveFailure)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF4E6A),
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

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Colors.black.withOpacity(0.38), fontSize: 11, height: 1.3)),
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
        Text(label, style: const TextStyle(color: Color(0xFF1A1D2E), fontWeight: FontWeight.w600, fontSize: 13)),
        Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
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
    ]);
  }
}

class _StaticWaveformPainter extends CustomPainter {
  final Color color;
  final List<double> points;
  _StaticWaveformPainter({required this.color, required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final mid = size.height / 2;
    final spacing = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * spacing;
      final y = mid - (points[i] * (size.height * 0.3));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Faded fill
    final fillPath = Path()
      ..addPath(path, Offset.zero)
      ..lineTo(size.width, mid)
      ..lineTo(0, mid)
      ..close();

    canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withOpacity(0.18), color.withOpacity(0.0)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
