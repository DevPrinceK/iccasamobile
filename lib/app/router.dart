import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/models/field_models.dart';
import '../core/state/app_controller.dart';
import '../design_system/components/app_shell.dart';
import '../features/assignments/assignment_detail_screen.dart';
import '../features/assignments/assignments_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/collection/collection_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/records/records_screen.dart';
import '../features/review/review_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/sync_center/sync_center_screen.dart';

GoRouter createAppRouter(AppController controller) => GoRouter(
  initialLocation: '/launch',
  refreshListenable: controller,
  redirect: (context, state) {
    final location = state.matchedLocation;
    if (controller.stage == AppStage.booting) {
      return location == '/launch' ? null : '/launch';
    }
    if (controller.stage == AppStage.signedOut) {
      return location == '/login' ? null : '/login';
    }
    if (location == '/login' || location == '/launch' || location == '/') {
      return '/home';
    }
    if (location == '/review' && !(controller.user?.canReview ?? false)) {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/launch'),
    GoRoute(path: '/launch', builder: (context, state) => const LaunchScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/assignments',
          builder: (context, state) => const AssignmentsScreen(),
          routes: [
            GoRoute(
              path: ':formId',
              builder: (context, state) => AssignmentDetailScreen(
                formId: int.tryParse(state.pathParameters['formId'] ?? '') ?? 0,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/records',
          builder: (context, state) => const RecordsScreen(),
        ),
        GoRoute(
          path: '/sync',
          builder: (context, state) => const SyncCenterScreen(),
        ),
        GoRoute(
          path: '/review',
          builder: (context, state) => const ReviewScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/collect/:formId',
      builder: (context, state) => CollectionScreen(
        formId: int.tryParse(state.pathParameters['formId'] ?? '') ?? 0,
        draftId: state.uri.queryParameters['draft'],
      ),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore_off_outlined, size: 48),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.error?.toString() ?? 'This page is unavailable.'),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('Back to home'),
            ),
          ],
        ),
      ),
    ),
  ),
);

class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandLogo(width: 190),
          SizedBox(height: 20),
          Text(
            'ICCASA Field',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 22),
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ],
      ),
    ),
  );
}
