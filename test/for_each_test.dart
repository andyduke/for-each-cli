import 'dart:io';
import 'package:for_each/for_each.dart';
import 'package:test/test.dart';

void main() {
  group('ForEach:', () {
    final app = ForEachApp();
    final dart = '${Platform.environment['FLUTTER_HOME']}/bin/dart';
    final workingDir = Directory.current.path;
    final appPath = 'bin/for_each.dart';

    Future<ProcessResult> forEach([List<String> args = const [], bool debug = false]) async {
      final cmd = '$dart run $appPath ${args.join(' ')}';

      if (debug) {
        print('$cmd\nWorking directory: $workingDir');
      }

      final result = await Process.run(
        cmd,
        [],
        runInShell: true,
        workingDirectory: workingDir,
      );

      if (debug) {
        print(result.stderr);
        print(result.stdout);
      }

      return result;
    }

    test('Usage', () async {
      final result = await forEach();

      expect(result.exitCode, 99);
      expect(result.stdout, '${app.name} ${app.version}, ${app.copyright}\n\n${app.usage}');
    });

    test('List dart files', () async {
      final result = await forEach(['*.dart do echo {file}']);

      expect(result.exitCode, 0);
      expect(result.stdout, '''
${app.intro}

Scanning...

bin\\for_each.dart
lib\\file_info.dart
lib\\for_each.dart
lib\\string_ext.dart
test\\for_each_test.dart
''');
    });

    test('Silent list dart files', () async {
      final result = await forEach(['-s *.dart do echo {file}']);

      expect(result.exitCode, 0);
      expect(result.stdout, '''
bin\\for_each.dart
lib\\file_info.dart
lib\\for_each.dart
lib\\string_ext.dart
test\\for_each_test.dart
''');
    });

    test('List dart files inside "lib" only (using path)', () async {
      final result = await forEach(['-s *.dart in $workingDir\\lib do echo {file}']);

      expect(result.exitCode, 0);
      expect(result.stdout, '''
file_info.dart
for_each.dart
string_ext.dart
''');
    });

    test('List dart files inside "lib" only', () async {
      final result = await forEach(['-s lib/**.dart in $workingDir do echo {file}']);

      expect(result.exitCode, 0);
      expect(result.stdout, '''
lib\\file_info.dart
lib\\for_each.dart
lib\\string_ext.dart
''');
    });
  });
}
