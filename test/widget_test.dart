import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iccasa_mobile/core/models/field_models.dart';
import 'package:iccasa_mobile/core/network/api_client.dart';
import 'package:iccasa_mobile/core/state/app_controller.dart';
import 'package:iccasa_mobile/core/storage/local_store.dart';
import 'package:iccasa_mobile/features/auth/login_screen.dart';

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
    expect(form.requiredCount, 2);
    expect(form.version!.fields.first.key, 'district');
    expect(form.version!.instructions, 'Verify evidence.');
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
}
