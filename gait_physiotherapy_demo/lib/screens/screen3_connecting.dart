import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'screen4_home_menu.dart';

class Screen3Connecting extends StatefulWidget {
  final String deviceName;
  const Screen3Connecting({super.key, required this.deviceName});

  @override
  State<Screen3Connecting> createState() => _Screen3ConnectingState();
}

class _Screen3ConnectingState extends State<Screen3Connecting>
    with TickerProviderStateMixin {
  late AnimationController _rotateCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  int _stepIndex = 0;
  final List<String> _steps = [
    'Searching for device...',
    'Establishing connection...',
    'Syncing configuration...',
    'Almost there...',
  ];

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Cycle status messages
    Future.delayed(const Duration(seconds: 1), _nextStep);
  }

  void _nextStep() {
    if (!mounted) return;
    if (_stepIndex < _steps.length - 1) {
      setState(() => _stepIndex++);
      Future.delayed(const Duration(milliseconds: 1200), _nextStep);
    } else {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                Screen4HomeMenu(deviceName: widget.deviceName),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Top bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // ── Animated ring + icon ───────────────────────────────
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer rotating dashed ring
                    AnimatedBuilder(
                      animation: _rotateCtrl,
                      builder: (_, __) => Transform.rotate(
                        angle: _rotateCtrl.value * 2 * math.pi,
                        child: CustomPaint(
                          size: const Size(220, 220),
                          painter: _DashedCirclePainter(
                            color: const Color(0xFFFF4E6A).withOpacity(0.4),
                            strokeWidth: 2,
                            dashCount: 20,
                          ),
                        ),
                      ),
                    ),
                    // Middle ring
                    AnimatedBuilder(
                      animation: _rotateCtrl,
                      builder: (_, __) => Transform.rotate(
                        angle: -_rotateCtrl.value * 2 * math.pi * 0.6,
                        child: CustomPaint(
                          size: const Size(170, 170),
                          painter: _DashedCirclePainter(
                            color: const Color(0xFF6C63FF).withOpacity(0.35),
                            strokeWidth: 1.5,
                            dashCount: 14,
                          ),
                        ),
                      ),
                    ),
                    // Pulsing center blob
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [
                              Color(0xFFFF4E6A),
                              Color(0xFFD63855),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4E6A).withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bluetooth_searching,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Device name
              Text(
                widget.deviceName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              // Animated status message
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _steps[_stepIndex],
                  key: ValueKey(_stepIndex),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Step progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _stepIndex == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _stepIndex >= i
                          ? const Color(0xFFFF4E6A)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Cancel button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.12)),
                  ),
                  child: const Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dashed circle painter ─────────────────────────────────────────────────────
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int dashCount;

  _DashedCirclePainter(
      {required this.color,
      required this.strokeWidth,
      required this.dashCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;
    final dashAngle = (2 * math.pi) / dashCount;
    final gapFraction = 0.4;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}