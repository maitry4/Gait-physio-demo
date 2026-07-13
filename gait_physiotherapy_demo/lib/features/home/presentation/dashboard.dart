import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_physiotherapy_demo/core/router/app_routes.dart';
import 'package:gait_physiotherapy_demo/features/configuration/presentation/provider/connectivity_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:gait_physiotherapy_demo/features/home/presentation/widgets/dashboard_grid.dart';
import 'package:gait_physiotherapy_demo/features/home/presentation/widgets/dashboard_header.dart';

class DashBoardPage extends ConsumerWidget {
  const DashBoardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final deviceName =
        connectivity.connectedDeviceName ?? "No Device Connected";

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
          DashboardHeader(),
          Expanded(
            child: DashboardGrid(),
          ),
        ],
      ),
    );
  }
}