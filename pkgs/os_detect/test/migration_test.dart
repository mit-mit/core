// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('data-driven migration works', () async {
    final tempDir = Directory('.tmp_migration_test').absolute;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
    tempDir.createSync(recursive: true);

    try {
      final packageDir = Directory.current.absolute.path;

      // 1. Create pubspec.yaml
      final pubspec = File('${tempDir.path}/pubspec.yaml');
      pubspec.writeAsStringSync('''
name: migration_test_project
environment:
  sdk: ^3.5.0
dependencies:
  os_detect:
    path: $packageDir
''');

      // 2. Create bin/main.dart with prefixed import and all usages
      final mainFile = File('${tempDir.path}/bin/main.dart');
      mainFile.createSync(recursive: true);
      mainFile.writeAsStringSync('''
import 'package:os_detect/os_detect.dart' as Platform;

void main() {
  print(Platform.isAndroid);
  print(Platform.isIOS);
  print(Platform.isLinux);
  print(Platform.isMacOS);
  print(Platform.isWindows);
  print(Platform.isFuchsia);
  print(Platform.isBrowser);
  print(Platform.operatingSystem);
  print(Platform.operatingSystemVersion);
}
''');

      // 3. Create bin/main_no_prefix.dart with non-prefixed import
      final mainNoPrefixFile = File('${tempDir.path}/bin/main_no_prefix.dart');
      mainNoPrefixFile.createSync(recursive: true);
      mainNoPrefixFile.writeAsStringSync('''
import 'package:os_detect/os_detect.dart';

void main() {
  print(isAndroid);
  print(isIOS);
  print(isLinux);
  print(isMacOS);
  print(isWindows);
  print(isFuchsia);
  print(isBrowser);
  print(operatingSystem);
  print(operatingSystemVersion);
}
''');

      // 4. Run `dart pub get`
      final pubGetResult = await Process.run(
        'dart',
        ['pub', 'get'],
        workingDirectory: tempDir.path,
      );
      expect(pubGetResult.exitCode, 0, reason: 'pub get failed: ${pubGetResult.stderr}');

      // 5. Run `dart fix --apply`
      final dartFixResult = await Process.run(
        'dart',
        ['fix', '--apply'],
        workingDirectory: tempDir.path,
      );
      expect(dartFixResult.exitCode, 0, reason: 'dart fix failed: ${dartFixResult.stderr}');

      // 6. Assert bin/main.dart is migrated correctly
      final mainContent = mainFile.readAsStringSync();
      expect(mainContent, contains("import 'package:platform/platform.dart';"));
      expect(mainContent, contains('print(Platform.current.isAndroid);'));
      expect(mainContent, contains('print(Platform.current.isIOS);'));
      expect(mainContent, contains('print(Platform.current.isLinux);'));
      expect(mainContent, contains('print(Platform.current.isMacOS);'));
      expect(mainContent, contains('print(Platform.current.isWindows);'));
      expect(mainContent, contains('print(Platform.current.isFuchsia);'));
      expect(mainContent, contains('print(Platform.current.isBrowser);'));
      expect(mainContent, contains('print(Platform.current.operatingSystem);'));
      expect(mainContent, contains('print(Platform.current.operatingSystemVersion);'));

      // 7. Assert bin/main_no_prefix.dart is migrated correctly
      final mainNoPrefixContent = mainNoPrefixFile.readAsStringSync();
      expect(mainNoPrefixContent, contains("import 'package:platform/platform.dart';"));
      expect(mainNoPrefixContent, contains('print(Platform.current.isAndroid);'));
      expect(mainNoPrefixContent, contains('print(Platform.current.isIOS);'));
      expect(mainNoPrefixContent, contains('print(Platform.current.isLinux);'));
      expect(mainNoPrefixContent, contains('print(Platform.current.isMacOS);'));
      expect(mainNoPrefixContent, contains('print(Platform.current.isWindows);'));
      expect(mainNoPrefixContent, contains('print(Platform.current.isFuchsia);'));
      expect(mainNoPrefixContent, contains('print(Platform.current.isBrowser);'));
      expect(mainNoPrefixContent, contains('print(Platform.current.operatingSystem);'));
      expect(mainNoPrefixContent, contains('print(Platform.current.operatingSystemVersion);'));

      // 8. Assert pubspec.yaml has added package:platform
      final pubspecContent = pubspec.readAsStringSync();
      expect(pubspecContent, contains('platform:'));

    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  });
}
