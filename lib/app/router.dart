import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/state/session_controller.dart';
import '../features/assignments/assignments_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/records/records_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/supervisor/supervisor_screen.dart';
import '../features/sync_center/sync_center_screen.dart';
import '../design_system/components/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionControllerProvider);

  return GoRouter(
    initialLocation: session.isAuthenticated ? '/home' : '/login',
    redirect: (context, state) {
      final loggingIn = state.uri.path == '/login';
      if (!session.isAuthenticated && !loggingIn) {
        return '/login';
      }
      if (session.isAuthenticated && loggingIn) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                _fadePage(state, const DashboardScreen()),
          ),
          GoRoute(
            path: '/assignments',
            pageBuilder: (context, state) =>
                _fadePage(state, const AssignmentsScreen()),
          ),
          GoRoute(
            path: '/records',
            pageBuilder: (context, state) =>
                _fadePage(state, const RecordsScreen()),
          ),
          GoRoute(
            path: '/sync',
            pageBuilder: (context, state) =>
                _fadePage(state, const SyncCenterScreen()),
          ),
          GoRoute(
            path: '/supervisor',
            pageBuilder: (context, state) =>
                _fadePage(state, const SupervisorScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                _fadePage(state, const SettingsScreen()),
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.02, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      );
    },
  );
}
