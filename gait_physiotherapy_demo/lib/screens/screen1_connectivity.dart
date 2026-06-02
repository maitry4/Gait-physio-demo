import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';
import 'screen2_device_list.dart';

class Screen1Connectivity extends ConsumerWidget {
  const Screen1Connectivity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connState = ref.watch(connectivityProvider);
    final connNotifier = ref.read(connectivityProvider.notifier);

    final bothEnabled = connState.isBluetoothOn && connState.isHotspotOn;

    return Scaffold(
      body: Column(
        children: [
          // ── Top Illustration Section ──────────────────────────────────
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
                    Container(
                      width: 180,
                      height: 180,
                      decoration: const BoxDecoration(
                        color: Color(0xFF252840),
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
                                color: (bothEnabled ? const Color(0xFF00C48C) : const Color(0xFFFF4E6A)).withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                          ),
                          // Icons
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.bluetooth_searching,
                                size: 68,
                                color: bothEnabled ? const Color(0xFF00C48C) : const Color(0xFFFF4E6A),
                              ),
                            ],
                          ),
                          // Hotspot status indicator dot
                          Positioned(
                            top: 28,
                            right: 24,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: (connState.isHotspotOn ? const Color(0xFF00C48C) : const Color(0xFF6C63FF)).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                connState.isHotspotOn ? Icons.wifi : Icons.wifi_tethering_error,
                                size: 20,
                                color: connState.isHotspotOn ? const Color(0xFF00C48C) : const Color(0xFF6C63FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Hardware Check',
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
                        bothEnabled
                            ? 'Bluetooth and Hotspot configurations validated. Press below to begin searching for your Gait band.'
                            : 'Enable both Bluetooth and Hotspot. BLE handles initial sync; Wi-Fi transfers high-speed biomechanics data.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 13.5,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom Action Section ──────────────────────────────────
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Status Pills
                  Row(
                    children: [
                      _StatusPill(
                        icon: connState.isBluetoothOn ? Icons.bluetooth : Icons.bluetooth_disabled,
                        label: 'Bluetooth',
                        isOff: !connState.isBluetoothOn,
                        color: connState.isBluetoothOn ? const Color(0xFF00C48C) : const Color(0xFFFF4E6A),
                        onTap: () => connNotifier.toggleBluetooth(!connState.isBluetoothOn),
                      ),
                      const SizedBox(width: 12),
                      _StatusPill(
                        icon: connState.isHotspotOn ? Icons.wifi_tethering : Icons.wifi_tethering_error,
                        label: 'Hotspot',
                        isOff: !connState.isHotspotOn,
                        color: connState.isHotspotOn ? const Color(0xFF00C48C) : const Color(0xFF6C63FF),
                        onTap: () => connNotifier.toggleHotspot(!connState.isHotspotOn),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Dynamic action button
                  GestureDetector(
                    onTap: () {
                      if (bothEnabled) {
                        connNotifier.startScanning();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Screen2DeviceList()),
                        );
                      } else {
                        // Display error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enable both Bluetooth and Hotspot toggles to continue.'),
                            backgroundColor: Color(0xFFFF4E6A),
                          ),
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: bothEnabled ? const Color(0xFF00C48C) : Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: bothEnabled
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF00C48C).withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            bothEnabled ? Icons.search : Icons.lock_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            bothEnabled ? 'Scan for Gait Devices' : 'Toggles Required',
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
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Ensure hotspot details saved in Step 1 match your device configuration.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.35),
                      fontSize: 11,
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

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isOff;
  final Color color;
  final VoidCallback onTap;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.isOff,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isOff ? 'OFF (Tap)' : 'ACTIVE',
                      style: TextStyle(
                        color: color.withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}