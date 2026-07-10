import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/core/router/app_routes.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gait_physiotherapy_demo/core/router/app_router.dart';
import 'package:gait_physiotherapy_demo/features/user_management/domain/entities/user_entity.dart';
import 'package:gait_physiotherapy_demo/features/view_session/presentation/providers/view_session_provider.dart';
import 'package:gait_physiotherapy_demo/features/view_session/presentation/widgets/session_tile.dart';

class Screen611SessionList extends ConsumerStatefulWidget {
  final UserModel user;

  const Screen611SessionList({super.key, required this.user});

  @override
  ConsumerState<Screen611SessionList> createState() => _Screen611SessionListState();
}

class _Screen611SessionListState extends ConsumerState<Screen611SessionList> {
  String? _selectedLeg;

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(viewSessionProvider);
    final sessions = sessionState.userSessions;
    
    final filteredSessions = _selectedLeg == null
        ? sessions
        : sessions.where((s) => s.label.toUpperCase().startsWith(_selectedLeg!)).toList();

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
                          onTap: () {
                            if (_selectedLeg != null) {
                              setState(() => _selectedLeg = null);
                            } else {
                              context.pop();
                            }
                          },
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
                                  'user': widget.user,
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
                      _selectedLeg == null ? 'Session Archives' : '${_selectedLeg == 'LEFT' ? 'Left' : 'Right'} Leg Sessions',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      widget.user.name,
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
                          _selectedLeg == null 
                              ? '${sessions.length} total sessions logged locally in SQLite'
                              : '${filteredSessions.length} sessions logged for this leg',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.4),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (sessions.isEmpty)
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history_toggle_off, size: 48, color: Colors.black.withOpacity(0.15)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No sessions recorded yet for ${widget.user.name}.\nGo to "Start Live Session" to generate logs.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.black.withOpacity(0.35), height: 1.5, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_selectedLeg == null)
                          Expanded(
                            child: Column(
                              children: [
                                _LegSelectionCard(
                                  title: 'Left Leg Sessions',
                                  count: sessions.where((s) => s.label.toUpperCase().startsWith('LEFT')).length,
                                  color: AppColors.primary,
                                  onTap: () => setState(() => _selectedLeg = 'LEFT'),
                                ),
                                const SizedBox(height: 16),
                                _LegSelectionCard(
                                  title: 'Right Leg Sessions',
                                  count: sessions.where((s) => s.label.toUpperCase().startsWith('RIGHT')).length,
                                  color: AppColors.secondary,
                                  onTap: () => setState(() => _selectedLeg = 'RIGHT'),
                                ),
                              ],
                            ),
                          )
                        else
                          filteredSessions.isEmpty
                              ? Expanded(
                                  child: Center(
                                    child: Text(
                                      'No sessions found for this leg.',
                                      style: TextStyle(color: Colors.black.withOpacity(0.35), fontSize: 13),
                                    ),
                                  ),
                                )
                              : Expanded(
                                  child: ListView.separated(
                                    itemCount: filteredSessions.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final s = filteredSessions[index];
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
                                              'user': widget.user.toMap(),
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

class _LegSelectionCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _LegSelectionCard({
    required this.title,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$count sessions',
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios, color: color),
          ],
        ),
      ),
    );
  }
}
