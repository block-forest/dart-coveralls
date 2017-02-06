dart-coveralls
==============
> This is not under active development anymore. No fixes or enhancements will be done.
> If one is willing to maintain and develop this, please contact me to talk about the
> handover.

[![Build Status](https://travis-ci.org/duse-io/dart-coveralls.svg?branch=master)](https://travis-ci.org/duse-io/dart-coveralls) [![Coverage Status](https://coveralls.io/repos/duse-io/dart-coveralls/badge.svg)](https://coveralls.io/r/duse-io/dart-coveralls)

Calculate coverage of your dart scripts, format it to LCOV and send it to
[coveralls.io](https://coveralls.io/).

### Usage
This package consists of a single command line tool `dart_coveralls` with
the three commands `calc`, `report`, `upload`.

To activate the program for global use, run `pub global activate dart_coveralls`.

#### The `calc` command
This command calculates the coverage of a given package. Use the tool like this:

```
dart_coveralls calc [--workers, --output, --package-root] test.dart
```

* `--workers`: The number of workers used to parse LCOV information
* `--output`: The output file path, if not given stdout
* `--packages`: Where to find the packages file, that is, "package:..." imports.
  (defaults to ".packages")
* `--package-root`: Ignored/Deprecated. Package directories are no longer supported.
  (defaults to ".packages")
* `test.dart`: The path of the test file on which coverage will be collected

#### The `report` command
This command calculates and then sends the coverage data to coveralls.io. Usage
of the tool is as follows:

```
dart_coveralls report <options> <test file>
```

* `--help` – Displays all options
* `--token` –Token for coveralls
* `--workers` – Number of workers for parsing
  (defaults to "1")
* `--packages`: Where to find the packages file, that is, "package:..." imports.
  (defaults to ".packages")
* `--package-root`: Ignored/Deprecated. Package directories are no longer supported.
  (defaults to ".packages")
* `--debug` Prints debug information
* `--retry` Number of retries
  (defaults to "10")
* `--dry-run` If this flag is enabled, data won't be sent to coveralls
* `-C, --throw-on-connectivity-error`
  Should this throw an exception, if the upload to coveralls fails?
* `-E, --throw-on-error`
  Should this throw if an error in the dart_coveralls implementation happens?
* `-T, --exclude-test-files`
  Should test files be included in the coveralls report?
* `-p, --print-json`
  Pretty-print the json that will be sent to coveralls.

#### The `upload` command
This command uploads a coverage report.

```
dart_coveralls upload <options> <directory containing coverage reports from the VM>
```

* `--help` – Displays all options
* `--token` –Token for coveralls
* `--workers` – Number of workers for parsing
  (defaults to "1")
* `--packages`: Where to find the packages file, that is, "package:..." imports.
  (defaults to ".packages")
* `--package-root`: Ignored/Deprecated. Package directories are no longer supported.
  (defaults to ".packages")
* `--debug` Prints debug information
* `--retry` Number of retries
  (defaults to "10")
* `--dry-run` If this flag is enabled, data won't be sent to coveralls
* `-C, --throw-on-connectivity-error`
  Should this throw an exception, if the upload to coveralls fails?
* `-E, --throw-on-error`
  Should this throw if an error in the dart_coveralls implementation happens?
* `-T, --exclude-test-files`
  Should test files be included in the coveralls report?
* `-p, --print-json`
  Pretty-print the json that will be sent to coveralls.

### Contributing

Help and Pull Requests are highly appreciated :)
