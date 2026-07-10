import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_physiotherapy_demo/core/router/app_routes.dart';
import 'package:go_router/go_router.dart';

import 'package:gait_physiotherapy_demo/core/router/app_router.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:gait_physiotherapy_demo/features/connectivity/presentation/providers/connectivity_provider.dart';
import 'package:gait_physiotherapy_demo/features/home/presentation/widgets/dashboard_grid.dart';
import 'package:gait_physiotherapy_demo/features/home/presentation/widgets/dashboard_header.dart';
import 'package:gait_physiotherapy_demo/features/session/presentation/providers/session_provider.dart';
import 'package:gait_physiotherapy_demo/features/user_management/domain/entities/user_entity.dart';
import 'package:gait_physiotherapy_demo/features/user_management/presentation/providers/user_provider.dart';
class Screen4HomeMenu extends ConsumerWidget {
  final String deviceName;

  const Screen4HomeMenu({
    super.key,
    required this.deviceName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.pushNamed(AppRoutes.settings),
        child: const Icon(
          Icons.settings,
          color: Colors.white,
        ),
      ),
      body: Column(
        children: [
          DashboardHeader(
            deviceName: deviceName,
          ),
          Expanded(
            child: DashboardGrid(
              sessionState: sessionState,
              activeUser: activeUser,
            ),
          ),
        ],
      ),
    );
  }
}