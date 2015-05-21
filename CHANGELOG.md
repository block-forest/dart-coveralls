### 0.2.0

* `CommandLinePart` and subtypes execute methods are now explicitly async.

* Added a lot more logging, especially in error cases.

* `covString` and related are removed from all classes. Using standard `toJson`
  method supported by `dart:convert` `JSON`.

### 0.1.12

* Support latest versions of `args` and `coverage` packages.

* Require at least Dart 1.9.0 SDK.

* Improved the reporting of errors, especially async errors.

* Add check of `CI_BRANCH` environment variable for Git branch. 
