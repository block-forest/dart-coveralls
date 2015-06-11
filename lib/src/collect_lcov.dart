library dart_coveralls.lcov;

import "dart:async" show Future;
import "dart:io";

import "package:coverage/coverage.dart";
import "package:path/path.dart" as p;

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
  final String packageRoot;
  final ProcessSystem processSystem;

  LcovCollector(this.packageRoot,
      {this.processSystem: const ProcessSystem(), this.sdkRoot}) {}

  Future<CoverageResult<String>> convertVmReportsToLcov(
      Directory directoryContainingVmReports, {int workers: 1}) async {
    var reportFiles = await directoryContainingVmReports
        .list(recursive: false, followLinks: false)
        .toList();

    var hitmap = await parseCoverage(reportFiles, workers);
    var resolver = new Resolver(packageRoot: packageRoot, sdkRoot: sdkRoot);
    var formatter = new LcovFormatter(resolver);

    var res = await formatter.format(hitmap);
    return new CoverageResult<String>(res, null);
  }

  // TODO: perhaps provide an option to NOT delete the temp file and instead
  //       print out the path for other tooling
  /// Returns an LCOV string of the tested [File].
  ///
  /// Calculates and returns LCOV information of the tested [File].
  /// This uses [workers] to parse the collected information.
  Future<CoverageResult<String>> getLcovInformation(String testFile,
      {int workers: 1}) async {
    if (!p.isAbsolute(testFile)) {
      throw new ArgumentError.value(
          testFile, 'testFile', 'Must be an absolute path.');
    }

    Directory tempDir =
        await Directory.systemTemp.createTemp('dart_coveralls.');
    try {
      var reportFile = await _getCoverageJson(testFile, tempDir);

      var hitmap = await parseCoverage(reportFile.result, workers);
      var resolver = new Resolver(packageRoot: packageRoot, sdkRoot: sdkRoot);
      var formatter = new LcovFormatter(resolver);

      var res = await formatter.format(hitmap);
      return new CoverageResult<String>(res, reportFile.processResult);
    } finally {
      await tempDir.delete(recursive: true);
    }
  }

  /// Generates and returns a coverage json file
  Future<CoverageResult<List<File>>> _getCoverageJson(
      String testFile, Directory coverageDir) async {
    var args = [
      "--coverage_dir=${coverageDir.path}",
      "--package-root=${packageRoot}",
      testFile
    ];
    var result = await processSystem.runProcess(Platform.executable, args);
    if (result.exitCode < 0) {
      stderr.writeln('stdout:');
      stderr.writeln(result.stdout);
      stderr.writeln('stderr:');
      stderr.writeln(result.stderr);
      throw new ProcessException(Platform.executable, args,
          'There was a critical error. Exit code: ${result.exitCode}',
          result.exitCode);
    }
    var reportFiles =
        await coverageDir.list(recursive: false, followLinks: false).toList();
    return new CoverageResult<List<File>>(reportFiles, result);
  }
}

class CoverageResult<E> {
  final E result;
  final ProcessResult processResult;

  CoverageResult(this.result, this.processResult);

  /// Prints `processResult.stdout`
  ///
  /// If `processResult.exitCode` is not zero, also prints the exit code and
  /// `processResult.stderr`.
  void printSummary() {
    print(processResult.stdout);
    if (processResult.exitCode != 0) {
      print("Process exited with code ${processResult.exitCode}.");
      print(processResult.stderr);
    }
  }
}
