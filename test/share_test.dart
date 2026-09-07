import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawverse_health_care/main.dart';
import 'package:pawverse_health_care/memory_repository.dart';

void main() {
  testWidgets('recipient change invalidates consent; revoke clears preview', (
    tester,
  ) async {
    await tester.pumpWidget(HealthApp(repository: MemoryHealthRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sharing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create demo share'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Demo family');
    await tester.tap(find.text('Daily care note'));
    final consent = find.widgetWithText(
      CheckboxListTile,
      'I confirm this recipient, selected records and expiry for this demo.',
    );
    await tester.ensureVisible(consent);
    await tester.tap(consent);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(consent).value, isTrue);
    await tester.ensureVisible(find.byType(TextFormField));
    await tester.enterText(
      find.byType(TextFormField),
      'Changed demo recipient',
    );
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(consent).value, isFalse);
    expect(
      find.textContaining('records for Changed demo recipient'),
      findsOneWidget,
    );
    await tester.ensureVisible(consent);
    await tester.tap(consent);
    await tester.ensureVisible(find.text('Confirm demo share'));
    await tester.tap(find.text('Confirm demo share'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Recipient preview'));
    await tester.tap(find.text('Recipient preview'));
    await tester.pumpAndSettle();
    expect(find.text('Daily care note'), findsOneWidget);
    expect(find.text('Example clinic visit'), findsNothing);
    await tester.tap(find.text('Close preview'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revoke'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revoke access'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Recipient preview'));
    await tester.tap(find.text('Recipient preview'));
    await tester.pumpAndSettle();
    expect(find.text('Access ended. No records available.'), findsOneWidget);
    expect(find.text('Daily care note'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
