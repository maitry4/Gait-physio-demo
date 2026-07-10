import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_physiotherapy_demo/core/router/app_routes.dart';
import 'package:gait_physiotherapy_demo/features/checks/presentation/provider/check_provider.dart';
import 'package:gait_physiotherapy_demo/features/checks/presentation/widgets/check_list_item.dart';
import 'package:go_router/go_router.dart';

class ChecksList extends ConsumerWidget {
  final CheckState checkState;

  const ChecksList({
    super.key,
    required this.checkState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return  Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CheckListItem(
                    title: 'Hotspot Credentials',
                    subtitle: 'Secure Storage Key Check',
                    status: checkState.storageCheck,
                    onFix: () {
                      context.pushNamed(AppRoutes.credentials).then((_) {
                        ref.read(checkProvider.notifier).runChecks();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  CheckListItem(
                    title: 'SLM Preferences',
                    subtitle: 'Local Hive DB State',
                    status: checkState.hiveCheck,
                    onFix: () {
                      context.pushNamed(AppRoutes.settings).then((_) {
                        ref.read(checkProvider.notifier).runChecks();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  CheckListItem(
                    title: 'Hardware Validation',
                    subtitle: 'Bluetooth & Mobile AP',
                    status: checkState.hardwareCheck,
                    onFix: () {
                      context.pushNamed(AppRoutes.connectivity).then((_) {
                        ref.read(checkProvider.notifier).runChecks();
                      });
                    },
                  ),
                ],
              ),
            );
  }
}