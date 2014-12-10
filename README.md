dart-coveralls
==============
[![Coverage Status](https://coveralls.io/repos/Adracus/dart-coveralls/badge.png)](https://coveralls.io/r/Adracus/dart-coveralls)

Calculate coverage of your dart scripts, format it to LCOV and send it to coveralls

### Usage
This package consists of three command line tools:

#### Calculate Coverage
This tool calculates the coverage of a given package. Use the tool like this:

```
dart calculate_coverage.dart [--workers, --output, --package-root] test.dart
```

* --workers: The number of workers used to parse LCOV information
* --output: The output file path, if not given stdout
* --package-root: The root of the analyzed package, default `.`
* test.dart: The path of the test file on which coverage will be collected

#### Calculate and Send Coverage
This tool calculates and then sends the coverage data to coveralls.io. Usage of
the tool is as follows:

```
dart calculate_and_send_coverage.dart [--workers, --token, --package-root, --debug, --retry] test.dart
```

* --workers: The number of workers used to parse LCOV information
* --token: The token for coveralls.io
* --package-root: The root of the analyzed package, default `.`
* --debug: Prints additional debug information
* --retry: The number of retries to submit data to coveralls

#### Send Coverage
This tool sends coverage collected in an LCOV-File to coveralls.io.

```
dart send_coverage.dart [--token, --package-root, --retry]
```

* --token: The token for coveralls.io
* --package-root: The root of the analyzed package, default `.`
* --retry: The number of retries to submit data to coveralls


Help and Pull Requests are highly appreciated :)