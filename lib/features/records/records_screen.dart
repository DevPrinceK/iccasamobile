import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/field_models.dart';
import '../../core/state/app_controller.dart';
import '../../design_system/app_ui.dart';

class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  final _searchController = TextEditingController();
  String _status = 'All';
  int _page = 0;
  static const _pageSize = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    final query = _searchController.text.trim().toLowerCase();
    final filtered = controller.submissions.where((record) {
      final name = record.formName ?? controller.formName(record.formId);
      final statusMatches = _status == 'All' || record.status == _status;
      final searchMatches =
          query.isEmpty ||
          name.toLowerCase().contains(query) ||
          record.id.toLowerCase().contains(query) ||
          record.data.values.any(
            (value) => value.toString().toLowerCase().contains(query),
          );
      return statusMatches && searchMatches;
    }).toList();
    final totalPages = (filtered.length / _pageSize).ceil().clamp(1, 9999);
    if (_page >= totalPages) _page = totalPages - 1;
    final pageItems = filtered.skip(_page * _pageSize).take(_pageSize).toList();
    return AppPage(
      onRefresh: controller.refreshAll,
      children: [
        const PageHeader(
          eyebrow: 'Collection history',
          title: 'Records',
          subtitle:
              'Find submitted records, track review outcomes and revisit anything returned for correction.',
        ),
        const SizedBox(height: 24),
        SectionCard(
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() => _page = 0),
                decoration: InputDecoration(
                  hintText: 'Search by form, record ID or response',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _page = 0);
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        [
                              'All',
                              'pending_review',
                              'accepted',
                              'rejected',
                              'queued',
                            ]
                            .map(
                              (status) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    status == 'All'
                                        ? status
                                        : status.replaceAll('_', ' '),
                                  ),
                                  selected: _status == status,
                                  labelStyle:
                                      Theme.of(context).brightness ==
                                          Brightness.light
                                      ? TextStyle(
                                          color: _status == status
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.onPrimaryContainer
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                        )
                                      : null,
                                  onSelected: (_) => setState(() {
                                    _status = status;
                                    _page = 0;
                                  }),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text(
              '${filtered.length} record${filtered.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            if (controller.outbox.isNotEmpty)
              StatusBadge(
                '${controller.outbox.length} queued',
                icon: Icons.cloud_upload_outlined,
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (pageItems.isEmpty)
          EmptyState(
            icon: Icons.folder_off_outlined,
            title: query.isEmpty
                ? 'No records in this view'
                : 'No records found',
            message: query.isEmpty
                ? 'Records will appear here after you submit collection forms.'
                : 'Try a different search term or status filter.',
            action: query.isEmpty
                ? FilledButton(
                    onPressed: () => context.go('/assignments'),
                    child: const Text('Open assignments'),
                  )
                : null,
          )
        else
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ...pageItems.indexed.map(
                  (entry) => Column(
                    children: [
                      _RecordRow(record: entry.$2, controller: controller),
                      if (entry.$1 != pageItems.length - 1) const Divider(),
                    ],
                  ),
                ),
                if (totalPages > 1) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Page ${_page + 1} of $totalPages',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          tooltip: 'Previous page',
                          onPressed: _page == 0
                              ? null
                              : () => setState(() => _page--),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        IconButton(
                          tooltip: 'Next page',
                          onPressed: _page >= totalPages - 1
                              ? null
                              : () => setState(() => _page++),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record, required this.controller});

  final SubmissionRecord record;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 670;
    final name = record.formName ?? controller.formName(record.formId);
    return InkWell(
      onTap: () => _showRecord(context, record, controller),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: statusColor(
                record.status,
                Theme.of(context).colorScheme,
              ).withValues(alpha: 0.12),
              child: Icon(
                Icons.description_outlined,
                color: statusColor(
                  record.status,
                  Theme.of(context).colorScheme,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Record ${record.id}  |  ${humanDate(record.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (compact) ...[
                    const SizedBox(height: 9),
                    StatusBadge(record.status),
                  ],
                ],
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 12),
              StatusBadge(record.status),
            ],
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

Future<void> _showRecord(
  BuildContext context,
  SubmissionRecord record,
  AppController controller,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 760),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Record ${record.id}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record.formName ?? controller.formName(record.formId),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(record.status),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      StatusBadge(
                        humanDate(record.createdAt),
                        icon: Icons.schedule_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      StatusBadge(
                        'Form ${record.formId}',
                        icon: Icons.assignment_outlined,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Collected responses',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...record.data.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _label(entry.key),
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _displayValue(entry.value),
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (record.reviewNote != null &&
                      record.reviewNote!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    MessageBanner(
                      message: 'Reviewer note: ${record.reviewNote}',
                      warning: record.status != 'rejected',
                    ),
                  ],
                ],
              ),
            ),
            if (record.status == 'rejected') ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final assignment = controller.assignmentById(
                        record.formId,
                      );
                      if (assignment == null) return;
                      final draft = controller.beginDraft(assignment);
                      await controller.updateDraft(draft.id, record.data);
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      if (context.mounted) {
                        context.go(
                          '/collect/${record.formId}?draft=${draft.id}',
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Correct and resubmit'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

String _label(String value) => value
    .split('_')
    .map(
      (part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' ');

String _displayValue(dynamic value) {
  if (value == null) return 'Not provided';
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is Map) {
    if (value['latitude'] != null) {
      return '${value['latitude']}, ${value['longitude']}';
    }
    if (value['filename'] != null) return value['filename'].toString();
    return value.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
  }
  if (value is Iterable) return value.join(', ');
  return value.toString();
}
