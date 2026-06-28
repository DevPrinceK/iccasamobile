import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';

import '../../core/models/field_models.dart';
import '../../core/state/session_controller.dart';
import '../../design_system/components/section_panel.dart';
import '../../design_system/components/status_badge.dart';

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  String? selectedId;
  final signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black87,
  );

  @override
  void dispose() {
    signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(demoRepositoryProvider);
    final assignments = repo.assignments;
    final selected = assignments.firstWhere(
      (item) => item.id == (selectedId ?? assignments.first.id),
    );
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final list = _AssignmentList(
      assignments: assignments,
      selectedId: selected.id,
      onSelected: (id) => setState(() => selectedId = id),
    );
    final detail = _AssignmentDetail(
      assignment: selected,
      signatureController: signatureController,
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 390, child: list),
                const SizedBox(width: 20),
                Expanded(child: detail),
              ],
            )
          : ListView(children: [list, const SizedBox(height: 20), detail]),
    );
  }
}

class _AssignmentList extends StatelessWidget {
  const _AssignmentList({
    required this.assignments,
    required this.selectedId,
    required this.onSelected,
  });

  final List<FieldAssignment> assignments;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Assignments',
      action: IconButton.filledTonal(
        onPressed: () {},
        icon: const Icon(Icons.refresh),
        tooltip: 'Refresh assignments',
      ),
      child: Column(
        children: [
          const TextField(
            decoration: InputDecoration(
              hintText: 'Search name, reference, location',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < assignments.length; index++)
            _AssignmentCard(
              assignment: assignments[index],
              selected: assignments[index].id == selectedId,
              onTap: () => onSelected(assignments[index].id),
            ).animate(delay: (60 * index).ms).fadeIn().slideY(begin: .08),
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.selected,
    required this.onTap,
  });

  final FieldAssignment assignment;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: selected ? scheme.primaryContainer.withValues(alpha: .55) : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    StatusBadge.assignment(assignment.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(assignment.task),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(assignment.community)),
                    Text('${assignment.distanceKm.toStringAsFixed(1)} km'),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: assignment.progress),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssignmentDetail extends ConsumerWidget {
  const _AssignmentDetail({
    required this.assignment,
    required this.signatureController,
  });

  final FieldAssignment assignment;
  final SignatureController signatureController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(demoRepositoryProvider).formSteps;

    return ListView(
      shrinkWrap: true,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment.personName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text('${assignment.reference} • ${assignment.community}'),
                ],
              ),
            ),
            StatusBadge.sync(assignment.syncStatus),
          ],
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visit Workflow',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                for (final step in steps) _FormStepTile(step: step),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _EvidenceGrid(signatureController: signatureController),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save draft'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () {},
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Complete locally'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FormStepTile extends StatelessWidget {
  const _FormStepTile({required this.step});

  final FormStepDefinition step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  step.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text('${(step.completion * 100).round()}%'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: step.completion),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final field in step.fields) StatusBadge.text(field),
            ],
          ),
        ],
      ),
    );
  }
}

class _EvidenceGrid extends StatelessWidget {
  const _EvidenceGrid({required this.signatureController});

  final SignatureController signatureController;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Evidence',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns = constraints.maxWidth > 680;
          final width = twoColumns
              ? (constraints.maxWidth - 14) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              SizedBox(
                width: width,
                child: _EvidenceTile(
                  icon: Icons.camera_alt_outlined,
                  title: 'Photo capture',
                  body:
                      'Queued uploads keep timestamp and assignment metadata.',
                ),
              ),
              SizedBox(
                width: width,
                child: _EvidenceTile(
                  icon: Icons.my_location_outlined,
                  title: 'GPS point',
                  body:
                      'Location capture will request permission before saving.',
                ),
              ),
              SizedBox(
                width: width,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Signature',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Signature(
                            controller: signatureController,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(body),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: () {},
              icon: const Icon(Icons.add),
              tooltip: title,
            ),
          ],
        ),
      ),
    );
  }
}
