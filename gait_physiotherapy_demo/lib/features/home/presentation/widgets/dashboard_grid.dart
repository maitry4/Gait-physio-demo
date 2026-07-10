import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/core/router/app_routes.dart';
import 'package:go_router/go_router.dart';

import 'package:gait_physiotherapy_demo/core/router/app_router.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:gait_physiotherapy_demo/features/home/presentation/widgets/grid_card.dart';
import 'package:gait_physiotherapy_demo/features/home/presentation/widgets/workflow_card.dart';
import 'package:gait_physiotherapy_demo/features/session/presentation/providers/session_provider.dart';
import 'package:gait_physiotherapy_demo/features/user_management/domain/entities/user_entity.dart';
import 'package:gait_physiotherapy_demo/features/user_management/presentation/screens/select_user_screen.dart';

class DashboardGrid extends StatelessWidget {
  final SessionState sessionState;
  final UserModel? activeUser;

  const DashboardGrid({
    super.key,
    required this.sessionState,
    required this.activeUser,
  });

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildActiveSessionCard(
    BuildContext context,
    UserModel user,
  ) {
    final durationStr = _formatDuration(sessionState.recordDurationSeconds);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryGradientStart,
            AppColors.primaryDeep,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
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
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer,
                      color: Colors.white,
                      size: 12,
                    ),
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
              context.pushNamed(
                AppRoutes.liveSession,
                extra: {
                  'user': user,
                },
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
                    Icon(
                      Icons.directions_run,
                      color: AppColors.primaryDeep,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Resume Live Tracking',
                      style: TextStyle(
                        color: AppColors.primaryDeep,
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
  Widget build(BuildContext context) {
    final isRecording = sessionState.isRecording;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRecording && activeUser != null) ...[
            _buildActiveSessionCard(context, activeUser!),
            const SizedBox(height: 20),
          ],

          const Text(
            'Clinical Workflows',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 14),

          WorkflowCard(
            title: 'Start Live Session',
            subtitle: 'Capture sensor metrics from gait band',
            icon: Icons.play_circle_outline,
            color: AppColors.primary,
            isPrimary: true,
            onTap: () => context.pushNamed(
              AppRoutes.selectUser,
              extra: {
                'mode': SelectUserMode.startSession,
              },
            ),
          ),

          const SizedBox(height: 32),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              GridCard(
                title: 'View Sessions',
                icon: Icons.history,
                color: AppColors.secondary,
                onTap: () => context.pushNamed(
                  AppRoutes.selectUser,
                  extra: {
                    'mode': SelectUserMode.viewSession,
                  },
                ),
              ),
              GridCard(
                title: 'Add New User',
                icon: Icons.person_add_outlined,
                color: AppColors.warning,
                onTap: () => context.pushNamed(
                  AppRoutes.addUser,
                ),
              ),
              GridCard(
                title: 'Get Report PDF',
                icon: Icons.picture_as_pdf_outlined,
                color: AppColors.pdf,
                onTap: () => context.pushNamed(
                  AppRoutes.therapistPdf,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}