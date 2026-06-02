import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';
import '../providers/session_provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import 'screen0_credentials.dart';
import 'screen5_1_select_user.dart';
import 'screen5_2_add_new_user.dart';
import 'screen5_new_session.dart';
import 'screen7_research_share.dart';
import 'screen8_therapist_pdf.dart';

class Screen4HomeMenu extends ConsumerWidget {
  final String deviceName;
  const Screen4HomeMenu({super.key, required this.deviceName});

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildActiveSessionCard(BuildContext context, UserModel user, SessionState sessionState) {
    final durationStr = _formatDuration(sessionState.recordDurationSeconds);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE93B57), Color(0xFF9E1029)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4E6A).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ACTIVE RUNNING SESSION',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      durationStr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Patient: ${user.name}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Steps Detected: ${sessionState.stepCount}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Screen5NewSession(user: user),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_run, color: Color(0xFF9E1029), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Resume Live Tracking',
                      style: TextStyle(
                        color: Color(0xFF9E1029),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connState = ref.watch(connectivityProvider);
    final sessionState = ref.watch(sessionProvider);
    final isRecording = sessionState.isRecording;
    final activeUserId = sessionState.activeRecordingUserId;

    UserModel? activeUser;
    if (isRecording && activeUserId != null) {
      final users = ref.watch(userProvider).users;
      try {
        activeUser = users.firstWhere(
          (u) => u.id == activeUserId,
          orElse: () => UserModel(
            id: activeUserId,
            name: 'Active Patient',
            age: 0,
            dateAdded: '',
          ),
        );
      } catch (_) {
        activeUser = UserModel(
          id: activeUserId,
          name: 'Active Patient',
          age: 0,
          dateAdded: '',
        );
      }
    }

    return Scaffold(
      body: Column(
        children: [
          // ── Dashboard Header ──────────────────────────────────────────
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
                        // System Title
                        const Text(
                          'Gait Physio',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        // Connected Pill
                        GestureDetector(
                          onTap: () {
                            ref.read(connectivityProvider.notifier).disconnect();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const Screen0Credentials()),
                              (route) => false,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C48C).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF00C48C).withOpacity(0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.link, color: Color(0xFF00C48C), size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Linked (Disconnect)',
                                  style: TextStyle(
                                    color: Color(0xFF00C48C),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'Clinician Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Paired Device: ${connState.connectedDeviceName ?? deviceName}',
                      style: const TextStyle(
                        color: Color(0xFFFF4E6A),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Dashboard Grid ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isRecording && activeUser != null) ...[
                    _buildActiveSessionCard(context, activeUser, sessionState),
                    const SizedBox(height: 20),
                  ],
                  const Text(
                    'Clinical Workflows',
                    style: TextStyle(
                      color: Color(0xFF1A1D2E),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 1. Start a Session Card (Highlighted)
                  _WorkflowCard(
                    title: 'Start Live Session',
                    subtitle: 'Capture sensor metrics from gait band',
                    icon: Icons.play_circle_outline,
                    color: const Color(0xFFFF4E6A),
                    isPrimary: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Screen51SelectUser(mode: SelectUserMode.startSession),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Grid of other options
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                    children: [
                      // 2. View Sessions
                      _GridCard(
                        title: 'View Sessions',
                        icon: Icons.history,
                        color: const Color(0xFF6C63FF),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Screen51SelectUser(mode: SelectUserMode.viewSession),
                          ),
                        ),
                      ),
                      // 3. Share Data for Research
                      _GridCard(
                        title: 'Share Dataset',
                        icon: Icons.share,
                        color: const Color(0xFF00C48C),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Screen7ResearchShare(),
                          ),
                        ),
                      ),
                      // 4. Add User
                      _GridCard(
                        title: 'Add New User',
                        icon: Icons.person_add_outlined,
                        color: const Color(0xFFFFBF00),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Screen52AddNewUser(),
                          ),
                        ),
                      ),
                      // 5. Get Report PDF
                      _GridCard(
                        title: 'Get Report PDF',
                        icon: Icons.picture_as_pdf_outlined,
                        color: Colors.blueGrey,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Screen8TherapistPdf(),
                          ),
                        ),
                      ),
                    ],
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

class _WorkflowCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isPrimary;
  final VoidCallback onTap;

  const _WorkflowCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GridCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1A1D2E),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.black.withOpacity(0.3), size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}