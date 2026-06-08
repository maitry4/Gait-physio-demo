import 'package:flutter/material.dart';

class StaticWaveformPainter extends CustomPainter {
  final Color color;
  final List<double> points;

  StaticWaveformPainter({required this.color, required this.points});

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
