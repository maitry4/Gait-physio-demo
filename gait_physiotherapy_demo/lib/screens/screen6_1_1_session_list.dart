import 'package:flutter/material.dart';
import 'screen6_1_2_overall_progress.dart';
import 'screen6_1_3_session_analysis.dart';

class Screen611SessionList extends StatelessWidget {
  final Map<String, dynamic> user;
  const Screen611SessionList({super.key, required this.user});

  final List<Map<String, dynamic>> _sessions = const [
    {'id': 'S-001', 'date': '10 Apr 2026', 'duration': '18 min', 'score': 87, 'label': 'Baseline'},
    {'id': 'S-002', 'date': '05 Apr 2026', 'duration': '22 min', 'score': 79, 'label': 'Follow-up'},
    {'id': 'S-003', 'date': '28 Mar 2026', 'duration': '15 min', 'score': 91, 'label': 'Post-therapy'},
    {'id': 'S-004', 'date': '20 Mar 2026', 'duration': '20 min', 'score': 74, 'label': 'Weekly'},
    {'id': 'S-005', 'date': '12 Mar 2026', 'duration': '17 min', 'score': 68, 'label': 'Initial'},
  ];

  Color _scoreColor(int score) {
    if (score >= 85) return const Color(0xFF00C48C);
    if (score >= 70) return const Color(0xFFFFBF00);
    return const Color(0xFFFF4E6A);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
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
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white, size: 18),
                          ),
                        ),
                        // Overall progress button
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => Screen612OverallProgress(user: user),
                          )),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.insights_rounded,
                                    color: Color(0xFF6C63FF), size: 16),
                                SizedBox(width: 6),
                                Text('Overview',
                                    style: TextStyle(
                                      color: Color(0xFF6C63FF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text(
                            user['initials'] ?? 'U',
                            style: const TextStyle(
                              color: Color(0xFF6C63FF),
                              fontWeight: FontWeight.w700, fontSize: 16,
                            ),
                          )),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['name'],
                                style: const TextStyle(
                                  color: Colors.white, fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                )),
                            Text(user['id'],
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Session History',
                        style: TextStyle(
                          color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 4),
                    Text('Tap a session to view detailed analysis',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4), fontSize: 12)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // ── Session list ─────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              itemCount: _sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final s = _sessions[index];
                final scoreColor = _scoreColor(s['score']);
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => Screen613SessionAnalysis(
                        session: s, user: user),
                  )),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10, offset: const Offset(0, 3),
                      )],
                    ),
                    child: Row(
                      children: [
                        // Score ring
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 52, height: 52,
                              child: CircularProgressIndicator(
                                value: s['score'] / 100,
                                strokeWidth: 4,
                                backgroundColor: scoreColor.withOpacity(0.15),
                                valueColor: AlwaysStoppedAnimation(scoreColor),
                              ),
                            ),
                            Text('${s['score']}',
                                style: TextStyle(
                                  color: scoreColor,
                                  fontWeight: FontWeight.w800, fontSize: 13,
                                )),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(s['id'],
                                      style: const TextStyle(
                                        color: Color(0xFF1A1D2E),
                                        fontWeight: FontWeight.w700, fontSize: 15,
                                      )),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C63FF)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(s['label'],
                                        style: const TextStyle(
                                          color: Color(0xFF6C63FF),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined,
                                      size: 12,
                                      color: Colors.black.withOpacity(0.35)),
                                  const SizedBox(width: 4),
                                  Text(s['date'],
                                      style: TextStyle(
                                          color: Colors.black.withOpacity(0.4),
                                          fontSize: 12)),
                                  const SizedBox(width: 12),
                                  Icon(Icons.timer_outlined,
                                      size: 12,
                                      color: Colors.black.withOpacity(0.35)),
                                  const SizedBox(width: 4),
                                  Text(s['duration'],
                                      style: TextStyle(
                                          color: Colors.black.withOpacity(0.4),
                                          fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.black.withOpacity(0.2), size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}