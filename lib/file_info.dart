class FileInfo {
  /// Full path to the file along with its name
  final String path;

  /// The directory where the file is located
  final String dir;

  /// Relative file path
  final String name;

  /// Relative file path without extension
  final String basename;

  /// File extension
  final String ext;

  FileInfo({
    required this.path,
    required this.dir,
    required this.name,
    required this.basename,
    required this.ext,
  });

  @override
  String toString() {
    return 'File: $name [$basename.$ext], $dir ($path)';
  }
}
