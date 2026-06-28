import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iccasa_mobile/app/app.dart';

void main() {
  testWidgets('agent can enter the field dashboard', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: IccasaMobileApp()));
    await tester.pumpAndSettle();

    expect(find.text('ICCASA Field'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Good evening'), findsOneWidget);
    expect(find.text('Continue Work'), findsOneWidget);
  });
}
