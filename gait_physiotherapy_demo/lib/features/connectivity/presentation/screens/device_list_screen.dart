import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gait_physiotherapy_demo/core/router/app_router.dart';
import 'package:gait_physiotherapy_demo/features/connectivity/presentation/providers/connectivity_provider.dart';
import 'package:gait_physiotherapy_demo/features/connectivity/presentation/widgets/device_tile.dart';

class Screen2DeviceList extends ConsumerStatefulWidget {
  const Screen2DeviceList({super.key});

  @override
  ConsumerState<Screen2DeviceList> createState() => _Screen2DeviceListState();
}

class _Screen2DeviceListState extends ConsumerState<Screen2DeviceList> {
  int? _selectedIndex;
  bool _simulateFailure = false;

  @override
  Widget build(BuildContext context) {
    final connState = ref.watch(connectivityProvider);
    final devices = connState.scannedDevices;

    return Scaffold(
      body: Column(
        children: [
          // ── Dark Header ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
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
                        // Scanning Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const PulsingDot(color: AppColors.secondary),
                              const SizedBox(width: 6),
                              const Text(
                                'Scanning...',
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Available Wearables',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pair your phone hotspot to the gait detection band.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Device List ───────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${devices.length} gait bands detected',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.4),
                          fontSize: 13,
                        ),
                      ),
                      // Failure Simulator Checkbox
                      Row(
                        children: [
                          Icon(Icons.bug_report, size: 16, color: Colors.black.withOpacity(0.4)),
                          const SizedBox(width: 4),
                          Text(
                            'Simulate Error',
                            style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Checkbox(
                            value: _simulateFailure,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() {
                                _simulateFailure = val ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  devices.isEmpty
                      ? const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        )
                      : Expanded(
                          child: ListView.separated(
                            itemCount: devices.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final device = devices[index];
                              final isSelected = _selectedIndex == index;
                              return DeviceTile(
                                name: device['name'],
                                deviceId: device['id'],
                                signalStrength: device['signal'],
                                isSelected: isSelected,
                                onTap: () => setState(() => _selectedIndex = index),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
          ),

          // ── Connect Button ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: AnimatedOpacity(
              opacity: _selectedIndex != null ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 250),
              child: GestureDetector(
                onTap: _selectedIndex != null
                    ? () {
                        final chosenDevice = devices[_selectedIndex!];
                        context.pushNamed(
                          AppRoutes.connecting,
                          extra: {
                            'deviceName': chosenDevice['name'],
                            'simulateFailure': _simulateFailure,
                          },
                        );
                      }
                    : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bluetooth_connected, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Authenticate & Connect',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
