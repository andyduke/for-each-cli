import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:cli_util/cli_logging.dart';
import 'package:args/args.dart';
// import 'package:args/src/utils.dart' show wrapText;
import 'package:path/path.dart' as p;
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:for_each/file_info.dart';
import 'package:for_each/string_ext.dart';

class ForEachApp {
  final String name = 'For-Each';
  final String version = '1.2';
  final String copyright = 'Copyright (C) 2022 Andy Chentsov <chentsov@gmail.com>';

  String get intro => '$name $version, $copyright';

  static const int usageIndent = 2;
  final String _usage = '''Usage: for-each [<options>] <mask> [in <path>] do <command...>

You can use bash-style substitutions in the <mask>, for example: "assets/**/*.scss". 

Substitutions can be used in <command>:
 - {path} for the full path to the found file;
 - {dir} for the full path to the found file without the file name itself;
 - {file.ext} for the path to the found file relative to <path>;
 - {file} for the path (without extension) to the found file relative to <path>;
 - {name.ext} for the filename with extension;
 - {name} for the filename without extension;
 - {ext} for file extension.

If the <path> is not specified, the current path is used.
''';

  String get usage => '''$_usage
Options:
${_indent('${parser.usage}\n', indent: usageIndent)}
''';

  String mask = '';
  String path = '';
  String command = '';
  List<String> commandArguments = [];

  int? failOn;

  bool dryRun = false;
  bool silent = false;
  bool verbose = false;
  String verbosity = verbosityNormal;

  static const String verbosityNormal = 'normal';
  static const String verbosityDebug = 'debug';

  static int get outputWidth => stdout.hasTerminal ? stdout.terminalColumns : 80;

  final parser = ArgParser(usageLineLength: outputWidth - usageIndent);
  late Logger logger;

  bool _ready = false;

  ForEachApp([List<String> args = const []]) {
    // Parse args: for-each [<opts>] <mask> [in <path>] do <command...>

    // Setup Parser
    setupParser(args);

    // Parse args
    var results = parser.parse(args);
    var rest = results.rest.toList(growable: true);

    failOn = int.tryParse(results['fail-on'] ?? '');
    dryRun = results['dry-run'];

    // Setup Logger
    silent = results['silent'];
    verbose = results['verbose'] && !silent;
    verbosity = results['verbosity'] ?? verbosityNormal;
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
      help: 'Dry run',
    );

    parser.addFlag(
      'silent',
      abbr: 's',
      defaultsTo: false,
      help: 'Silent output',
    );

    parser.addFlag(
      'verbose',
      abbr: 'v',
      defaultsTo: false,
      help: 'Verbose output',
    );

    parser.addOption(
      'verbosity',
      defaultsTo: 'normal',
      help: 'Control output verbosity',
      allowed: [
        'normal',
        'debug',
      ],
      allowedHelp: {
        'normal': 'Shows detailed information about searching for files and running commands',
        'debug': 'Shows more detailed information',
      },
      valueHelp: 'level',
    );

    parser.addOption(
      'fail-on',
      abbr: 'f',
      help: 'Exit with an <exit code> if the exit code of at least one command is greater than <exit code>',
      valueHelp: 'exit code',
      defaultsTo: null,
    );
  }

  Future<void> run() async {
    displayIntro();

    if (!_ready) {
      displayUsage();
      return;
    }

    displaySummary();

    Progress? progress;
    if (!silent) {
      progress = logger.progress('Scanning');
    }

    // scan
    var files = await scan(mask: mask, path: path);

    if (!verbose && !silent) {
      logger.write('\n');
    }

    if (files.isEmpty) {
      if (!silent) {
        logger.write('No files found\n');
      }
    } else {
      for (var file in files) {
        final exitCode = await runBatch(file);
        if (failOn != null && exitCode >= failOn!) {
          if (!silent && progress != null) progress.finish(showTiming: true);

          exit(exitCode);
        }
      }
    }

    if (!silent && progress != null) progress.finish(showTiming: true);

    if (!silent) {
      logger.stdout('\nAll ${logger.ansi.emphasized('done')}.');
      logger.flush();
    }
  }

  String subst(String command, FileInfo file) {
    final result = command
        .replaceAll('{file}', file.basename)
        .replaceAll('{dir}', file.dir)
        .replaceAll('{path}', file.path)
        .replaceAll('{file.ext}', file.name)
        .replaceAll('{ext}', file.ext)
        .replaceAll('{name.ext}', file.filenameExt)
        .replaceAll('{name}', file.filename);
    return result;
  }

  Future<int> runBatch(FileInfo file) async {
    final cmd = subst(command, file);
    final args = commandArguments.map((entry) {
      return subst(entry, file);
    }).toList(growable: false);

    if (dryRun) {
      logger.write('RUN: $cmd ${args.join(' ')}\n');

      return 0;
    } else {
      if (verbosity == verbosityDebug) {
        logger.trace('RUN: $cmd ${args.join(' ')}');
      }

      final batchProcess = await Process.start(
        cmd,
        args,
        runInShell: true,
      );

      unawaited(batchProcess.stdout.transform(utf8.decoder).forEach((s) {
        logger.stdout(s.endsWith('\n') ? s.substring(0, s.length - 1) : s);
      }));
      unawaited(batchProcess.stderr.transform(utf8.decoder).forEach((s) {
        logger.stderr(s.endsWith('\n') ? s.substring(0, s.length - 1) : s);
      }));

      final exitCode = await batchProcess.exitCode;
      return exitCode;
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

      final relativePath = p.relative(entry.path, from: path);

      return FileInfo(
        path: entry.path,
        dir: entry.dirname,
        name: relativePath,
        basename: p.withoutExtension(relativePath),
        ext: p.extension(entry.basename).substring(1),
        filename: p.withoutExtension(entry.basename),
        filenameExt: entry.basename,
      );
    }).toList();

    logger.trace('');

    return results;
  }

  // String _wrap(String text, {int? hangingIndent}) =>
  //     wrapText(text, length: parser.usageLineLength, hangingIndent: hangingIndent ?? outputWidth);

  String _indent(String text, {int indent = 2}) {
    var result = text.replaceAllMapped(RegExp(r'^([^\S\r\n]*)', multiLine: true), (m) {
      if (m.groupCount > 0) {
        // return m[1]!.padLeft(indent);
        return ''.padLeft(indent) + m[1]!;
      } else {
        return m.input;
      }
    });

    return result;
  }
}
