import 'package:flutter/material.dart';

import '../../core/models/field_models.dart';
import '../../core/services/geography_repository.dart';
import '../../core/services/disability_metadata.dart';
import '../../design_system/app_ui.dart';

class AssignmentCard extends StatelessWidget {
  const AssignmentCard({
    required this.assignment,
    required this.onOpen,
    super.key,
    this.draft,
    this.compact = false,
  });

  final FieldAssignment assignment;
  final DraftRecord? draft;
  final VoidCallback onOpen;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedCustom = draft == null
        ? 0
        : assignment.version?.fields.where((field) {
                final value = draft!.values[field.key];
                return value != null &&
                    value.toString().trim().isNotEmpty &&
                    value != false;
              }).length ??
              0;
    final geography = draft == null
        ? const <String, dynamic>{}
        : geographyFromValues(draft!.values);
    final disability = draft == null
        ? const <String, dynamic>{}
        : disabilityFromValues(draft!.values);
    final completed =
        completedCustom +
        (geography['country_code']?.toString().isNotEmpty ?? false ? 1 : 0) +
        (geographyIsComplete(geography) ? 1 : 0) +
        (disability['status']?.toString().isNotEmpty ?? false ? 1 : 0) +
        (disabilityIsComplete(disability) ? 1 : 0);
    final totalFields = assignment.fieldCount;
    final progress = totalFields == 0 ? 0.0 : completed / totalFields;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: EdgeInsets.all(compact ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.assignment_outlined,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          assignment.projectId == null
                              ? 'Institutional collection'
                              : 'Project ${assignment.projectId}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (!compact) ...[
                const SizedBox(height: 16),
                Text(
                  assignment.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (draft != null) ...[
                Row(
                  children: [
                    const StatusBadge('Draft', icon: Icons.edit_note_rounded),
                    const Spacer(),
                    Text(
                      '${(progress * 100).round()}% complete',
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(99),
                ),
              ] else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusBadge(
                      '${assignment.fieldCount} fields',
                      icon: Icons.format_list_bulleted_rounded,
                    ),
                    StatusBadge(
                      '${assignment.requiredCount} required',
                      icon: Icons.verified_outlined,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
