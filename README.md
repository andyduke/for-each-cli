# For-Each

A cross-platform command line utility that allows you to recursively search for files by mask in a specific directory and run the specified command for each found file or for all files in one run of the command.

## Usage

```
for-each [<options>] <mask> [in <path>] do [finally] <command...>
```

You can use bash-style substitutions in the `<mask>`, for example: `"assets/**/*.scss"`.

### Substitutions

Substitutions can be used in `<command>`:
 - `{path}` for the full path to the found file;
 - `{dir}` for the full path to the found file without the file name itself;
 - `{parent-dir}` for the path to the parent directory of the found file;
 - `{file.ext}` for the path to the found file relative to `<path>`;
 - `{file}` for the path (without extension) to the found file relative to `<path>`;
 - `{name.ext}` for the filename with extension;
 - `{name}` for the filename without extension;
 - `{ext}` for file extension.

If the <path> is not specified, the current path is used.

### Finally run mode

If the **finally** keyword is specified before the command,
then the command will be executed once for all found files.

In the finally command, you can use variable substitution in
the format "[text pattern]", inside "text pattern" you can use
the substitutions [described above](#substitutions) for a regular command.
Such patterns will be replicated for each found file.

Example:
> for-each \*.\* in example-project-folder do finally echo [Found: {name.ext};]

If the files "file1.txt" and "file2.dat" are found, the following command will be executed:
> echo Found: file1.txt; Found: file2.dat;

## Options
```
  -d, --dry-run                   Dry run
  -s, --silent                    Silent output
  -v, --verbose                   Verbose output
      --verbosity=<level>         Control output verbosity

            [debug]               Shows more detailed information
            [normal] (default)    Shows detailed information about searching for files and running commands

  -f, --fail-on=<exit code>       Exit with an <exit code> if the exit code of at least one command is greater than <exit code>.
                                  Ignored for the finally command.
      --version                   Prints the version of the For-Each
```
