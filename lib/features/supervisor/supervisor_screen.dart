import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/session_controller.dart';
import '../../design_system/components/section_panel.dart';
import '../../design_system/components/status_badge.dart';

class SupervisorScreen extends ConsumerWidget {
  const SupervisorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignments = ref.watch(demoRepositoryProvider).assignments;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionPanel(
          title: 'Supervisor Review',
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final assignment in assignments)
                SizedBox(
                  width: 340,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  assignment.personName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              StatusBadge.assignment(assignment.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(assignment.task),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.undo),
                                  label: const Text('Return'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.check),
                                  label: const Text('Approve'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
