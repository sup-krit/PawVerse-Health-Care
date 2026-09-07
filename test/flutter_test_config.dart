import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  var root = Directory(
    Platform.environment['FLUTTER_ROOT'] ??
        File(Platform.resolvedExecutable).parent.path,
  );
  while (!Directory('${root.path}/bin/cache/artifacts/material_fonts')
      .existsSync()) {
    final parent = root.parent;
    if (parent.path == root.path) {
      throw StateError('Set FLUTTER_ROOT to load SDK screenshot fonts.');
    }
    root = parent;
  }
  final fonts = '${root.path}/bin/cache/artifacts/material_fonts';
  Future<ByteData> bytes(String name) async =>
      ByteData.sublistView(await File('$fonts/$name').readAsBytes());
  await (FontLoader('Roboto')
        ..addFont(bytes('roboto-regular.ttf'))
        ..addFont(bytes('roboto-bold.ttf')))
      .load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(bytes('materialicons-regular.otf'))).load();
  await testMain();
}
