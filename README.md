dart-coveralls
==============

[![Build Status](https://travis-ci.org/block-forest/dart-coveralls.svg?branch=master)](https://travis-ci.org/block-forest/dart-coveralls)
[![Coverage Status](https://coveralls.io/repos/github/block-forest/dart-coveralls/badge.svg?branch=master)](https://coveralls.io/github/block-forest/dart-coveralls?branch=master)

Calculate coverage of your dart scripts, format it to LCOV and send it to
[coveralls.io](https://coveralls.io/).


*NOTE:* as of version 0.6.0 `dart-coveralls`, requires a Dart 2 SDK. 

### Usage
This package consists of a single command line tool `dart_coveralls` with
the three commands `calc`, `report`, `upload`.

To activate the program for global use, run `pub global activate dart_coveralls`.

#### The `calc` command
This command calculates the coverage of a given package. Use the tool like this:

```
dart_coveralls calc [--output, --package-root] test.dart
# or
dart_coveralls calc [--output, --packages] test.dart
```

* `--output`: The output file path, if not given stdout
* `--packages`: Specifies the path to the package resolution configuration file. 
   This option cannot be used with --package-root. Defaults to ".packages".
* `--package-root`: Specifies where to find imported libraries. 
   This option cannot be used with --packages. Defaults to null.
* `test.dart`: The path of the test file on which coverage will be collected

#### The `report` command
This command calculates and then sends the coverage data to coveralls.io. Usage
of the tool is as follows:

```
dart_coveralls report <options> <test file>
```

* `--help` – Displays all options
* `--token` –Token for coveralls
* `--packages`: Specifies the path to the package resolution configuration file. 
   This option cannot be used with --package-root. Defaults to ".packages".
* `--package-root`: Specifies where to find imported libraries. 
   This option cannot be used with --packages. Defaults to null.
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
* `--packages`: Specifies the path to the package resolution configuration file. 
   This option cannot be used with --package-root. Defaults to ".packages".
* `--package-root`: Specifies where to find imported libraries. 
   This option cannot be used with --packages. Defaults to null.
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
