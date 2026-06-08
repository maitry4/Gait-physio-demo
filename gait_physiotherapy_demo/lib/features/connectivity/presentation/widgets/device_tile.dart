import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';

class DeviceTile extends StatelessWidget {
  final String name;
  final String deviceId;
  final int signalStrength;
  final bool isSelected;
  final VoidCallback onTap;

  const DeviceTile({
    super.key,
    required this.name,
    required this.deviceId,
    required this.signalStrength,
    required this.isSelected,
    required this.onTap,
  });

  IconData _signalIcon() {
    if (signalStrength >= 75) return Icons.signal_cellular_alt;
    if (signalStrength >= 50) return Icons.signal_cellular_alt_2_bar;
    return Icons.signal_cellular_alt_1_bar;
  }

  Color _signalColor() {
    if (signalStrength >= 75) return AppColors.success;
    if (signalStrength >= 50) return AppColors.warning;
    return AppColors.primary;
  }

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
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.navy.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.watch,
                color: isSelected ? AppColors.primary : AppColors.navy,
                size: 26,
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
                  const SizedBox(height: 3),
                  Text(
                    deviceId,
                    style: TextStyle(
                      color: isSelected ? Colors.white.withOpacity(0.45) : Colors.black.withOpacity(0.35),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Icon(_signalIcon(), color: _signalColor(), size: 20),
                const SizedBox(height: 3),
                Text(
                  '$signalStrength%',
                  style: TextStyle(
                    color: _signalColor(),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 12),
              const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}

class PulsingDot extends StatefulWidget {
  final Color color;
  const PulsingDot({super.key, required this.color});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
