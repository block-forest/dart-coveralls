library dart_coveralls.lcov;

import "dart:async" show Completer, Future;
import "dart:io";
import "dart:convert" show utf8;

import "package:coverage/coverage.dart";
import "package:coverage/src/util.dart" as util;
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
  final String packagesPath;
  final ProcessSystem processSystem;
  final bool previewDart2;

  LcovCollector(
      {this.packageRoot,
      this.packagesPath,
      this.processSystem: const ProcessSystem(),
      this.sdkRoot,
      this.previewDart2: false}) {}

  Future<String> convertVmReportsToLcov(
      Directory directoryContainingVmReports) async {
    var reportFiles = await directoryContainingVmReports
        .list(recursive: false, followLinks: false)
        .toList();

    var hitmap = await parseCoverage(reportFiles as Iterable<File>, null);
    return await _formatCoverageJson(hitmap);
  }

  /// Returns an LCOV string of the tested [File].
  ///
  /// Calculates and returns LCOV information of the tested [File].
  Future<String> getLcovInformation(String testFile) async {
    if (!p.isAbsolute(testFile)) {
      throw new ArgumentError.value(
          testFile, 'testFile', 'Must be an absolute path.');
    }

    var reportFile = await _getCoverageJson(testFile);
    if (reportFile == null) {
      return null;
    }

    Map<String, Map<int, int>> hitmap = {};
    mergeHitmaps(createHitmap(reportFile), hitmap);
    return await _formatCoverageJson(hitmap);
  }

  /// Formats coverage hitmap json to an lcov string
  Future<String> _formatCoverageJson(Map<dynamic, dynamic> hitmap) {
    var resolver;
    if (packageRoot != null) {
      resolver = new Resolver(packageRoot: packageRoot, sdkRoot: sdkRoot);
    } else {
      resolver = new Resolver(packagesPath: packagesPath, sdkRoot: sdkRoot);
    }
    var formatter = new LcovFormatter(resolver);
    return formatter.format(hitmap);
  }

  /// Generates and returns a coverage json file
  Future<List<Map<String, dynamic>>> _getCoverageJson(String testFile) async {
    bool terminated = false;

    var dartArgs = ["--pause-isolates-on-exit", "--enable-vm-service"];
    if (packageRoot != null) {
      dartArgs.add("--package-root=${packageRoot}");
    } else {
      dartArgs.add("--packages=${packagesPath}");
    }
    if (previewDart2) {
      dartArgs.add("--preview-dart-2");
    }
    dartArgs.add(testFile);

    Process process =
        await processSystem.startProcess(Platform.executable, dartArgs);
    process.exitCode.then((exitCode) {
      if (exitCode < 0 && !terminated) {
        throw new ProcessException(Platform.executable, dartArgs,
            'There was a critical error. Exit code: ${exitCode}', exitCode);
      }
    });

    Completer<Uri> hostCompleter = new Completer<Uri>();
    process.stdout.transform(utf8.decoder).listen((data) {
      Uri uri = util.extractObservatoryUri(data);
      if (uri != null) {
        hostCompleter.complete(uri);
      }
    });
    Uri host = await hostCompleter.future;

    try {
      Map<String, dynamic> coverageResults =
          await collect(host, true, true, timeout: new Duration(seconds: 60));
      return coverageResults['coverage'];
    } catch (e) {
      print(e);
      return null;
    } finally {
      terminated = true;
      process.kill();
    }
  }
}
