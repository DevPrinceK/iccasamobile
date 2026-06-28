import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/session_controller.dart';
import '../../design_system/components/section_panel.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final controller = ref.read(sessionControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionPanel(
          title: 'Device Diagnostics',
          child: Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: session.isOnline,
                  onChanged: (_) => controller.toggleNetwork(),
                  secondary: const Icon(Icons.wifi),
                  title: const Text('Network available'),
                  subtitle: const Text('Demo toggle for online/offline flows'),
                ),
                ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: const Text('Secure storage'),
                  subtitle: const Text(
                    'Token and device key integration pending',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: const Text('Encrypted offline database'),
                  subtitle: const Text('Drift or Isar implementation pending'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  onTap: controller.signOut,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
