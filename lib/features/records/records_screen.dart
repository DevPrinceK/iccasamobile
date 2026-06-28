import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/session_controller.dart';
import '../../design_system/components/section_panel.dart';
import '../../design_system/components/status_badge.dart';

class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(demoRepositoryProvider).records;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionPanel(
          title: 'Offline Record Search',
          child: const TextField(
            decoration: InputDecoration(
              hintText: 'Search name, ID, phone, community, status',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        const SizedBox(height: 18),
        for (final record in records)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                minVerticalPadding: 18,
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(record.name),
                subtitle: Text(
                  '${record.reference} • ${record.phone}\n'
                  '${record.location} • ${record.lastVisit}',
                ),
                isThreeLine: true,
                trailing: StatusBadge.assignment(record.status),
              ),
            ),
          ),
      ],
    );
  }
}
