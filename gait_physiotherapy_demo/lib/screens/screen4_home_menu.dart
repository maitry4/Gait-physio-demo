import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/screens/screen5_2_add_new_user.dart';
import 'package:gait_physiotherapy_demo/screens/screen5_new_session.dart';
import 'package:gait_physiotherapy_demo/screens/screen6_view_session.dart';


class Screen4HomeMenu extends StatelessWidget {
  final String deviceName;
  const Screen4HomeMenu({super.key, required this.deviceName});

  @override
  Widget build(BuildContext context) {
    final List<_MenuOption> options = [
      _MenuOption(
        title: 'Start a New Session',
        subtitle: 'Begin recording data',
        icon: Icons.play_circle_outline_rounded,
        color: const Color(0xFFFF4E6A),
        onTap: () => {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const Screen5NewSession())),}
      ),
      _MenuOption(
        title: 'View a Session',
        subtitle: 'Analyse previous recordings',
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFF6C63FF),
        onTap: () => {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const Screen6ViewSession())),}
      ),
      _MenuOption(
        title: 'Add a New User',
        subtitle: 'Register a new patient profile',
        icon: Icons.person_add_alt_1_rounded,
        color: const Color(0xFF00C48C),
        onTap: () => {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) =>  Screen52AddNewUser())),}
      ),
      _MenuOption(
        title: 'Save Data to Cloud',
        subtitle: 'Sync & backup all session data',
        icon: Icons.cloud_upload_outlined,
        color: const Color(0xFFFFBF00),
        onTap: () => {}
        // Navigator.push(context,
            // MaterialPageRoute(builder: (_) => const Screen8SaveCloud())),
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          // ── Dark header ─────────────────────────────────────────────
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
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Connected badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C48C).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00C48C),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                deviceName,
                                style: const TextStyle(
                                  color: Color(0xFF00C48C),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.settings_outlined,
                              color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'What would you\nlike to do?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select an action to get started',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // ── Menu grid ───────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.88,
                children: options
                    .map((opt) => _MenuCard(option: opt))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────
class _MenuOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _MenuOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

// ── Menu card ─────────────────────────────────────────────────────────────────
class _MenuCard extends StatefulWidget {
  final _MenuOption option;
  const _MenuCard({required this.option});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opt = widget.option;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        opt.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon container
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: opt.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(opt.icon, color: opt.color, size: 28),
                ),
                const Spacer(),
                Text(
                  opt.title,
                  style: const TextStyle(
                    color: Color(0xFF1A1D2E),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  opt.subtitle,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.38),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                // Arrow chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: opt.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Open',
                        style: TextStyle(
                          color: opt.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_forward, color: opt.color, size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}