import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/session_provider.dart';
import 'screen5_3_session_confirmation.dart';
import 'screen6_1_1_session_list.dart';

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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Screen53SessionConfirmation(user: user),
        ),
      );
    } else {
      // Load sessions for user
      ref.read(sessionProvider.notifier).loadSessionsForUser(user.id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Screen611SessionList(user: user),
        ),
      );
    }
  }

  void _triggerForceSync(BuildContext context, WidgetRef ref) async {
    final activeUser = ref.read(userProvider).selectedUser;
    if (activeUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient first to run background synchronization.'),
          backgroundColor: Color(0xFFFF4E6A),
        ),
      );
      return;
    }

    final notifier = ref.read(sessionProvider.notifier);
    final success = await notifier.forceFetchSessionsFromDevice(
      activeUser.id,
      simulateFailure: _forceSyncFailure,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully synced missing sessions for ${activeUser.name} from wearable!'),
          backgroundColor: const Color(0xFF00C48C),
        ),
      );
    } else {
      final error = ref.read(sessionProvider).errorMessage ?? 'Sync failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFFF4E6A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final sessionState = ref.watch(sessionProvider);
    final activeUser = userState.selectedUser;

    return Scaffold(
      body: Column(
        children: [
          // ── Dark Header ───────────────────────────────────────────────
          Container(
            width: double.infinity,
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
                                  child: CircularProgressIndicator(color: Color(0xFFFF4E6A), strokeWidth: 2),
                                )
                              : Row(
                                  children: [
                                    Checkbox(
                                      value: _forceSyncFailure,
                                      activeColor: const Color(0xFFFF4E6A),
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
                                        backgroundColor: const Color(0xFFFF4E6A).withOpacity(0.2),
                                        foregroundColor: const Color(0xFFFF4E6A),
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
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4E6A)))
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
                                    return _PatientTile(
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

class _PatientTile extends StatelessWidget {
  final String name;
  final int age;
  final String id;
  final String date;
  final bool isSelected;
  final VoidCallback onTap;

  const _PatientTile({
    required this.name,
    required this.age,
    required this.id,
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1D2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF4E6A) : Colors.transparent,
            width: 2,
          ),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF4E6A).withOpacity(0.15) : const Color(0xFF1A1D2E).withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFFF4E6A) : const Color(0xFF1A1D2E),
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF1A1D2E),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Age: $age  ·  ID: $id',
                    style: TextStyle(
                      color: isSelected ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.chevron_right, color: isSelected ? const Color(0xFFFF4E6A) : Colors.black.withOpacity(0.2), size: 20),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    color: isSelected ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.25),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}