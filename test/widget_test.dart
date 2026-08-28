import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iccasa_mobile/core/models/field_models.dart';
import 'package:iccasa_mobile/core/network/api_client.dart';
import 'package:iccasa_mobile/core/state/app_controller.dart';
import 'package:iccasa_mobile/core/storage/local_store.dart';
import 'package:iccasa_mobile/app/theme.dart';
import 'package:iccasa_mobile/features/assignments/assignments_screen.dart';
import 'package:iccasa_mobile/features/auth/login_screen.dart';
import 'package:iccasa_mobile/features/records/records_screen.dart';
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
    expect(form.fieldCount, 4);
    expect(form.requiredCount, 4);
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
      'data': const {},
      'created_at': DateTime.now().toIso8601String(),
    });

    expect(reviewer.canReview, isTrue);
    expect(observer.canReview, isFalse);
    expect(reviewer.avatarUrl, '/api/v1/users/1/avatar?v=2');
    expect(queued.isAwaitingReview, isTrue);
    expect(queued.countryName, 'Ghana');
    expect(queued.administrativeAreaName, 'Tamale Metropolitan District');
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
}
