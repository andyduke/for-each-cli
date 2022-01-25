# For-Each

A cross-platform command line utility that allows you to recursively search for files by mask in a specific directory and run the specified command for each found file.

```
Usage: for-each [<options>] <mask> [in <path>] do <command...>

You can use bash-style substitutions in the <mask>, for example: "assets/**/*.scss".

Substitutions can be used in <command>:
 - {path} for the full path to the found file;
 - {dir} for the full path to the found file without the file name itself;
 - {file.ext} for the path to the found file relative to <path>;
 - {file} for the path (without extension) to the found file relative to <path>;
 - {ext} for file extension.

If the <path> is not specified, the current path is used.

Options:
  -d, --[no-]dry-run              Dry run
  -s, --[no-]silent               Silent output
  -v, --[no-]verbose              Verbose output
      --verbosity=<level>         Control output verbosity

            [debug]               Shows more detailed information
            [normal] (default)    Shows detailed information about searching for files and running commands

  -f, --fail-on=<exit code>       Exit with an <exit code> if the exit code of at least one command is greater than <exit code>
```
