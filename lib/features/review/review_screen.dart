import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/models/field_models.dart';
import '../../core/network/api_client.dart';
import '../../core/state/app_controller.dart';
import '../../design_system/app_ui.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    final query = _searchController.text.trim().toLowerCase();
    final records = controller.submissions.where((item) {
      final name = controller.formName(item.formId);
      return item.isAwaitingReview &&
          (query.isEmpty ||
              name.toLowerCase().contains(query) ||
              item.id.contains(query));
    }).toList();
    return AppPage(
      onRefresh: controller.refreshAll,
      children: [
        PageHeader(
          eyebrow: 'Quality assurance',
          title: 'Review queue',
          subtitle:
              'Inspect submitted field evidence, record a decision and return clear correction notes where needed.',
          actions: [
            StatusBadge(
              '${records.length} pending',
              icon: Icons.fact_check_outlined,
              color: AppColors.amber,
            ),
          ],
        ),
        const SizedBox(height: 24),
        SectionCard(
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search pending submissions',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (records.isEmpty)
          const EmptyState(
            icon: Icons.task_alt_rounded,
            title: 'Review queue is clear',
            message:
                'New field submissions will appear here when they are ready for quality review.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1050
                  ? 3
                  : constraints.maxWidth >= 640
                  ? 2
                  : 1;
              return GridView.builder(
                itemCount: records.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: columns == 1
                      ? 1.75
                      : columns == 2
                      ? 1.55
                      : 1.25,
                ),
                itemBuilder: (context, index) =>
                    _ReviewCard(record: records[index], controller: controller),
              );
            },
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.record, required this.controller});

  final SubmissionRecord record;
  final AppController controller;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _openReview(context, record, controller),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const StatusBadge(
                  'Pending review',
                  icon: Icons.schedule_rounded,
                  color: AppColors.amber,
                ),
                const Spacer(),
                Text(
                  '#${record.id}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              controller.formName(record.formId),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${record.data.length} responses  |  ${relativeTime(record.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _openReview(context, record, controller),
                    child: const Text('Inspect evidence'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Approve',
                  onPressed: () =>
                      _decide(context, record, controller, 'accepted'),
                  icon: const Icon(Icons.check_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _openReview(
  BuildContext context,
  SubmissionRecord record,
  AppController controller,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 780),
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
                          'Submission #${record.id}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(controller.formName(record.formId)),
                      ],
                    ),
                  ),
                  const StatusBadge('Pending review', color: AppColors.amber),
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
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      StatusBadge(
                        humanDate(record.createdAt),
                        icon: Icons.schedule_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      StatusBadge(
                        '${record.data.length} responses',
                        icon: Icons.format_list_bulleted_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  ...record.data.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SectionCard(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _reviewLabel(entry.key),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _reviewValue(entry.value),
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      await _decide(context, record, controller, 'rejected');
                    },
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Return for correction'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      await _decide(context, record, controller, 'accepted');
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Approve submission'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _decide(
  BuildContext context,
  SubmissionRecord record,
  AppController controller,
  String status,
) async {
  final noteController = TextEditingController();
  final accepted = status == 'accepted';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(
        accepted ? Icons.verified_outlined : Icons.assignment_return_outlined,
      ),
      title: Text(accepted ? 'Approve submission?' : 'Return for correction'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            accepted
                ? 'The record will be accepted into ICCASA reporting.'
                : 'Explain what the field agent needs to correct before resubmission.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: noteController,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: accepted
                  ? 'Optional review note'
                  : 'Required correction note',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!accepted && noteController.text.trim().isEmpty) return;
            Navigator.pop(context, true);
          },
          child: Text(accepted ? 'Approve' : 'Return record'),
        ),
      ],
    ),
  );
  if (confirmed != true) {
    noteController.dispose();
    return;
  }
  try {
    await controller.review(
      record.id,
      status,
      note: noteController.text.trim(),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accepted
                ? 'Submission approved.'
                : 'Submission returned for correction.',
          ),
        ),
      );
    }
  } on ApiException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  } finally {
    noteController.dispose();
  }
}

String _reviewLabel(String value) => value
    .split('_')
    .map(
      (part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' ');

String _reviewValue(dynamic value) {
  if (value == null) return 'Not provided';
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is Map) {
    if (value['latitude'] != null) {
      return '${value['latitude']}, ${value['longitude']}';
    }
    if (value['filename'] != null) return 'Evidence file: ${value['filename']}';
    return value.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
  }
  if (value is Iterable) return value.join(', ');
  return value.toString();
}
