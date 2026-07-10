import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:gait_physiotherapy_demo/core/router/app_router.dart';
import 'package:gait_physiotherapy_demo/features/checks/presentation/provider/check_provider.dart';

class HomePageChecks extends ConsumerStatefulWidget {
  const HomePageChecks({super.key});

  @override
  ConsumerState<HomePageChecks> createState() => _HomePageChecksState();
}

class _HomePageChecksState extends ConsumerState<HomePageChecks> {
  @override
  Widget build(BuildContext context) {
    final checkState = ref.watch(checkProvider);

    ref.listen(checkProvider, (prev, next) {
      if (next.isComplete && prev?.isComplete != true) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            context.goNamed(AppRoutes.home);
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          // Header
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: checkState.isComplete 
                            ? AppColors.success.withOpacity(0.4)
                            : AppColors.primary.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        checkState.isComplete ? Icons.check_circle : Icons.shield_outlined,
                        size: 60,
                        color: checkState.isComplete ? AppColors.success : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Startup Checks',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Validating device security, local models, and hardware capabilities.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 13.5,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Checklist
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CheckListItem(
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
                  _CheckListItem(
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
                  _CheckListItem(
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
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final CheckStatus status;
  final VoidCallback onFix;

  const _CheckListItem({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onFix,
  });

  @override
  Widget build(BuildContext context) {
    Widget trailing;
    switch (status) {
      case CheckStatus.pending:
        trailing = const Icon(Icons.circle_outlined, color: Colors.grey);
        break;
      case CheckStatus.loading:
        trailing = const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        );
        break;
      case CheckStatus.passed:
        trailing = const Icon(Icons.check_circle, color: AppColors.success);
        break;
      case CheckStatus.failed:
        trailing = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onFix,
          child: const Text('FIX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navy),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.5)),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
