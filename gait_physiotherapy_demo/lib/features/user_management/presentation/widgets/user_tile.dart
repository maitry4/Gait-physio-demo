import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';

class UserTile extends StatelessWidget {
  final String name;
  final int age;
  final String id;
  final String date;
  final bool isSelected;
  final VoidCallback onTap;

  const UserTile({
    super.key,
    required this.name,
    required this.age,
    required this.id,
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.navy.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
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
                    name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Age: $age  ·  ID: $id',
                    style: TextStyle(
                      color: isSelected ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.chevron_right, color: isSelected ? AppColors.primary : Colors.black.withOpacity(0.2), size: 20),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    color: isSelected ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.25),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
