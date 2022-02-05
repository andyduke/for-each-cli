import 'package:file/file.dart';
import 'package:path/path.dart' as p;

class FileInfo {
  /// Search path
  final String basePath;

  /// File system entry
  final FileSystemEntity entry;

  final String relativePath;

  /// Full path to the file along with its name
  // final String path;

  /// The directory where the file is located
  // final String dir;

  /// Relative file path
  // final String name;

  /// Relative file path without extension
  // final String basename;

  /// File extension
  // final String ext;

  /// Filename without extension
  // final String filename;

  /// Filename with extension
  // final String filenameExt;

  FileInfo({
    required this.basePath,
    required this.entry,
    // required this.path,
    // required this.dir,
    // required this.name,
    // required this.basename,
    // required this.ext,
    // required this.filename,
    // required this.filenameExt,
  }) : relativePath = p.relative(entry.path, from: basePath);

  @override
  String toString() {
    return 'File: $name [$basename.$ext], $dir ($path)';
  }

  /// Parent path
  String get parentPath => p.dirname(dir);

  /// Full path to the file along with its name
  String get path => entry.path;

  /// The directory where the file is located
  String get dir => entry.dirname;

  /// Relative file path
  String get name => relativePath;

  /// Relative file path without extension
  String get basename => p.withoutExtension(relativePath);

  /// File extension
  String get ext => p.extension(entry.basename).substring(1);

  /// Filename without extension
  String get filename => p.withoutExtension(entry.basename);

  /// Filename with extension
  String get filenameExt => entry.basename;
}
