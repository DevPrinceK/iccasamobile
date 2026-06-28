import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/session_controller.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final controller = ref.read(sessionControllerProvider.notifier);
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 720;

    if (!useRail) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ICCASA Field'),
          actions: [_NetworkButton(session.isOnline, controller.toggleNetwork)],
        ),
        body: child,
        bottomNavigationBar: _BottomNav(),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: width >= 1040,
            selectedIndex: _selectedIndex(context),
            onDestinationSelected: (index) => context.go(_paths[index]),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Text(
                  'IC',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _NetworkButton(
                    session.isOnline,
                    controller.toggleNetwork,
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment),
                label: Text('Assignments'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: Text('Records'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.sync_outlined),
                selectedIcon: Icon(Icons.sync),
                label: Text('Sync'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.fact_check_outlined),
                selectedIcon: Icon(Icons.fact_check),
                label: Text('Review'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedIndex(context).clamp(0, 4),
      onDestinationSelected: (index) => context.go(_paths[index]),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          label: 'Work',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_outlined),
          label: 'Records',
        ),
        NavigationDestination(icon: Icon(Icons.sync_outlined), label: 'Sync'),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: 'Settings',
        ),
      ],
    );
  }
}

class _NetworkButton extends StatelessWidget {
  const _NetworkButton(this.isOnline, this.onPressed);

  final bool isOnline;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isOnline ? 'Online' : 'Offline demo mode',
      child: IconButton.filledTonal(
        onPressed: onPressed,
        icon: Icon(isOnline ? Icons.wifi : Icons.wifi_off),
      ),
    );
  }
}

const _paths = [
  '/home',
  '/assignments',
  '/records',
  '/sync',
  '/supervisor',
  '/settings',
];

int _selectedIndex(BuildContext context) {
  final location = GoRouterState.of(context).uri.path;
  final index = _paths.indexWhere((path) => location.startsWith(path));
  return index == -1 ? 0 : index;
}
