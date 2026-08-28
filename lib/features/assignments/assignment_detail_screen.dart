import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/models/field_models.dart';
import '../../core/state/app_controller.dart';
import '../../design_system/app_ui.dart';

class AssignmentDetailScreen extends ConsumerWidget {
  const AssignmentDetailScreen({required this.formId, super.key});

  final int formId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final assignment = controller.assignmentById(formId);
    if (assignment == null) {
      return AppPage(
        children: [
          EmptyState(
            icon: Icons.assignment_late_outlined,
            title: 'Assignment unavailable',
            message:
                'This form may have been unassigned or is not saved on this device.',
            action: FilledButton(
              onPressed: () => context.go('/assignments'),
              child: const Text('Back to assignments'),
            ),
          ),
        ],
      );
    }
    final draft = controller.drafts
        .where((item) => item.formId == formId)
        .firstOrNull;
    final fields = assignment.version?.fields ?? const <FieldDefinition>[];
    return AppPage(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go('/assignments'),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Assignments'),
          ),
        ),
        const SizedBox(height: 8),
        PageHeader(
          eyebrow: assignment.projectId == null
              ? 'Institutional collection'
              : 'Project ${assignment.projectId}',
          title: assignment.name,
          subtitle: assignment.description,
          actions: [
            StatusBadge(
              assignment.isReady ? 'Ready' : 'Unavailable',
              icon: assignment.isReady
                  ? Icons.verified_outlined
                  : Icons.warning_amber_rounded,
            ),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final main = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                        title: 'Before you begin',
                        subtitle: 'Collection guidance from the form owner',
                      ),
                      const SizedBox(height: 18),
                      Text(
                        assignment.version?.instructions ??
                            'Review the source information and complete each required field.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 18),
                      const _GuidancePoint(
                        icon: Icons.people_outline_rounded,
                        text:
                            'Confirm informed consent before collecting personal information.',
                      ),
                      const SizedBox(height: 12),
                      const _GuidancePoint(
                        icon: Icons.fact_check_outlined,
                        text:
                            'Verify values against source documents before submission.',
                      ),
                      const SizedBox(height: 12),
                      const _GuidancePoint(
                        icon: Icons.lock_outline_rounded,
                        text:
                            'Keep identifiable data private and use only this assigned device.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionTitle(
                        title: 'Form contents',
                        subtitle:
                            '${assignment.fieldCount} fields, ${assignment.requiredCount} required',
                      ),
                      const SizedBox(height: 16),
                      const _SystemFieldPreview(label: 'Country'),
                      const _SystemFieldPreview(label: 'District / county'),
                      ...fields.map((field) => _FieldPreview(field: field)),
                    ],
                  ),
                ),
              ],
            );
            final side = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionTitle(title: 'Collection readiness'),
                      const SizedBox(height: 18),
                      _ReadinessRow(
                        label: 'Published form',
                        ready: assignment.version?.isPublished ?? false,
                      ),
                      const SizedBox(height: 12),
                      _ReadinessRow(
                        label: 'Saved for offline use',
                        ready: true,
                      ),
                      const SizedBox(height: 12),
                      _ReadinessRow(
                        label: controller.isOnline
                            ? 'Connection available'
                            : 'Offline collection ready',
                        ready: true,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: assignment.isReady
                            ? () {
                                final activeDraft =
                                    draft ?? controller.beginDraft(assignment);
                                context.go(
                                  '/collect/${assignment.id}?draft=${activeDraft.id}',
                                );
                              }
                            : null,
                        icon: Icon(
                          draft == null
                              ? Icons.play_arrow_rounded
                              : Icons.edit_note_rounded,
                        ),
                        label: Text(
                          draft == null ? 'Start collection' : 'Resume draft',
                        ),
                      ),
                      if (draft != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Saved ${relativeTime(draft.updatedAt).toLowerCase()}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(title: 'Form details'),
                      const SizedBox(height: 16),
                      _MetaRow(
                        label: 'Version',
                        value: 'v${assignment.version?.version ?? 0}',
                      ),
                      _MetaRow(
                        label: 'Project',
                        value:
                            assignment.projectId?.toString() ?? 'Institutional',
                      ),
                      _MetaRow(
                        label: 'Indicator',
                        value:
                            assignment.indicatorId?.toString() ?? 'Not linked',
                      ),
                    ],
                  ),
                ),
              ],
            );
            if (!wide) {
              return Column(children: [side, const SizedBox(height: 18), main]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: main),
                const SizedBox(width: 20),
                Expanded(flex: 4, child: side),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _GuidancePoint extends StatelessWidget {
  const _GuidancePoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 11),
      Expanded(child: Text(text)),
    ],
  );
}

class _FieldPreview extends StatelessWidget {
  const _FieldPreview({required this.field});

  final FieldDefinition field;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            _fieldIcon(field.normalizedType),
            size: 19,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            field.label,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        if (field.required)
          const StatusBadge('Required', color: AppColors.coral),
      ],
    ),
  );
}

class _SystemFieldPreview extends StatelessWidget {
  const _SystemFieldPreview({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.location_on_outlined,
            size: 19,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        const StatusBadge('Required', color: AppColors.coral),
      ],
    ),
  );
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({required this.label, required this.ready});

  final String label;
  final bool ready;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        ready ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: ready ? AppColors.emerald : Theme.of(context).colorScheme.error,
        size: 21,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ),
    ],
  );
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(value, style: Theme.of(context).textTheme.labelLarge),
      ],
    ),
  );
}

IconData _fieldIcon(String type) {
  if (type.contains('date')) return Icons.calendar_today_outlined;
  if (type.contains('number')) return Icons.numbers_rounded;
  if (type.contains('select') ||
      type.contains('choice') ||
      type.contains('dropdown')) {
    return Icons.list_alt_rounded;
  }
  if (type.contains('gps') || type.contains('location')) {
    return Icons.location_on_outlined;
  }
  if (type.contains('photo') || type.contains('image')) {
    return Icons.photo_camera_outlined;
  }
  if (type.contains('signature')) return Icons.draw_outlined;
  if (type.contains('checkbox') || type.contains('boolean')) {
    return Icons.check_box_outlined;
  }
  if (type.contains('long')) return Icons.notes_rounded;
  return Icons.short_text_rounded;
}
