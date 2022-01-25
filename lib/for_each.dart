import 'dart:io';
import 'package:cli_util/cli_logging.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:for_each/file_info.dart';
import 'package:for_each/string_ext.dart';

class ForEachApp {
  final String name = 'For-Each';
  final String version = '1.1';
  final String copyright = 'Copyright (C) 2022 Andy Chentsov <chentsov@gmail.com>';

  String get intro => '$name $version, $copyright';

  final String usage = '''Usage: for-each [<options>] <mask> [in <path>] do <command...>

You can use bash-style substitutions in the <mask>, for example: "assets/**/*.scss". 

Substitutions can be used in <command>:
 - {path} for the full path to the found file;
 - {dir} for the full path to the found file without the file name itself;
 - {name} for the path to the found file relative to <path>.

If the <path> is not specified, the current path is used.

Options:
  -d, --dry-run\t\t\tDry run
  -s, --silent\t\t\tSilent output
  -v, --verbose\t\t\tVerbose output

''';

  String mask = '';
  String path = '';
  String command = '';
  List<String> commandArguments = [];

  bool dryRun = false;
  bool silent = false;
  bool verbose = false;

  final parser = ArgParser();
  late Logger logger;

  bool _ready = false;

  ForEachApp([List<String> args = const []]) {
    // Parse args: for-each [<opts>] <mask> [in <path>] do <command...>

    // Setup Parser
    setupParser(args);

    // Parse args
    var results = parser.parse(args);
    var rest = results.rest.toList(growable: true);

    dryRun = results['dry-run'];

    // Setup Logger
    silent = results['silent'];
    verbose = results['verbose'] && !silent;
    logger = verbose ? Logger.verbose(logTime: false) : Logger.standard();

    if (rest.isEmpty) return;

    // mask
    mask = rest.removeAt(0).trimChar('"');

    // in
    if (rest.first == 'in') {
      rest.removeAt(0); // remove in
      path = rest.removeAt(0).trimChar('"');
    } else {
      path = Directory.current.path;
    }

    // command
    if (rest.first == 'do') {
      rest.removeAt(0);
    }

    if (rest.isEmpty) return;

    // command = rest.join(' ').trimChar('"');
    command = rest.removeAt(0).trimChar('"');
    commandArguments = rest;

    _ready = true;
  }

  void displayIntro() {
    if (!silent) {
      logger.write('$intro\n\n');
    }
  }

  void displayUsage() {
    logger.write(usage);

    exitApp(99);
  }

  void displaySummary() {
    logger.trace(' - Mask: $mask');
    logger.trace(' - Path: $path');
    logger.trace(' - Command: $command ${commandArguments.join(' ')}');
    logger.trace('');
  }

  void exitApp(int exitCode) {
    exit(exitCode);
  }

  void setupParser(List<String> args) {
    parser.addFlag(
      'dry-run',
      abbr: 'd',
      defaultsTo: false,
    );

    parser.addFlag(
      'verbose',
      abbr: 'v',
      defaultsTo: false,
    );

    parser.addFlag(
      'silent',
      abbr: 's',
      defaultsTo: false,
    );
  }

  Future<void> run() async {
    displayIntro();

    if (!_ready) {
      displayUsage();
      return;
    }

    displaySummary();

    if (!silent) {
      logger.progress('Scanning');
    }

    // scan
    var files = await scan(mask: mask, path: path);

    // logger.write('$files');

    if (!verbose && !silent) {
      logger.write('\n');
    }

    if (files.isEmpty) {
      if (!silent) {
        logger.write('No files found\n');
      }
    } else {
      for (var file in files) {
        await runBatch(file);
      }
    }
  }

  String subst(String command, FileInfo file) {
    final result =
        command.replaceFirst('{file}', file.name).replaceFirst('{dir}', file.dir).replaceFirst('{path}', file.path);
    return result;
  }

  Future<int> runBatch(FileInfo file) async {
    final cmd = subst(command, file);
    final args = commandArguments.map((entry) {
      return subst(entry, file);
    }).toList(growable: false);

    // logger.trace('Run: $cmd');

    if (dryRun) {
      logger.write('RUN: $cmd ${args.join(' ')}\n');

      return 0;
    } else {
      final result = await Process.run(
        cmd,
        args,
        runInShell: true,
      );

      final err = result.stderr.toString().trim();
      final out = result.stdout.toString().trim();

      if (err.isNotEmpty) {
        logger.stderr(err);
      }
      if (out.isNotEmpty) {
        logger.stdout(out);
      }

      return result.exitCode;
    }
  }

  Future<List<FileInfo>> scan({
    required String mask,
    required String path,
  }) async {
    final globMask = mask.startsWith('**') ? mask : '*$mask';
    final glob = Glob(globMask);

    // logger.trace('Scan $globMask in $path');
    // print('Scan $globMask in $path');

    final results = await glob.list(root: path).map((entry) {
      logger.trace('  ${entry.path}');

      // print(' * ${entry.path}');

      return FileInfo(
        path: entry.path,
        dir: entry.dirname,
        name: p.relative(entry.path, from: path),
      );
    }).toList();

    logger.trace('');

    return results;
  }
}
