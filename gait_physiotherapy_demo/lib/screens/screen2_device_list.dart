import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';
import 'screen3_connecting.dart';

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
              color: Color(0xFF1A1D2E),
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
                        // Scanning Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              _PulsingDot(color: const Color(0xFF6C63FF)),
                              const SizedBox(width: 6),
                              const Text(
                                'Scanning...',
                                style: TextStyle(
                                  color: Color(0xFF6C63FF),
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
                            activeColor: const Color(0xFFFF4E6A),
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
                            child: CircularProgressIndicator(color: Color(0xFFFF4E6A)),
                          ),
                        )
                      : Expanded(
                          child: ListView.separated(
                            itemCount: devices.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final device = devices[index];
                              final isSelected = _selectedIndex == index;
                              return _DeviceTile(
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Screen3Connecting(
                              deviceName: chosenDevice['name'],
                              simulateFailure: _simulateFailure,
                            ),
                          ),
                        );
                      }
                    : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4E6A),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4E6A).withOpacity(0.35),
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

class _DeviceTile extends StatelessWidget {
  final String name;
  final String deviceId;
  final int signalStrength;
  final bool isSelected;
  final VoidCallback onTap;

  const _DeviceTile({
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
    if (signalStrength >= 75) return const Color(0xFF00C48C);
    if (signalStrength >= 50) return const Color(0xFFFFBF00);
    return const Color(0xFFFF4E6A);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1D2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF4E6A) : Colors.transparent,
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
                    ? const Color(0xFFFF4E6A).withOpacity(0.15)
                    : const Color(0xFF1A1D2E).withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.watch,
                color: isSelected ? const Color(0xFFFF4E6A) : const Color(0xFF1A1D2E),
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
                      color: isSelected ? Colors.white : const Color(0xFF1A1D2E),
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
              const Icon(Icons.check_circle, color: Color(0xFFFF4E6A), size: 22),
            ],
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
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