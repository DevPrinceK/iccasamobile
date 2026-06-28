enum AssignmentStatus {
  newWork,
  inProgress,
  needsAttention,
  completedLocal,
  pendingSync,
  submitted,
  returnedForCorrection,
  approved,
}

enum SyncStatus { pending, syncing, synced, failed, blocked, conflict }

enum AlertLevel { info, warning, urgent }

class FieldAssignment {
  const FieldAssignment({
    required this.id,
    required this.reference,
    required this.personName,
    required this.community,
    required this.task,
    required this.status,
    required this.syncStatus,
    required this.dueLabel,
    required this.distanceKm,
    required this.progress,
  });

  final String id;
  final String reference;
  final String personName;
  final String community;
  final String task;
  final AssignmentStatus status;
  final SyncStatus syncStatus;
  final String dueLabel;
  final double distanceKm;
  final double progress;
}

class FieldRecord {
  const FieldRecord({
    required this.id,
    required this.name,
    required this.reference,
    required this.phone,
    required this.location,
    required this.lastVisit,
    required this.status,
  });

  final String id;
  final String name;
  final String reference;
  final String phone;
  final String location;
  final String lastVisit;
  final AssignmentStatus status;
}

class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.label,
    required this.endpoint,
    required this.status,
    required this.retryCount,
    required this.updatedAt,
    this.error,
  });

  final String id;
  final String label;
  final String endpoint;
  final SyncStatus status;
  final int retryCount;
  final DateTime updatedAt;
  final String? error;
}

class FieldAlert {
  const FieldAlert({
    required this.id,
    required this.title,
    required this.body,
    required this.level,
  });

  final String id;
  final String title;
  final String body;
  final AlertLevel level;
}

class FormStepDefinition {
  const FormStepDefinition({
    required this.title,
    required this.completion,
    required this.fields,
  });

  final String title;
  final double completion;
  final List<String> fields;
}
