import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:gait_physiotherapy_demo/features/checks/presentation/provider/check_provider.dart';

class CheckListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final CheckStatus status;
  final VoidCallback onFix;

  const CheckListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onFix,
  });

  @override
  Widget build(BuildContext context) {
    Widget trailing;
    switch (status) {
      case CheckStatus.pending:
        trailing = const Icon(Icons.circle_outlined, color: Colors.grey);
        break;
      case CheckStatus.loading:
        trailing = const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        );
        break;
      case CheckStatus.passed:
        trailing = const Icon(Icons.check_circle, color: AppColors.success);
        break;
      case CheckStatus.failed:
        trailing = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onFix,
          child: const Text('FIX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navy),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.5)),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}