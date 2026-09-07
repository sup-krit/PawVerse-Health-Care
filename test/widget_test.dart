import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawverse_health_care/main.dart';
import 'package:pawverse_health_care/memory_repository.dart';

void main() {
  Future<void> start(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('capture'),
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: HealthApp(repository: MemoryHealthRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('capture')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('test-artifacts').createSync(recursive: true);
      File('test-artifacts/$name.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('mobile overview capture and validated record creation', (
    tester,
  ) async {
    await start(tester);
    expect(find.text('Care, one day\nat a time.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture(tester, 'health-overview');
    await tester.tap(find.text('Add record').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('This field is required.'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      'Demo follow-up note',
    );
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Records'));
    await tester.pumpAndSettle();
    expect(find.text('Demo follow-up note'), findsOneWidget);
    await capture(tester, 'health-records');
    expect(tester.takeException(), isNull);
  });
  testWidgets('pet switching clears record view; verified original read only', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('Records'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Example clinic visit'));
    await tester.pumpAndSettle();
    expect(find.text('Verified example · Read-only original'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch pet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Luna · Cat'));
    await tester.pumpAndSettle();
    expect(find.text('Daily care note'), findsNothing);
    expect(
      find.text('No records yet. Start with a visit or note.'),
      findsOneWidget,
    );
  });
  testWidgets('large text care and sharing tabs have no overflow', (
    tester,
  ) async {
    await start(tester, scale: 1.6);
    await tester.tap(find.text('Care'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Sharing'));
    await tester.pumpAndSettle();
    await capture(tester, 'health-sharing');
    expect(tester.takeException(), isNull);
  });
}
