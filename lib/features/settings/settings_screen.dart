import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/state/app_controller.dart';
import '../../design_system/app_ui.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    return AppPage(
      children: [
        const PageHeader(
          eyebrow: 'Account and device',
          title: 'Settings',
          subtitle:
              'Manage your field profile, accessibility preferences, local data and connection settings.',
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final account = Column(
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionTitle(title: 'Your account'),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _ProfileAvatar(controller: controller),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller.user?.name ?? 'ICCASA user',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  controller.user?.email ?? '',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 6),
                                StatusBadge(
                                  controller.user?.roleLabel ?? 'Field Agent',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: controller.isUpdatingProfilePhoto
                                ? null
                                : () =>
                                      _chooseProfilePhoto(context, controller),
                            icon: controller.isUpdatingProfilePhoto
                                ? const SizedBox.square(
                                    dimension: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add_a_photo_outlined),
                            label: Text(
                              controller.avatarUrl == null
                                  ? 'Add profile photo'
                                  : 'Change profile photo',
                            ),
                          ),
                          if (controller.avatarUrl != null)
                            TextButton.icon(
                              onPressed: controller.isUpdatingProfilePhoto
                                  ? null
                                  : () => _removeProfilePhoto(
                                      context,
                                      controller,
                                    ),
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Remove photo'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => _confirmSignOut(context, controller),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Sign out of this device'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionTitle(
                        title: 'Device data',
                        subtitle:
                            'Content stored for reliable offline collection',
                      ),
                      const SizedBox(height: 18),
                      _SettingRow(
                        icon: Icons.assignment_outlined,
                        title: 'Assigned forms',
                        value: '${controller.assignments.length}',
                      ),
                      _SettingRow(
                        icon: Icons.edit_note_rounded,
                        title: 'Local drafts',
                        value: '${controller.drafts.length}',
                      ),
                      _SettingRow(
                        icon: Icons.cloud_upload_outlined,
                        title: 'Queued records',
                        value: '${controller.outbox.length}',
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _confirmClear(context, controller),
                        icon: const Icon(Icons.cleaning_services_outlined),
                        label: const Text('Refresh cached workspace'),
                      ),
                    ],
                  ),
                ),
              ],
            );
            final preferences = Column(
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionTitle(
                        title: 'Appearance and accessibility',
                        subtitle: 'Preferences apply across the field app',
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Color theme',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto_outlined),
                            label: Text('System'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_outlined),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined),
                            label: Text('Dark'),
                          ),
                        ],
                        selected: {controller.themeMode},
                        onSelectionChanged: (value) =>
                            controller.setThemeMode(value.first),
                      ),
                      const SizedBox(height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('High contrast'),
                        subtitle: const Text(
                          'Strengthen borders and key interface colors.',
                        ),
                        value: controller.highContrast,
                        onChanged: controller.setHighContrast,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Text size',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          Text(
                            '${(controller.textScale * 100).round()}%',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                      Slider(
                        value: controller.textScale,
                        min: 0.9,
                        max: 1.3,
                        divisions: 4,
                        label: '${(controller.textScale * 100).round()}%',
                        onChanged: controller.setTextScale,
                      ),
                      Text(
                        'Preview: Climate action evidence',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionTitle(title: 'Connection and app'),
                      const SizedBox(height: 18),
                      _SettingRow(
                        icon: controller.isOnline
                            ? Icons.wifi_rounded
                            : Icons.wifi_off_rounded,
                        title: 'Connection',
                        value: controller.isOnline ? 'Online' : 'Offline',
                        valueColor: controller.isOnline
                            ? AppColors.emerald
                            : AppColors.amber,
                      ),
                      const _SettingRow(
                        icon: Icons.language_rounded,
                        title: 'Language',
                        value: 'English',
                      ),
                      const _SettingRow(
                        icon: Icons.info_outline_rounded,
                        title: 'App version',
                        value: AppConfig.appVersion,
                      ),
                      _SettingRow(
                        icon: Icons.phone_android_rounded,
                        title: 'Device ID',
                        value: controller.deviceId,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'API: ${AppConfig.apiUrl}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            if (!wide) {
              return Column(
                children: [account, const SizedBox(height: 18), preferences],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: account),
                const SizedBox(width: 20),
                Expanded(child: preferences),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _chooseProfilePhoto(
    BuildContext context,
    AppController controller,
  ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Profile photo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    final image = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1400,
      maxHeight: 1400,
      imageQuality: 88,
    );
    if (image == null) return;
    try {
      await controller.updateProfilePhoto(
        filename: image.name,
        bytes: await image.readAsBytes(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
      }
    } on ApiException catch (error) {
      if (context.mounted) _showProfileError(context, error.message);
    }
  }

  Future<void> _removeProfilePhoto(
    BuildContext context,
    AppController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.person_remove_outlined),
        title: const Text('Remove profile photo?'),
        content: const Text(
          'Your initials will be shown until you add another photo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove photo'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await controller.removeProfilePhoto();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile photo removed.')));
      }
    } on ApiException catch (error) {
      if (context.mounted) _showProfileError(context, error.message);
    }
  }

  void _showProfileError(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    AppController controller,
  ) async {
    if (controller.hasLocalWork) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded),
          title: const Text('Local work is still on this device'),
          content: Text(
            '${controller.drafts.length} draft(s) and ${controller.outbox.length} queued record(s) remain. They are preserved locally, but sign in with the same account to access them again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay signed in'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign out'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    await controller.signOut();
  }

  Future<void> _confirmClear(
    BuildContext context,
    AppController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.cleaning_services_outlined),
        title: const Text('Refresh cached workspace?'),
        content: const Text(
          'This removes downloaded forms, drafts and queued records from this device, then reloads server data. Sync or finish local work first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: controller.hasLocalWork
                ? null
                : () => Navigator.pop(context, true),
            child: const Text('Refresh cache'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.clearCachedOperationalData();
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final image = controller.avatarUrl == null
        ? null
        : NetworkImage(
            controller.avatarUrl!,
            headers: controller.avatarHeaders,
          );
    return CircleAvatar(
      radius: 31,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundImage: image,
      child: image == null
          ? Text(
              controller.user?.name.characters.first.toUpperCase() ?? 'I',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 21),
        const SizedBox(width: 12),
        Expanded(child: Text(title)),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: valueColor),
        ),
      ],
    ),
  );
}
