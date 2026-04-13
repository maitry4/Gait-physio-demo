import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/screens/screen2_device_list.dart';

class Screen1Connectivity extends StatelessWidget {
  const Screen1Connectivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── Top illustration section (dark navy) ──────────────────────
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1D2E),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    // Illustration placeholder — replace with your SVG/Lottie
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: const Color(0xFF252840),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFF4E6A).withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                          ),
                          // Bluetooth icon with slash
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.bluetooth,
                                size: 64,
                                color: Colors.white.withOpacity(0.15),
                              ),
                              Icon(
                                Icons.bluetooth_disabled,
                                size: 72,
                                color: const Color(0xFFFF4E6A),
                              ),
                            ],
                          ),
                          // Hotspot icon — top right
                          Positioned(
                            top: 28,
                            right: 24,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C63FF).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.wifi_tethering_error,
                                size: 20,
                                color: Color(0xFF6C63FF),
                              ),
                            ),
                          ),
                          // Small dot accent
                          Positioned(
                            bottom: 30,
                            left: 26,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFBF00),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Connection Required',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Your Bluetooth and Hotspot are currently turned off. Please enable them to connect to your Gait device.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom action section (light) ────────────────────────────
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Status pills
                  Row(
                    children: [
                      _StatusPill(
                        icon: Icons.bluetooth_disabled,
                        label: 'Bluetooth',
                        isOff: true,
                        color: const Color(0xFFFF4E6A),
                      ),
                      const SizedBox(width: 12),
                      _StatusPill(
                        icon: Icons.wifi_tethering_error,
                        label: 'Hotspot',
                        isOff: true,
                        color: const Color(0xFF6C63FF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Enable Bluetooth button
                  _ActionButton(
                    label: 'Enable Bluetooth',
                    icon: Icons.bluetooth,
                    color: const Color(0xFFFF4E6A),
                    onTap: () {
                      // TODO: invoke platform channel to open BT settings
                    },
                  ),
                  const SizedBox(height: 14),
                  // Enable Hotspot button
                  _ActionButton(
                    label: 'Enable Hotspot',
                    icon: Icons.wifi_tethering,
                    color: const Color(0xFF6C63FF),
                    onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const Screen2DeviceList())),
                  ),
                  // const SizedBox(height: 20),
                  Text(
                    'Both must be active to discover Gait devices',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.35),
                      fontSize: 12,
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

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isOff;
  final Color color;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.isOff,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  isOff ? 'OFF' : 'ON',
                  style: TextStyle(
                    color: color.withOpacity(0.6),
                    fontSize: 11,
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}