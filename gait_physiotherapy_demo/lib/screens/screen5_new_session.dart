import 'package:flutter/material.dart';
import 'screen5_1_select_user.dart';
import 'screen5_2_add_new_user.dart';

class Screen5NewSession extends StatelessWidget {
  const Screen5NewSession({super.key});

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Icon
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4E6A).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.play_circle_outline_rounded,
                          color: Color(0xFFFF4E6A), size: 34),
                    ),
                    const SizedBox(height: 18),
                    const Text('Start a New Session',
                        style: TextStyle(
                          color: Colors.white, fontSize: 26,
                          fontWeight: FontWeight.w700, letterSpacing: -0.5,
                        )),
                    const SizedBox(height: 8),
                    Text('Select how you want to begin',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.45), fontSize: 14)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // ── Options ─────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _OptionCard(
                    title: 'Select an Existing User',
                    subtitle: 'Choose a previously registered patient to record a session',
                    icon: Icons.person_search_rounded,
                    color: const Color(0xFF6C63FF),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const Screen51SelectUser(mode: SelectUserMode.newSession))),
                  ),
                  const SizedBox(height: 16),
                  _OptionCard(
                    title: 'Add a New User',
                    subtitle: 'Register a new patient and immediately start their first session',
                    icon: Icons.person_add_alt_1_rounded,
                    color: const Color(0xFF00C48C),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const Screen52AddNewUser())),
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

class _OptionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title, required this.subtitle,
    required this.icon, required this.color, required this.onTap,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14, offset: const Offset(0, 5),
            )],
          ),
          child: Row(
            children: [
              Container(
                width: 58, height: 58,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, color: widget.color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: const TextStyle(
                      color: Color(0xFF1A1D2E), fontWeight: FontWeight.w700,
                      fontSize: 15,
                    )),
                    const SizedBox(height: 5),
                    Text(widget.subtitle, style: TextStyle(
                      color: Colors.black.withOpacity(0.38),
                      fontSize: 12.5, height: 1.4,
                    )),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    color: widget.color, size: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}