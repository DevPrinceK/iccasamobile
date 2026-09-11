import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../design_system/app_ui.dart';
import 'assignment_card.dart';

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  final _searchController = TextEditingController();
  String _filter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    final query = _searchController.text.trim().toLowerCase();
    final filtered = controller.assignments.where((assignment) {
      final draft = controller.drafts.any(
        (item) => item.formId == assignment.id,
      );
      final matchesFilter =
          _filter == 'All' ||
          (_filter == 'In progress' && draft) ||
          (_filter == 'Not started' && !draft);
      final matchesQuery =
          query.isEmpty ||
          assignment.name.toLowerCase().contains(query) ||
          assignment.description.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
    return AppPage(
      onRefresh: controller.refreshAll,
      children: [
        PageHeader(
          eyebrow: 'Field collection',
          title: 'Assignments',
          subtitle:
              'Open an assigned form, review its requirements and collect data online or offline.',
          actions: [
            OutlinedButton.icon(
              onPressed: controller.isRefreshing ? null : controller.refreshAll,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SectionCard(
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search assigned forms',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['All', 'In progress', 'Not started']
                      .map(
                        (filter) => ChoiceChip(
                          label: Text(filter),
                          selected: _filter == filter,
                          labelStyle:
                              Theme.of(context).brightness == Brightness.light
                              ? TextStyle(
                                  color: _filter == filter
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                )
                              : null,
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text(
              '${filtered.length} form${filtered.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            if (!controller.isOnline)
              const StatusBadge(
                'Available offline',
                icon: Icons.offline_bolt_rounded,
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          EmptyState(
            icon: Icons.assignment_late_outlined,
            title: query.isEmpty
                ? 'No forms in this view'
                : 'No matching forms',
            message: query.isEmpty
                ? 'New collection forms appear here after an ICCASA manager assigns them to your account.'
                : 'Try a different search term or filter.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1120
                  ? 3
                  : constraints.maxWidth >= 650
                  ? 2
                  : 1;
              final cardWidth =
                  (constraints.maxWidth - (14 * (columns - 1))) / columns;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: filtered.map((assignment) {
                  final draft = controller.drafts
                      .where((item) => item.formId == assignment.id)
                      .firstOrNull;
                  return SizedBox(
                    width: cardWidth,
                    child: AssignmentCard(
                      assignment: assignment,
                      draft: draft,
                      onOpen: () => context.go('/assignments/${assignment.id}'),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}
