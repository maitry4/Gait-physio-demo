import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_physiotherapy_demo/features/checks/presentation/startup_check.dart';
import 'package:gait_physiotherapy_demo/features/configuration/presentation/pages/credentials_page.dart';
import 'package:gait_physiotherapy_demo/features/configuration/presentation/pages/device_list_page.dart';
import 'package:gait_physiotherapy_demo/features/home/presentation/dashboard.dart';
import 'package:go_router/go_router.dart';
import 'package:gait_physiotherapy_demo/core/router/app_routes.dart';



final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/checks',
    routes: [
      GoRoute(
        path: '/checks',
        name: AppRoutes.checks,
        builder: (context, state) => const StartupCheck(),
      ),
      GoRoute(
        path: '/credentials',
        name: AppRoutes.credentials,
        builder: (context, state) => const CredentialsPage(),
      ),
      GoRoute(
        path: '/device-list',
        name: AppRoutes.deviceList,
        builder: (context, state) => const DeviceListPage(),
      ),
      GoRoute(
        path: '/connecting',
        name: AppRoutes.connecting,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return Screen3Connecting(
            deviceName: extra['deviceName'] as String,
            deviceId: extra['deviceId'] as String,
          );
        },
      ),
      GoRoute(
        path: '/home',
        name: AppRoutes.home,
        builder: (context, state) {
          return DashBoardPage();
        },
      ),
      GoRoute(
        path: '/select-user',
        name: AppRoutes.selectUser,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return Screen51SelectUser(
            mode: extra['mode'] as SelectUserMode,
          );
        },
      ),
      GoRoute(
        path: '/session-confirmation',
        name: AppRoutes.sessionConfirmation,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return Screen53SessionConfirmation(
            user: extra['user'] as UserModel,
          );
        },
      ),
      GoRoute(
        path: '/live-session',
        name: AppRoutes.liveSession,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return Screen5NewSession(
            user: extra['user'] as UserModel,
          );
        },
      ),
      GoRoute(
        path: '/analysis-processing',
        name: AppRoutes.analysisProcessing,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return Screen54AnalysisProcessing(
            user: extra['user'] as UserModel,
          );
        },
      ),
      GoRoute(
        path: '/session-list',
        name: AppRoutes.sessionList,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return Screen611SessionList(
            user: extra['user'] as UserModel,
          );
        },
      ),
      GoRoute(
        path: '/overall-progress',
        name: AppRoutes.overallProgress,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return Screen612OverallProgress(
            user: extra['user'] as UserModel,
            sessions: extra['sessions'] as List<SessionModel>,
          );
        },
      ),
      GoRoute(
        path: '/session-analysis',
        name: AppRoutes.sessionAnalysis,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return Screen613SessionAnalysis(
            session: extra['session'] as Map<String, dynamic>,
            user: extra['user'] as Map<String, dynamic>,
          );
        },
      ),
      GoRoute(
        path: '/add-user',
        name: AppRoutes.addUser,
        builder: (context, state) => const Screen52AddNewUser(),
      ),
      GoRoute(
        path: '/therapist-pdf',
        name: AppRoutes.therapistPdf,
        builder: (context, state) => const Screen8TherapistPdf(),
      ),
      GoRoute(
        path: '/settings',
        name: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});