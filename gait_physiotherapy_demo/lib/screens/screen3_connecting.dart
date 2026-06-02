import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../providers/connectivity_provider.dart';
import 'screen4_home_menu.dart';

class Screen3Connecting extends ConsumerStatefulWidget {
  final String deviceName;
  final bool simulateFailure;

  const Screen3Connecting({
    super.key,
    required this.deviceName,
    required this.simulateFailure,
  });

  @override
  ConsumerState<Screen3Connecting> createState() => _Screen3ConnectingState();
}

class _Screen3ConnectingState extends ConsumerState<Screen3Connecting>
    with TickerProviderStateMixin {
  late AnimationController _rotateCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  int _stepIndex = 0;
  final List<String> _steps = [
    'Opening BLE Channel...',
    'Sending Hotspot SSID & Key...',
    'Awaiting Device Wi-Fi Handshake...',
    'Almost there...',
  ];

  bool _isConnecting = true;
  String? _failureMessage;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startConnectionProcess();
    });
  }

  Future<void> _startConnectionProcess() async {
    _cycleMessages();

    try {
      // Fire the Riverpod connection handler
      final success = await ref.read(connectivityProvider.notifier).connectToDevice(
            widget.deviceName,
            simulateFailure: widget.simulateFailure,
          );

      if (!mounted) return;

      if (success) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => Screen4HomeMenu(deviceName: widget.deviceName),
          ),
          (route) => false, // Clear navigation stack so user lands on Dashboard
        );
      } else {
        final connState = ref.read(connectivityProvider);
        setState(() {
          _isConnecting = false;
          _failureMessage = connState.errorMessage ?? 'Bluetooth connection failed.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _failureMessage = 'Internal Connection Error: $e';
        });
      }
    }
  }

  void _cycleMessages() {
    if (!mounted || !_isConnecting) return;
    if (_stepIndex < _steps.length - 1) {
      setState(() => _stepIndex++);
      Future.delayed(const Duration(milliseconds: 900), _cycleMessages);
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
    if (!_isConnecting) {
      return _buildFailureView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1D2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
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
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Rotating rings
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
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
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFFFF4E6A), Color(0xFFD63855)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4E6A).withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.bluetooth_searching, color: Colors.white, size: 44),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              Text(
                widget.deviceName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _steps[_stepIndex],
                  key: ValueKey(_stepIndex),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 36),

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
                      color: _stepIndex >= i ? const Color(0xFFFF4E6A) : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const Spacer(),

              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: const Center(
                    child: Text(
                      'Cancel pairing',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
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

  Widget _buildFailureView() {
    return Scaffold(
      backgroundColor: const Color(0xFF1E101D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4E6A).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.wifi_tethering_error, size: 48, color: Color(0xFFFF4E6A)),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Connection Failed',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _failureMessage ?? 'Device did not acknowledge hotspot registration.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Suggestions: Verify your phone hotspot is ON, the password matches the SSID configuration, and the band is within range.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isConnecting = true;
                    _stepIndex = 0;
                    _failureMessage = null;
                  });
                  _startConnectionProcess();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4E6A),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Text(
                      'Retry Handshake',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: const Center(
                    child: Text(
                      'Return to Devices',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
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

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int dashCount;

  _DashedCirclePainter({required this.color, required this.strokeWidth, required this.dashCount});

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