import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../providers/session_provider.dart';
import 'screen6_1_2_overall_progress.dart';
import 'screen6_1_3_session_analysis.dart';

class Screen611SessionList extends ConsumerWidget {
  final UserModel user;

  const Screen611SessionList({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionProvider);
    final sessions = sessionState.userSessions;

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
                            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                          ),
                        ),
                        // Overall Trend button (only if sessions present)
                        if (sessions.isNotEmpty)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Screen612OverallProgress(
                                    user: user,
                                    sessions: sessions,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.analytics, size: 16),
                            label: const Text(
                              'Overall Analysis',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Session Archives',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Sessions List ─────────────────────────────────────────────
          Expanded(
            child: sessionState.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4E6A)))
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${sessions.length} sessions logged locally in SQLite',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.4),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        sessions.isEmpty
                            ? Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.history_toggle_off, size: 48, color: Colors.black.withOpacity(0.15)),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No sessions recorded yet for ${user.name}.\nGo to "Start Live Session" to generate logs.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.black.withOpacity(0.35), height: 1.5, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Expanded(
                                child: ListView.separated(
                                  itemCount: sessions.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final s = sessions[index];
                                    return _SessionTile(
                                      sessionId: s.id,
                                      date: s.date,
                                      score: s.score,
                                      duration: s.duration,
                                      label: s.label,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => Screen613SessionAnalysis(
                                              session: s.toMap(),
                                              user: user.toMap(),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
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

class _SessionTile extends StatelessWidget {
  final String sessionId;
  final String date;
  final int score;
  final String duration;
  final String label;
  final VoidCallback onTap;

  const _SessionTile({
    required this.sessionId,
    required this.date,
    required this.score,
    required this.duration,
    required this.label,
    required this.onTap,
  });

  Color _scoreColor() {
    if (score >= 85) return const Color(0xFF00C48C);
    if (score >= 72) return const Color(0xFFFFBF00);
    return const Color(0xFFFF4E6A);
  }

  @override
  Widget build(BuildContext context) {
    final sColor = _scoreColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Score circle
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: sColor, width: 2),
                color: sColor.withOpacity(0.06),
              ),
              child: Center(
                child: Text(
                  '$score',
                  style: TextStyle(
                    color: sColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sessionId,
                    style: const TextStyle(
                      color: Color(0xFF1A1D2E),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        date,
                        style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(
                        duration,
                        style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (score >= 85 ? const Color(0xFF00C48C) : const Color(0xFF6C63FF)).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: score >= 85 ? const Color(0xFF00C48C) : const Color(0xFF6C63FF),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}