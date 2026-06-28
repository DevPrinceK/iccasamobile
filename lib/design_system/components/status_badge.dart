import 'package:flutter/material.dart';

import '../../core/models/field_models.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge.assignment(this.status, {super.key})
    : syncStatus = null,
      label = null;

  const StatusBadge.sync(this.syncStatus, {super.key})
    : status = null,
      label = null;

  const StatusBadge.text(this.label, {super.key})
    : status = null,
      syncStatus = null;

  final AssignmentStatus? status;
  final SyncStatus? syncStatus;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolved =
        label ?? _assignmentLabel(status) ?? _syncLabel(syncStatus) ?? 'Status';
    final color = _color(context, scheme);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .32)),
      ),
      child: Text(
        resolved,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _color(BuildContext context, ColorScheme scheme) {
    if (status == AssignmentStatus.returnedForCorrection ||
        status == AssignmentStatus.needsAttention ||
        syncStatus == SyncStatus.failed ||
        syncStatus == SyncStatus.conflict) {
      return scheme.error;
    }
    if (status == AssignmentStatus.approved ||
        syncStatus == SyncStatus.synced) {
      return Colors.green.shade700;
    }
    if (status == AssignmentStatus.pendingSync ||
        syncStatus == SyncStatus.pending ||
        syncStatus == SyncStatus.syncing) {
      return const Color(0xff9a6700);
    }
    if (syncStatus == SyncStatus.blocked) {
      return Colors.indigo.shade600;
    }
    return scheme.primary;
  }
}

String? _assignmentLabel(AssignmentStatus? status) {
  return switch (status) {
    AssignmentStatus.newWork => 'New',
    AssignmentStatus.inProgress => 'In progress',
    AssignmentStatus.needsAttention => 'Needs attention',
    AssignmentStatus.completedLocal => 'Completed locally',
    AssignmentStatus.pendingSync => 'Pending sync',
    AssignmentStatus.submitted => 'Submitted',
    AssignmentStatus.returnedForCorrection => 'Returned',
    AssignmentStatus.approved => 'Approved',
    null => null,
  };
}

String? _syncLabel(SyncStatus? status) {
  return switch (status) {
    SyncStatus.pending => 'Pending',
    SyncStatus.syncing => 'Syncing',
    SyncStatus.synced => 'Synced',
    SyncStatus.failed => 'Failed',
    SyncStatus.blocked => 'Blocked',
    SyncStatus.conflict => 'Conflict',
    null => null,
  };
}
