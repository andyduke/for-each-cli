# For-Each

A cross-platform command line utility that allows you to recursively search for files by mask in a specific directory and run the specified command for each found file.

```
Usage: for-each [<options>] <mask> [in <path>] do <command...>

You can use bash-style substitutions in the <mask>, for example: "assets/**/*.scss".

Substitutions can be used in <command>:
 - {path} for the full path to the found file;
 - {dir} for the full path to the found file without the file name itself;
 - {name} for the path to the found file relative to <path>.

If the <path> is not specified, the current path is used.

Options:
  -s, --silent                  Silent output
  -v, --verbose                 Verbose output
```
