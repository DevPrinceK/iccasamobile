import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/state/app_controller.dart';
import '../app_ui.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, required this.location, super.key});

  final Widget child;
  final String location;

  static const _items = [
    _NavItem(
      'Home',
      Icons.space_dashboard_outlined,
      Icons.space_dashboard_rounded,
      '/home',
    ),
    _NavItem(
      'Assignments',
      Icons.assignment_outlined,
      Icons.assignment_rounded,
      '/assignments',
    ),
    _NavItem(
      'Records',
      Icons.folder_copy_outlined,
      Icons.folder_copy_rounded,
      '/records',
    ),
    _NavItem(
      'Sync',
      Icons.cloud_sync_outlined,
      Icons.cloud_sync_rounded,
      '/sync',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final width = MediaQuery.sizeOf(context).width;
    final selectedIndex = _selectedIndex(location);
    final phone = width < AppBreakpoints.phone;
    final extended = width >= AppBreakpoints.wide;

    if (phone) {
      return Scaffold(
        appBar: _MobileTopBar(controller: controller),
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => context.go(_items[index].path),
          destinations: _items
              .map(
                (item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            minExtendedWidth: 236,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => context.go(_items[index].path),
            leading: _RailBrand(extended: extended),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (controller.user?.canReview ?? false)
                        _RailAction(
                          extended: extended,
                          icon: Icons.fact_check_outlined,
                          label: 'Review',
                          badge: controller.pendingReviewCount,
                          onTap: () => context.go('/review'),
                        ),
                      _RailAction(
                        extended: extended,
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        onTap: () => context.go('/settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            destinations: _items
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  ),
                )
                .toList(),
          ),
          VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
          Expanded(
            child: Column(
              children: [
                _DesktopTopBar(controller: controller),
                Divider(color: Theme.of(context).dividerColor),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _selectedIndex(String path) {
    final index = _items.indexWhere((item) => path.startsWith(item.path));
    return index < 0 ? 0 : index;
  }
}

class _MobileTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _MobileTopBar({required this.controller});

  final AppController controller;

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    titleSpacing: 16,
    title: const _CompactBrand(),
    actions: [
      _ConnectionButton(controller: controller),
      if (controller.user?.canReview ?? false)
        IconButton(
          tooltip: 'Review queue',
          onPressed: () => context.go('/review'),
          icon: Badge(
            isLabelVisible: controller.pendingReviewCount > 0,
            label: Text('${controller.pendingReviewCount}'),
            child: const Icon(Icons.fact_check_outlined),
          ),
        ),
      _AccountMenu(controller: controller),
      const SizedBox(width: 6),
    ],
  );
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 70,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Field collection workspace',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          _ConnectionButton(controller: controller, showLabel: true),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () => controller.setThemeMode(
              Theme.of(context).brightness == Brightness.dark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            ),
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: 4),
          _AccountMenu(controller: controller, showName: true),
        ],
      ),
    ),
  );
}

class _ConnectionButton extends StatelessWidget {
  const _ConnectionButton({required this.controller, this.showLabel = false});

  final AppController controller;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final online = controller.isOnline;
    final label = controller.isSyncing
        ? 'Syncing'
        : online
        ? controller.outbox.isEmpty
              ? 'Up to date'
              : '${controller.outbox.length} queued'
        : 'Offline';
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: controller.outbox.isNotEmpty && online
            ? controller.syncOutbox
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                controller.isSyncing
                    ? Icons.sync_rounded
                    : online
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                size: 20,
                color: online ? AppColors.emerald : AppColors.amber,
              ),
              if (showLabel) ...[
                const SizedBox(width: 7),
                Text(label, style: Theme.of(context).textTheme.labelLarge),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.controller, this.showName = false});

  final AppController controller;
  final bool showName;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Account menu',
    onSelected: (value) {
      if (value == 'settings') context.go('/settings');
      if (value == 'logout') controller.signOut();
    },
    itemBuilder: (context) => const [
      PopupMenuItem(
        value: 'settings',
        child: ListTile(
          leading: Icon(Icons.settings_outlined),
          title: Text('Settings'),
        ),
      ),
      PopupMenuDivider(),
      PopupMenuItem(
        value: 'logout',
        child: ListTile(
          leading: Icon(Icons.logout_rounded),
          title: Text('Sign out'),
        ),
      ),
    ],
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              controller.user?.name.characters.first.toUpperCase() ?? 'I',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (showName) ...[
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.user?.name ?? 'ICCASA user',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  controller.user?.roleLabel ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ],
      ),
    ),
  );
}

class _RailBrand extends StatelessWidget {
  const _RailBrand({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 26),
    child: extended
        ? const Row(
            children: [
              LogoMark(),
              SizedBox(width: 10),
              Text(
                'ICCASA Field',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          )
        : const LogoMark(),
  );
}

class _CompactBrand extends StatelessWidget {
  const _CompactBrand();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      LogoMark(size: 34),
      SizedBox(width: 9),
      Text(
        'ICCASA Field',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
    ],
  );
}

class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.emerald, AppColors.emeraldDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(size * 0.3),
    ),
    child: SizedBox(
      width: size,
      height: size,
      child: Icon(Icons.eco_rounded, color: Colors.white, size: size * 0.58),
    ),
  );
}

class _RailAction extends StatelessWidget {
  const _RailAction({
    required this.extended,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final bool extended;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: extended
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: badge > 0,
              label: Text('$badge'),
              child: Icon(icon),
            ),
            if (extended) ...[
              const SizedBox(width: 16),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    ),
  );
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.selectedIcon, this.path);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
}
