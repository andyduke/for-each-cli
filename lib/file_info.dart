class FileInfo {
  final String path;
  final String dir;
  final String name;

  FileInfo({
    required this.path,
    required this.dir,
    required this.name,
  });

  @override
  String toString() {
    return 'File: $name, $dir ($path)';
  }
}
