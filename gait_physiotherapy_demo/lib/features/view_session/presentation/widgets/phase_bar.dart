import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';

class PhaseBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const PhaseBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 13)),
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
