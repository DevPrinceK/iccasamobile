import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/state/app_controller.dart';
import '../../design_system/app_ui.dart';
import '../assignments/assignment_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final recentAssignments = controller.assignments.take(3).toList();
    final latestDraft = controller.drafts.firstOrNull;
    return AppPage(
      onRefresh: controller.refreshAll,
      children: [
        PageHeader(
          eyebrow: _greeting(),
          title: 'Hello, ${controller.user?.firstName ?? 'there'}',
          subtitle: controller.isOnline
              ? 'Your field workspace is current and ready for today\'s collection work.'
              : 'You are offline. Assigned forms and drafts remain available on this device.',
          actions: [
            StatusBadge(
              controller.isOnline ? 'Online' : 'Offline',
              icon: controller.isOnline
                  ? Icons.wifi_rounded
                  : Icons.wifi_off_rounded,
              color: controller.isOnline ? AppColors.emerald : AppColors.amber,
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (controller.errorMessage != null) ...[
          MessageBanner(
            message: controller.errorMessage!,
            warning: !controller.isOnline,
            onDismiss: controller.clearError,
          ),
          const SizedBox(height: 18),
        ],
        _ActionHero(
          controller: controller,
          onPrimary: () {
            if (latestDraft != null) {
              context.go(
                '/collect/${latestDraft.formId}?draft=${latestDraft.id}',
              );
            } else {
              context.go('/assignments');
            }
          },
        ).animate().fadeIn(duration: 340.ms).slideY(begin: 0.04, end: 0),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1050
                ? 4
                : constraints.maxWidth >= 580
                ? 2
                : 1;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: columns == 1
                  ? 2.1
                  : columns == 2
                  ? 2.35
                  : 1.6,
              children: [
                MetricCard(
                  label: 'Assigned forms',
                  value: '${controller.assignments.length}',
                  icon: Icons.assignment_outlined,
                  caption: 'Available on this device',
                ),
                MetricCard(
                  label: 'Drafts in progress',
                  value: '${controller.drafts.length}',
                  icon: Icons.edit_note_rounded,
                  accent: AppColors.blue,
                  caption: 'Saved automatically',
                ),
                MetricCard(
                  label: 'Queued to sync',
                  value: '${controller.outbox.length}',
                  icon: Icons.cloud_upload_outlined,
                  accent: AppColors.amber,
                  caption: controller.outbox.isEmpty
                      ? 'Everything is current'
                      : 'Will retry when online',
                ),
                MetricCard(
                  label: 'Accepted records',
                  value: '${controller.acceptedCount}',
                  icon: Icons.verified_outlined,
                  accent: AppColors.emerald,
                  caption: 'Verified by reviewers',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            final work = _TodayWork(
              assignments: recentAssignments,
              controller: controller,
            );
            final activity = _RecentActivity(controller: controller);
            if (!wide) {
              return Column(
                children: [work, const SizedBox(height: 20), activity],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: work),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: activity),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _ActionHero extends StatelessWidget {
  const _ActionHero({required this.controller, required this.onPrimary});

  final AppController controller;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final hasDraft = controller.drafts.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007A64), Color(0xFF0C4761)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                hasDraft ? Icons.edit_note_rounded : Icons.add_task_rounded,
                color: Colors.white,
                size: 34,
              ),
              const SizedBox(height: 16),
              Text(
                hasDraft
                    ? 'Continue where you left off'
                    : 'Ready to collect new evidence?',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                hasDraft
                    ? '${controller.drafts.first.formName} was saved ${relativeTime(controller.drafts.first.updatedAt).toLowerCase()}.'
                    : '${controller.assignments.length} assigned forms are available and ready to use offline.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
            ],
          );
          final button = FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.emeraldDark,
            ),
            onPressed: onPrimary,
            icon: Icon(
              hasDraft ? Icons.arrow_forward_rounded : Icons.add_rounded,
            ),
            label: Text(hasDraft ? 'Continue draft' : 'Choose a form'),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [copy, const SizedBox(height: 22), button],
            );
          }
          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 24),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _TodayWork extends StatelessWidget {
  const _TodayWork({required this.assignments, required this.controller});

  final List<dynamic> assignments;
  final AppController controller;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Assigned work',
          subtitle: 'Your next available collection forms',
          trailing: TextButton(
            onPressed: () => context.go('/assignments'),
            child: const Text('View all'),
          ),
        ),
        const SizedBox(height: 18),
        if (assignments.isEmpty)
          const EmptyState(
            icon: Icons.assignment_late_outlined,
            title: 'No assigned forms',
            message:
                'New collection work will appear here when it is assigned to you.',
          )
        else
          ...assignments.map((assignment) {
            final draft = controller.drafts
                .where((item) => item.formId == assignment.id)
                .firstOrNull;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AssignmentCard(
                assignment: assignment,
                draft: draft,
                compact: true,
                onOpen: () => context.go('/assignments/${assignment.id}'),
              ),
            );
          }),
      ],
    ),
  );
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final records = controller.submissions.take(5).toList();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            title: 'Recent activity',
            subtitle: 'Latest records and review outcomes',
            trailing: IconButton(
              tooltip: 'Open records',
              onPressed: () => context.go('/records'),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ),
          const SizedBox(height: 18),
          if (records.isEmpty)
            const EmptyState(
              icon: Icons.history_rounded,
              title: 'No recent records',
              message: 'Submitted records and review updates will appear here.',
            )
          else
            ...records.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
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
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.formName ??
                                controller.formName(record.formId),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            relativeTime(record.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(record.status),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
