import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/core/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:gait_physiotherapy_demo/features/home/presentation/widgets/grid_card.dart';
import 'package:gait_physiotherapy_demo/features/home/presentation/widgets/workflow_card.dart';

enum SelectUserMode { viewSession, startSession }

class DashboardGrid extends StatelessWidget {

  const DashboardGrid({
    super.key,
  });


  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          

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