import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';

class LiveWaveformPainter extends CustomPainter {
  final List<double> points;

  LiveWaveformPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.primary
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
          colors: [AppColors.primary, Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
