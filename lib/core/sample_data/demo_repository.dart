import '../models/field_models.dart';

class DemoRepository {
  const DemoRepository();

  List<FieldAssignment> get assignments => const [
    FieldAssignment(
      id: 'a-1048',
      reference: 'ICC-2026-1048',
      personName: 'Martha Kollie',
      community: 'Paynesville Zone 3',
      task: 'Household verification and consent update',
      status: AssignmentStatus.inProgress,
      syncStatus: SyncStatus.pending,
      dueLabel: 'Due today, 2:30 PM',
      distanceKm: 1.8,
      progress: .62,
    ),
    FieldAssignment(
      id: 'a-1051',
      reference: 'ICC-2026-1051',
      personName: 'Joseph Teah',
      community: 'Barnersville Estate',
      task: 'New beneficiary intake',
      status: AssignmentStatus.newWork,
      syncStatus: SyncStatus.synced,
      dueLabel: 'Due today, 4:00 PM',
      distanceKm: 4.2,
      progress: .08,
    ),
    FieldAssignment(
      id: 'a-1055',
      reference: 'ICC-2026-1055',
      personName: 'Grace Bility',
      community: 'Congo Town',
      task: 'Returned record correction',
      status: AssignmentStatus.returnedForCorrection,
      syncStatus: SyncStatus.failed,
      dueLabel: 'Overdue',
      distanceKm: 6.4,
      progress: .84,
    ),
  ];

  List<FieldRecord> get records => const [
    FieldRecord(
      id: 'r-8801',
      name: 'Martha Kollie',
      reference: 'ICC-2026-1048',
      phone: '+231 77 456 1002',
      location: 'Paynesville Zone 3',
      lastVisit: 'Draft saved 14 min ago',
      status: AssignmentStatus.inProgress,
    ),
    FieldRecord(
      id: 'r-8814',
      name: 'Joseph Teah',
      reference: 'ICC-2026-1051',
      phone: '+231 88 120 5421',
      location: 'Barnersville Estate',
      lastVisit: 'Not started',
      status: AssignmentStatus.newWork,
    ),
    FieldRecord(
      id: 'r-8780',
      name: 'Grace Bility',
      reference: 'ICC-2026-1055',
      phone: '+231 77 391 7740',
      location: 'Congo Town',
      lastVisit: 'Returned yesterday',
      status: AssignmentStatus.returnedForCorrection,
    ),
  ];

  List<SyncQueueItem> get queue => [
    SyncQueueItem(
      id: 'q-1',
      label: 'Martha Kollie draft answers',
      endpoint: '/api/mobile/sync/batch',
      status: SyncStatus.pending,
      retryCount: 0,
      updatedAt: DateTime.now().subtract(const Duration(minutes: 14)),
    ),
    SyncQueueItem(
      id: 'q-2',
      label: 'Grace Bility correction photo',
      endpoint: '/api/mobile/media',
      status: SyncStatus.failed,
      retryCount: 2,
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      error: 'Network dropped during upload',
    ),
    SyncQueueItem(
      id: 'q-3',
      label: 'Device location heartbeat',
      endpoint: '/api/mobile/sync/batch',
      status: SyncStatus.synced,
      retryCount: 0,
      updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  List<FieldAlert> get alerts => const [
    FieldAlert(
      id: 'alert-1',
      title: 'Offline mode active',
      body: 'Three local changes are waiting for a stable connection.',
      level: AlertLevel.warning,
    ),
    FieldAlert(
      id: 'alert-2',
      title: 'Supervisor note',
      body: 'Confirm consent signature before completing returned records.',
      level: AlertLevel.info,
    ),
  ];

  List<FormStepDefinition> get formSteps => const [
    FormStepDefinition(
      title: 'Identity',
      completion: 1,
      fields: ['Name confirmed', 'Phone number', 'Household reference'],
    ),
    FormStepDefinition(
      title: 'Visit details',
      completion: .65,
      fields: ['Interview outcome', 'Consent status', 'Field notes'],
    ),
    FormStepDefinition(
      title: 'Evidence',
      completion: .35,
      fields: ['Photo', 'GPS point', 'Signature'],
    ),
  ];
}
