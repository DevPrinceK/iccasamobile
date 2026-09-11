import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iccasa_mobile/core/models/field_models.dart';
import 'package:iccasa_mobile/core/network/api_client.dart';
import 'package:iccasa_mobile/core/services/geography_repository.dart';
import 'package:iccasa_mobile/core/state/app_controller.dart';
import 'package:iccasa_mobile/core/storage/local_store.dart';
import 'package:iccasa_mobile/app/theme.dart';
import 'package:iccasa_mobile/design_system/components/submission_response_value.dart';
import 'package:iccasa_mobile/features/assignments/assignment_detail_screen.dart';
import 'package:iccasa_mobile/features/assignments/assignments_screen.dart';
import 'package:iccasa_mobile/features/auth/login_screen.dart';
import 'package:iccasa_mobile/features/collection/collection_screen.dart';
import 'package:iccasa_mobile/features/dashboard/dashboard_screen.dart';
import 'package:iccasa_mobile/features/records/records_screen.dart';
import 'package:iccasa_mobile/features/review/review_screen.dart';
import 'package:iccasa_mobile/features/settings/settings_screen.dart';
import 'package:iccasa_mobile/features/sync_center/sync_center_screen.dart';

void main() {
  test('published form detail parses server fields in order', () {
    final form = FieldAssignment.fromJson({
      'id': 7,
      'name': 'Site visit',
      'description': 'Quarterly check',
      'is_active': true,
      'current_version': {
        'id': 12,
        'version': 2,
        'is_published': true,
        'schema': {'instructions': 'Verify evidence.'},
        'fields': [
          {
            'id': 2,
            'key': 'value',
            'label': 'Value',
            'field_type': 'Number',
            'order': 1,
            'required': true,
            'config': {},
          },
          {
            'id': 1,
            'key': 'district',
            'label': 'District',
            'field_type': 'Text',
            'order': 0,
            'required': true,
            'config': {},
          },
        ],
      },
    });

    expect(form.isReady, isTrue);
    expect(form.fieldCount, 6);
    expect(form.requiredCount, 5);
    expect(form.version!.fields.first.key, 'district');
    expect(form.version!.instructions, 'Verify evidence.');
  });

  test('assigned forms prefer the published version over a newer draft', () {
    final form = FieldAssignment.fromJson({
      'id': 9,
      'name': 'Partner verification',
      'is_active': true,
      'current_version': {
        'id': 30,
        'version': 3,
        'is_published': false,
        'fields': const [],
      },
      'versions': [
        {'id': 30, 'version': 3, 'is_published': false, 'fields': const []},
        {
          'id': 29,
          'version': 2,
          'is_published': true,
          'fields': [
            {
              'id': 1,
              'key': 'district',
              'label': 'District',
              'field_type': 'Dropdown',
              'required': true,
              'config': {
                'options': [
                  {'label': 'Tamale Metro', 'value': 'tamale'},
                ],
              },
            },
          ],
        },
      ],
    });

    expect(form.version!.id, 29);
    expect(form.isReady, isTrue);
    expect(form.version!.fields.single.options.single.label, 'Tamale Metro');
    expect(form.version!.fields.single.options.single.value, 'tamale');
  });

  test('mobile permissions and review statuses match the live API', () {
    final reviewer = AppUser.fromJson({
      'id': 1,
      'name': 'Reviewer',
      'email': 'reviewer@example.org',
      'role': 'manager',
      'avatar_url': '/api/v1/users/1/avatar?v=2',
    });
    final observer = AppUser.fromJson({
      'id': 2,
      'name': 'Observer',
      'email': 'observer@example.org',
      'role': 'donor_viewer',
    });
    final queued = SubmissionRecord.fromJson({
      'id': 41,
      'form_id': 9,
      'form_version_id': 29,
      'status': 'queued',
      'country_name': 'Ghana',
      'administrative_area_name': 'Tamale Metropolitan District',
      'administrative_area_type': 'District',
      'disability_status': 'self-identified disability',
      'disability_types': ['visual', 'hearing'],
      'data': const {},
      'created_at': DateTime.now().toIso8601String(),
    });

    expect(reviewer.canReview, isTrue);
    expect(observer.canReview, isFalse);
    expect(reviewer.avatarUrl, '/api/v1/users/1/avatar?v=2');
    expect(queued.isAwaitingReview, isTrue);
    expect(queued.countryName, 'Ghana');
    expect(queued.administrativeAreaName, 'Tamale Metropolitan District');
    expect(queued.disabilityStatus, 'self-identified disability');
    expect(queued.disabilityTypes, ['visual', 'hearing']);
  });

  testWidgets('login exposes the secure sign-in flow', (tester) async {
    final controller = AppController(api: ApiClient(), store: LocalStore())
      ..stage = AppStage.signedOut;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appControllerProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in securely'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Protected ICCASA workspace'), findsOneWidget);
  });

  testWidgets('login opens the native password reset flow', (tester) async {
    final controller = AppController(api: ApiClient(), store: LocalStore())
      ..stage = AppStage.signedOut;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appControllerProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.text('Reset your password')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Email address')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Send reset code')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Cancel')),
      findsOneWidget,
    );
  });

  testWidgets('light theme filter chips retain readable labels', (
    tester,
  ) async {
    final controller = AppController(api: ApiClient(), store: LocalStore())
      ..stage = AppStage.signedIn
      ..previewMode = true;
    final theme = buildLightTheme();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appControllerProvider.overrideWith((ref) => controller)],
        child: MaterialApp(theme: theme, home: const AssignmentsScreen()),
      ),
    );

    final chips = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .toList();
    expect(chips, hasLength(3));
    expect(chips.first.labelStyle?.color, theme.colorScheme.onPrimaryContainer);
    expect(chips[1].labelStyle?.color, theme.colorScheme.onSurface);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appControllerProvider.overrideWith((ref) => controller)],
        child: MaterialApp(theme: theme, home: const RecordsScreen()),
      ),
    );
    final recordChips = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .toList();
    expect(recordChips, hasLength(5));
    expect(
      recordChips.first.labelStyle?.color,
      theme.colorScheme.onPrimaryContainer,
    );
    expect(recordChips[1].labelStyle?.color, theme.colorScheme.onSurface);
  });

  testWidgets('manual sync shows progress and completion feedback', (
    tester,
  ) async {
    final controller = AppController(api: ApiClient(), store: LocalStore())
      ..stage = AppStage.signedIn
      ..previewMode = true
      ..isOnline = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appControllerProvider.overrideWith((ref) => controller)],
        child: MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: SyncCenterScreen()),
        ),
      ),
    );

    await tester.tap(find.text('Sync now'));
    await tester.pump();
    expect(find.text('Syncing...'), findsOneWidget);
    expect(
      find.text('Checking assignments and sending queued records...'),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 700));
    expect(
      find.text('Sync complete. Assignments and records are up to date.'),
      findsOneWidget,
    );
  });

  test('checkbox false is a recorded response rather than a missing value', () {
    expect(isResponseEmpty(false), isFalse);
    expect(isResponseEmpty(0), isFalse);
    expect(isResponseEmpty(''), isTrue);
    expect(isResponseEmpty(const []), isTrue);
  });

  test('correction values retain geography and disability metadata', () {
    final record = SubmissionRecord.fromJson({
      'id': 91,
      'form_id': 9,
      'form_version_id': 29,
      'status': 'rejected',
      'submitted_by_name': 'Prince Kyeremanteng',
      'submitted_by_email': 'prince@example.org',
      'country_code': 'GH',
      'country_name': 'Ghana',
      'administrative_area_code': 'GH.12.702',
      'administrative_area_name': 'Asunafo North',
      'administrative_area_type': 'District',
      'disability_status': 'self-identified disability',
      'disability_types': ['physical_mobility', 'other'],
      'other_disability_type': 'Chronic pain-related impairment',
      'data': {'result': 12},
      'created_at': DateTime.now().toIso8601String(),
    });

    final values = submissionValuesForCorrection(record);

    expect(values['result'], 12);
    expect(values[geographyValueKey]['country_code'], 'GH');
    expect(values[geographyValueKey]['administrative_area_code'], 'GH.12.702');
    expect(values['__disability']['types'], ['physical_mobility', 'other']);
    expect(record.submittedByName, 'Prince Kyeremanteng');
  });

  test(
    'sync always leaves its busy state after malformed local evidence',
    () async {
      final controller = AppController(api: ApiClient(), store: _MemoryStore())
        ..stage = AppStage.signedIn
        ..isOnline = true
        ..outbox = [
          OutboxItem(
            id: 'local-1',
            formId: 7,
            formVersionId: 12,
            formName: 'Site visit',
            data: {
              'signature': {
                'filename': 'signature.png',
                '_upload_bytes': 'not-valid-base64',
              },
            },
            createdAt: DateTime.now(),
          ),
        ];

      await controller.syncOutbox();

      expect(controller.isSyncing, isFalse);
      expect(controller.outbox, hasLength(1));
      expect(controller.outbox.single.attempts, 1);
      expect(controller.outbox.single.lastError, isNotEmpty);
    },
  );

  testWidgets('signature evidence is compact, expandable and identifies signer', (
    tester,
  ) async {
    const onePixelPng =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: const Scaffold(
          body: SubmissionResponseValue(
            label: 'signature',
            value: {
              'filename': 'signature-1.png',
              'content_type': 'image/png',
              '_upload_bytes': onePixelPng,
            },
            signedBy: 'Prince Kyeremanteng',
          ),
        ),
      ),
    );

    expect(find.text('Signed by Prince Kyeremanteng'), findsOneWidget);
    expect(find.text('Tap image to expand'), findsOneWidget);
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.text('Captured signature'), findsOneWidget);
  });

  testWidgets(
    'assignment list remains usable on a narrow phone at large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 740);
      addTearDown(tester.view.reset);
      final controller = AppController(api: ApiClient(), store: _MemoryStore());
      await controller.enterPreview();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appControllerProvider.overrideWith((ref) => controller)],
          child: MaterialApp(
            theme: buildLightTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: const Scaffold(body: AssignmentsScreen()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Assignments'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('core workflows render without overflow on phone and tablet', (
    tester,
  ) async {
    final controller = AppController(api: ApiClient(), store: _MemoryStore());
    await controller.enterPreview();
    addTearDown(tester.view.reset);

    Future<void> pumpScreen(
      Widget screen,
      Size size, {
      double textScale = 1,
    }) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = size;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appControllerProvider.overrideWith((ref) => controller)],
          child: MaterialApp(
            theme: buildLightTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: Scaffold(body: screen),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 120));
      expect(
        tester.takeException(),
        isNull,
        reason: '${screen.runtimeType} overflowed at ${size.width} px',
      );
    }

    const phone = Size(360, 740);
    const tablet = Size(1024, 768);
    final screens = <Widget>[
      const DashboardScreen(),
      const AssignmentsScreen(),
      const AssignmentDetailScreen(formId: 101),
      const CollectionScreen(formId: 101, draftId: null),
      const RecordsScreen(),
      const ReviewScreen(),
      const SyncCenterScreen(),
      const SettingsScreen(),
    ];
    for (final screen in screens) {
      await pumpScreen(screen, phone, textScale: 1.3);
      await pumpScreen(screen, tablet);
    }
  });
}

class _MemoryStore extends LocalStore {
  @override
  Future<void> saveDrafts(List<DraftRecord> values) async {}

  @override
  Future<void> saveOutbox(List<OutboxItem> values) async {}

  @override
  Future<void> saveSubmissions(List<SubmissionRecord> values) async {}
}
