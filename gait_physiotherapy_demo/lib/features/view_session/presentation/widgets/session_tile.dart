import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';

class SessionTile extends StatelessWidget {
  final String sessionId;
  final String date;
  final int score;
  final String duration;
  final String label;
  final VoidCallback onTap;

  const SessionTile({
    super.key,
    required this.sessionId,
    required this.date,
    required this.score,
    required this.duration,
    required this.label,
    required this.onTap,
  });

  Color _scoreColor() {
    if (score >= 85) return AppColors.success;
    if (score >= 72) return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final sColor = _scoreColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
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
        child: Row(
          children: [
            // Score circle
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: sColor, width: 2),
                color: sColor.withOpacity(0.06),
              ),
              child: Center(
                child: Text(
                  '$score',
                  style: TextStyle(
                    color: sColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sessionId,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        date,
                        style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(
                        duration,
                        style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (score >= 85 ? AppColors.success : AppColors.secondary).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: score >= 85 ? AppColors.success : AppColors.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
