import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gait_physiotherapy_demo/core/router/app_router.dart';
import 'package:gait_physiotherapy_demo/features/user_management/domain/entities/user_entity.dart';
import 'package:gait_physiotherapy_demo/features/view_session/presentation/providers/view_session_provider.dart';
import 'package:gait_physiotherapy_demo/features/view_session/presentation/widgets/session_tile.dart';

class Screen611SessionList extends ConsumerWidget {
  final UserModel user;

  const Screen611SessionList({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(viewSessionProvider);
    final sessions = sessionState.userSessions;

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
                            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                          ),
                        ),
                        // Overall Trend button (only if sessions present)
                        if (sessions.isNotEmpty)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              context.pushNamed(
                                AppRoutes.overallProgress,
                                extra: {
                                  'user': user,
                                  'sessions': sessions,
                                },
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
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                                    return SessionTile(
                                      sessionId: s.id,
                                      date: s.date,
                                      score: s.score,
                                      duration: s.duration,
                                      label: s.label,
                                      onTap: () {
                                        context.pushNamed(
                                          AppRoutes.sessionAnalysis,
                                          extra: {
                                            'session': s.toMap(),
                                            'user': user.toMap(),
                                          },
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
