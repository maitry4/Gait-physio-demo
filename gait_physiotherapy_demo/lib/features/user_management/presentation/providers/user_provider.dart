import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_physiotherapy_demo/core/services/sqlite_service.dart';
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
      final db = await SQLiteService.database;
      final maps = await db.query('patients', orderBy: 'created_at DESC');
      final list = maps.map((map) {
        return UserModel(
          id: map['id'] as String,
          name: map['name'] as String,
          age: map['age'] as int,
          dateAdded: map['created_at'] as String,
        );
      }).toList();
      state = state.copyWith(users: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load users: $e');
    }
  }
  
  Future<List<UserModel>> getUsersForDevice(String deviceId) async {
    try {
      final db = await SQLiteService.database;
      // Get all patients that have at least one session with this device
      final maps = await db.rawQuery('''
        SELECT DISTINCT p.* 
        FROM patients p
        INNER JOIN sessions s ON p.id = s.patient_id
        WHERE s.device_id = ?
        ORDER BY p.created_at DESC
      ''', [deviceId]);
      return maps.map((map) {
        return UserModel(
          id: map['id'] as String,
          name: map['name'] as String,
          age: map['age'] as int,
          dateAdded: map['created_at'] as String,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  void selectUser(UserModel? user) {
    state = state.copyWith(selectedUser: user);
  }

  Future<bool> registerNewUser({
    required String name,
    required int age,
    required String id,

  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    await Future.delayed(const Duration(milliseconds: 1200));

    final newUser = UserModel(
      id: id.trim().isNotEmpty ? id.trim() : 'patient_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      age: age,
      dateAdded: DateTime.now().toIso8601String(),
    );

    try {
      final db = await SQLiteService.database;
      await db.insert(
        'patients',
        {
          'id': newUser.id,
          'name': newUser.name,
          'age': newUser.age,
          'created_at': newUser.dateAdded,
        },
      );
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
