dart-coveralls
==============
[![Build Status](https://travis-ci.org/duse-io/dart-coveralls.svg?branch=master)](https://travis-ci.org/duse-io/dart-coveralls) [![Coverage Status](https://coveralls.io/repos/duse-io/dart-coveralls/badge.svg)](https://coveralls.io/r/duse-io/dart-coveralls)

Calculate coverage of your dart scripts, format it to LCOV and send it to
[coveralls.io](https://coveralls.io/).

### Usage
This package consists of a single command line tool `dart_coveralls` with
the two commands `calc`, `report`.

To activate the program for global use, run `pub global activate dart_coveralls`.

#### The `calc` command
This command calculates the coverage of a given package. Use the tool like this:

```
dart_coveralls calc [--workers, --output, --package-root] test.dart
```

* `--workers`: The number of workers used to parse LCOV information
* `--output`: The output file path, if not given stdout
* `--package-root`: The root of the analyzed package, default `.`
* `test.dart`: The path of the test file on which coverage will be collected

#### The `report` command
This command calculates and then sends the coverage data to coveralls.io. Usage
of the tool is as follows:

```
dart_coveralls report [--workers, --token, --package-root, --debug, --retry] test.dart
```

* `--workers`: The number of workers used to parse LCOV information
* `--token`: The token for coveralls.io. The token can also be set as an
  environment variable called `REPO_TOKEN`.
* `--package-root`: The root of the analyzed package, default `.`
* `--debug`: Prints additional debug information
* `--retry`: The number of retries to submit data to coveralls
* `--dry-run`: Choose this if the collected data shouldn't be submitted
  to coveralls.
* `--throw-on-connectivity-error`: Should this throw if there is a connectivity
  error with coveralls?
* `--throw-on-error`: Should this throw if there is an error in the dart
  coveralls library?
* `--exclude-test-files`: Should test files be excluded for the coveralls report?
* `test.dart`: The path of the test file on which coverage will be collected

### Contributing

Help and Pull Requests are highly appreciated :)
