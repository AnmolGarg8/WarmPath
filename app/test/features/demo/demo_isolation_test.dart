import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Guided Demo Isolation & Honesty Architecture Tests', () {
    final demoDir = Directory('lib/features/demo');

    test('All files in features/demo must start with required allow-mock-file header', () {
      expect(demoDir.existsSync(), isTrue, reason: 'features/demo directory must exist');

      final files = demoDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

      expect(files, isNotEmpty);

      for (final file in files) {
        final lines = file.readAsLinesSync();
        expect(
          lines.isNotEmpty,
          isTrue,
          reason: 'File ${file.path} is empty',
        );
        expect(
          lines.first.trim(),
          '// allow-mock-file: guided demo, simulated and labelled',
          reason: 'File ${file.path} must start with exact comment `// allow-mock-file: guided demo, simulated and labelled`',
        );
      }
    });

    test('Guided demo files must NEVER import live network/API/storage dependencies', () {
      final forbiddenImports = [
        'dio',
        'dio_client.dart',
        'api_client.dart',
        'secure_storage.dart',
        'core/api',
        'core/storage',
      ];

      final files = demoDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

      for (final file in files) {
        final importLines = file
            .readAsLinesSync()
            .where((l) => l.trim().startsWith('import ') || l.trim().startsWith('export '))
            .toList();

        for (final line in importLines) {
          for (final forbidden in forbiddenImports) {
            expect(
              line.contains(forbidden),
              isFalse,
              reason: 'File ${file.path} violates isolation by importing "$forbidden" in line: "$line"',
            );
          }

          if (line.contains('features/') && !line.contains('features/demo')) {
            fail('File ${file.path} imports live feature in line: "$line"');
          }
        }
      }
    });

    test('Live features must not import demo (except app_router and entry points)', () {
      final appLibDir = Directory('lib');
      final allowedCallers = [
        'app_router.dart',
        'email_page.dart',
        'profile_page.dart',
      ];

      final files = appLibDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.contains('features${Platform.pathSeparator}demo'))
          .toList();

      for (final file in files) {
        final isAllowed = allowedCallers.any((c) => file.path.endsWith(c));
        if (isAllowed) continue;

        final content = file.readAsStringSync();
        expect(
          content.contains('features/demo'),
          isFalse,
          reason: 'Live non-demo file ${file.path} imports features/demo',
        );
      }
    });
  });
}
