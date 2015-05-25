### 0.2.0

* A number of (breaking) changes to clarify and correctly distinguish between
  `projectDirectory` – the directory containing the source project – and
  `packageRoot` – the directory containing the project packages,
  usually located at `<projectDirectory>/packages`.

* A number of (breaking) changes to pass around paths – as `String` – instead of
  `File` and `Directory` instances.

* `CommandLinePart` and subtypes execute methods are now explicitly async.

* Added a lot more logging, especially in error cases.

* `covString` and related are removed from all classes. Using standard `toJson`
  method supported by `dart:convert` `JSON`.
  
* A number of public helper methods were moved to private, top-level functions.

* Added a `print-json` option to `report`.

* `LcovCollector` now puts coverage output in a temporary directory.

* `CommandLineClient` and `LcovCollector` removed dependency on `FileSystem`.
  Constructors and fields were changed accordingly.
  
* `LcovCollector` now parses *all* coverage output files.
  There is a lot less missed coverage, especially when isolates are being used.
  
* Minimum version of `coverage` was bumped to `0.6.4`.

### 0.1.12

* Support latest versions of `args` and `coverage` packages.

* Require at least Dart 1.9.0 SDK.

* Improved the reporting of errors, especially async errors.

* Add check of `CI_BRANCH` environment variable for Git branch. 
