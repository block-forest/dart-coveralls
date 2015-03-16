library dart_coveralls.lcov;

import "dart:async" show Future;
import "dart:io";

import "package:coverage/coverage.dart";
import "package:mockable_filesystem/filesystem.dart" show FileSystem;
import "package:path/path.dart";

import "process_system.dart";

class LcovDocument {
  final List<LcovPart> parts;

  LcovDocument(this.parts);

  /// Parses a string representation of an lcov document
  static LcovDocument parse(String lcovDocument) {
    var parts = lcovDocument.split("end_of_record\n")
      ..removeWhere((str) => str.isEmpty);
    var lcovParts = parts.map(LcovPart.parse).toList();
    return new LcovDocument(lcovParts);
  }

  String toString() => parts.map((part) => part.toString()).join("\n");
}

class LcovPart {
  final String heading;
  final String content;

  LcovPart(this.heading, this.content);

  /// Parses a part of an LCOV document, with or without end_of_record
  static LcovPart parse(String lcovPart) {
    var firstLineEnd = lcovPart.indexOf("\n");
    var heading = lcovPart.substring(0, firstLineEnd);

    var end = lcovPart.indexOf("\nend_of_record");
    if (-1 == end) end = null; // If "end_of_record" is missing, take rest
    var content =
        lcovPart.substring(firstLineEnd + 1, end); // Skip newline symbol

    return new LcovPart(heading, content);
  }

  String get fileName => heading.split(":").last;

  String toString() => heading;
}

class LcovCollector {
  final String sdkRoot;
  final File testFile;
  final Directory packageRoot;
  final FileSystem fileSystem;
  final ProcessSystem processSystem;

  LcovCollector(this.packageRoot, this.testFile,
      {this.fileSystem: const FileSystem(),
      this.processSystem: const ProcessSystem(), this.sdkRoot});

  /// Returns an LCOV string of the tested [File].
  ///
  /// Calculates and returns LCOV information of the tested [File].
  /// This uses [workers] to parse the collected information.
  Future<CoverageResult<String>> getLcovInformation({int workers: 1}) {
    var reportFile = getCoverageJson();
    return parseCoverage([reportFile.result], workers).then((hitmap) {
      var resolver =
          new Resolver(packageRoot: packageRoot.path, sdkRoot: sdkRoot);
      var formatter = new LcovFormatter(resolver);
      reportFile.result.deleteSync();
      return formatter
          .format(hitmap)
          .then((res) => new CoverageResult(res, reportFile.processResult));
    });
  }

  /// Generates and returns a coverage json file
  CoverageResult<File> getCoverageJson() {
    var current = fileSystem.getDirectory(fileSystem.currentDirectory);
    var args = [
      "--enable-vm-service:9999",
      "--coverage_dir=${current.path}",
      testFile.absolute.path
    ];
    var process = processSystem.runProcessSync("dart", args);
    var reportFile = getYoungestDartCoverageFile(current);
    return new CoverageResult<File>(reportFile, process);
  }

  /// Checks the given directory for the most recently changed dart coverage file
  static File getYoungestDartCoverageFile(Directory dir,
      {bool recursive: false}) {
    var files = dir.listSync(recursive: recursive);
    var coverageFiles = files
        .where(isDartCoverageEntity)
        .map((f) => f as File)
        .toList() as List<File>;
    return youngestElement(coverageFiles);
  }

  /// Returns the most recently changed file among the given files
  static File youngestElement(Iterable<File> files) {
    if (files.isEmpty) throw new Exception("Empty iterable");

    var max = files.first;
    var maxStats = max.statSync();
    var iterable = files.skip(1);

    for (var file in iterable) {
      var stats = file.statSync();
      if (0 > stats.changed.compareTo(maxStats.changed)) {
        maxStats = stats;
        max = file;
      }
    }

    return max;
  }

  /// Checks if the given entity is a file and checks its name against a pattern
  static bool isDartCoverageEntity(FileSystemEntity file) {
    if (file is! File) return false;
    var name = basename(file.path);
    return name.startsWith("dart-cov") && name.endsWith(".json");
  }

  /// Returns the root path of the Dart SDK
  ///
  /// If the given environment is null, it will be [Platform].environment.
  /// This checks the environment for "DART_SDK". If it exists, this
  /// will return the normalized, absolute form of the path
  /// to the dart sdk joined with "lib", otherwise this returns null.
  static String getSDKRootPath([Map<String, String> environment]) {
    if (null == environment) environment = Platform.environment;
    if (environment.containsKey("DART_SDK")) return join(
        absolute(normalize(environment["DART_SDK"])), "lib");
    return null;
  }
}

class CoverageResult<E> {
  final E result;
  final ProcessResult processResult;

  CoverageResult(this.result, this.processResult);
}
