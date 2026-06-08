import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gait_physiotherapy_demo/core/router/app_router.dart';
import 'package:gait_physiotherapy_demo/features/user_management/presentation/providers/user_provider.dart';
import 'package:gait_physiotherapy_demo/features/user_management/presentation/widgets/user_tile.dart';
import 'package:gait_physiotherapy_demo/features/view_session/presentation/providers/view_session_provider.dart';

enum SelectUserMode { viewSession, startSession }

class Screen51SelectUser extends ConsumerStatefulWidget {
  final SelectUserMode mode;

  const Screen51SelectUser({super.key, required this.mode});

  @override
  ConsumerState<Screen51SelectUser> createState() => _Screen51SelectUserState();
}

class _Screen51SelectUserState extends ConsumerState<Screen51SelectUser> {
  bool _forceSyncFailure = false;

  void _onUserSelected(BuildContext context, WidgetRef ref, dynamic user) {
    ref.read(userProvider.notifier).selectUser(user);

    if (widget.mode == SelectUserMode.startSession) {
      context.pushNamed(
        AppRoutes.sessionConfirmation,
        extra: {'user': user},
      );
    } else {
      // Load sessions for user
      ref.read(viewSessionProvider.notifier).loadSessionsForUser(user.id);
      context.pushNamed(
        AppRoutes.sessionList,
        extra: {'user': user},
      );
    }
  }

  void _triggerForceSync(BuildContext context, WidgetRef ref) async {
    final activeUser = ref.read(userProvider).selectedUser;
    if (activeUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient first to run background synchronization.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    final notifier = ref.read(viewSessionProvider.notifier);
    final success = await notifier.forceFetchSessionsFromDevice(
      activeUser.id,
      simulateFailure: _forceSyncFailure,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully synced missing sessions for ${activeUser.name} from wearable!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final error = ref.read(viewSessionProvider).errorMessage ?? 'Sync failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final sessionState = ref.watch(viewSessionProvider);
    final activeUser = userState.selectedUser;

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
                        // Force Sync button (only for View Session mode to pull offline)
                        if (widget.mode == SelectUserMode.viewSession)
                          sessionState.isSyncingFromDevice
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                                )
                              : Row(
                                  children: [
                                    Checkbox(
                                      value: _forceSyncFailure,
                                      activeColor: AppColors.primary,
                                      onChanged: (val) {
                                        setState(() {
                                          _forceSyncFailure = val ?? false;
                                        });
                                      },
                                    ),
                                    const Text('Simulate Error', style: TextStyle(color: Colors.white, fontSize: 10)),
                                    const SizedBox(width: 4),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        backgroundColor: AppColors.primary.withOpacity(0.2),
                                        foregroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        minimumSize: Size.zero,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () => _triggerForceSync(context, ref),
                                      icon: const Icon(Icons.sync, size: 14),
                                      label: const Text('Pull Wearable', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.mode == SelectUserMode.startSession ? 'Gait Recording' : 'Patient History',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'Select Patient',
                      style: TextStyle(
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

          // ── Patients List ─────────────────────────────────────────────
          Expanded(
            child: userState.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${userState.users.length} patients registered locally',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.4),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        userState.users.isEmpty
                            ? Expanded(
                                child: Center(
                                  child: Text(
                                    'No patients added yet. Add a user from the dashboard menu first.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.black.withOpacity(0.35), height: 1.5),
                                  ),
                                ),
                              )
                            : Expanded(
                                child: ListView.separated(
                                  itemCount: userState.users.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final u = userState.users[index];
                                    final isSelected = activeUser?.id == u.id;
                                    return UserTile(
                                      name: u.name,
                                      age: u.age,
                                      id: u.id,
                                      date: u.dateAdded,
                                      isSelected: isSelected,
                                      onTap: () => _onUserSelected(context, ref, u),
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
