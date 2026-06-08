import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_physiotherapy_demo/core/database/database_service.dart';
import 'package:gait_physiotherapy_demo/features/user_management/domain/entities/user_entity.dart';

class UserState {
  final List<UserModel> users;
  final UserModel? selectedUser;
  final bool isLoading;
  final String? errorMessage;

  UserState({
    this.users = const [],
    this.selectedUser,
    this.isLoading = false,
    this.errorMessage,
  });

  UserState copyWith({
    List<UserModel>? users,
    UserModel? selectedUser,
    bool? isLoading,
    String? errorMessage,
  }) {
    return UserState(
      users: users ?? this.users,
      selectedUser: selectedUser ?? this.selectedUser,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class UserNotifier extends Notifier<UserState> {
  @override
  UserState build() {
    Future.microtask(() => loadUsers());
    return UserState();
  }

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await DatabaseService.instance.getUsers();
      state = state.copyWith(users: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load users: $e');
    }
  }

  void selectUser(UserModel? user) {
    state = state.copyWith(selectedUser: user);
  }

  Future<bool> registerNewUser({
    required String name,
    required int age,
    required String id,
    bool simulateDeviceFailure = false,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Simulate sending data to the wearable device
    await Future.delayed(const Duration(milliseconds: 1200));

    if (simulateDeviceFailure) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Wearable Sync Failed: Device did not confirm patient storage. Tap retry.',
      );
      return false;
    }

    // Success -> Store on wearable completed. Create on mobile SQLite DB.
    final newUser = UserModel(
      id: id.trim().isNotEmpty ? id.trim() : 'PT-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      age: age,
      dateAdded: DateTime.now().toIso8601String().substring(0, 10),
    );

    try {
      await DatabaseService.instance.insertUser(newUser);
      await loadUsers();
      state = state.copyWith(selectedUser: newUser, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Database Error: $e');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(() {
  return UserNotifier();
});
