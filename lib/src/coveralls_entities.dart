library dart_coveralls.coveralls_entities;

import 'dart:io' show Directory, File, Platform, FileSystemEntity, Link;

import 'package:mockable_filesystem/filesystem.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'collect_lcov.dart';
import 'git_data.dart';
import 'log.dart';

class PackageFilter {
  final bool excludeTestFiles;
  final PackageDartFiles dartFiles;
  final String packageName;

  PackageFilter(this.packageName, this.dartFiles,
      {this.excludeTestFiles: false});

  PackageFilter.from(Directory packageDirectory,
      {this.excludeTestFiles: false, FileSystem fileSystem: const FileSystem()})
      : packageName = getPackageName(packageDirectory, fileSystem),
        dartFiles = new PackageDartFiles.from(packageDirectory);

  bool accept(String fileName, [FileSystem fileSystem = const FileSystem()]) {
    log.info("ANALYZING $fileName");

    if (fileName.startsWith(packageName)) {
      log.info("ADDING $fileName");
      return true;
    }

    var file = fileSystem.getFile(fileName);
    log.info(() =>
        "is implementation file? ${dartFiles.isImplementationFile(file)}");
    log.info(() => "is test file? ${dartFiles.isTestFile(file)}");
    if (dartFiles.isImplementationFile(file) ||
        (!excludeTestFiles && dartFiles.isTestFile(file))) {
      log.info("ADDING $fileName");
      return true;
    }
    log.info("IGNORING $fileName");
    return false;
  }

  /// Returns the name of the package located in [packageRoot].
  ///
  /// This searches [packageRoot] for a yaml file, which it then
  /// parses for the top level attribute name, which it then returns.
  static String getPackageName(Directory packageRoot,
      [FileSystem fileSystem = const FileSystem()]) {
    var pubspecFile = fileSystem.getFile(packageRoot.path + "/pubspec.yaml");
    var pubspecContent = pubspecFile.readAsStringSync();
    var yaml = loadYaml(pubspecContent);
    return yaml["name"];
  }
}

class PackageDartFiles {
  final List<File> testFiles;
  final List<File> implementationFiles;

  PackageDartFiles(this.testFiles, this.implementationFiles);

  factory PackageDartFiles.from(Directory packageDirectory) {
    var testFiles = _getTestFiles(packageDirectory).toList();
    var implementationFiles = _getImplementationFiles(packageDirectory).toList();

    testFiles.forEach(
        (file) => log.info("Test file: ${p.normalize(file.absolute.path)}"));

    implementationFiles.forEach((file) =>
        log.info("Implementation file: ${p.normalize(file.absolute.path)}"));

    return new PackageDartFiles(testFiles, implementationFiles);
  }

  bool isTestFile(File file) {
    return testFiles.any((testFile) => sameAbsolutePath(testFile, file));
  }

  bool isImplementationFile(File file) {
    return implementationFiles
        .any((implFile) => sameAbsolutePath(implFile, file));
  }

  static bool isTestDirectory(FileSystemEntity entity) =>
      entity is Directory && "test" == p.basename(entity.path);

  static bool sameAbsolutePath(File f1, File f2) {
    var absolutePath1 = p.normalize(f1.absolute.path);
    var absolutePath2 = p.normalize(f2.absolute.path);
    return absolutePath1 == absolutePath2;
  }
}

/// A Report of a single Source File
class SourceFileReport {
  /// Identification of this [SourceFileReport]
  final SourceFile sourceFile;

  /// The [Coverage] data which was collected for the [sourceFile]
  final Coverage coverage;

  SourceFileReport(this.sourceFile, this.coverage);

  static SourceFileReport parse(LcovPart lcov, Directory packageRoot) {
    var sourceFile = SourceFile.parse(lcov.heading, packageRoot);
    var coverage = Coverage.parse(lcov.content);
    return new SourceFileReport(sourceFile, coverage);
  }

  Map toJson() => {
    "name": sourceFile.name,
    "source": sourceFile.source,
    "coverage": coverage.values.map((lv) => lv.lineCount).toList()
  };
}

class SourceFile {
  final String name;
  final String source;

  SourceFile(this.name, this.source);

  static SourceFile parse(String heading, Directory packageRoot,
      {FileSystem fileSystem: const FileSystem()}) {
    var path = heading.split(":").last;
    var name = resolveName(path, packageRoot, fileSystem: fileSystem);
    var sourceFile = getSourceFile(path, packageRoot, fileSystem: fileSystem);
    var source = sourceFile.readAsStringSync();
    return new SourceFile(name, source);
  }

  static String resolveName(String path, Directory packageRoot,
      {FileSystem fileSystem: const FileSystem()}) {
    var file = fileSystem.getFile(path);
    var sep = Platform.pathSeparator;
    if (!file.isAbsolute) {
      var packagePath = packageRoot.path + "${sep}packages$sep$path";
      file = fileSystem.getFile(packagePath);
      file = fileSystem.getFile(file.resolveSymbolicLinksSync());
    }
    var ctx = new p.Context(current: packageRoot.absolute.path);
    var name = ctx.relative(file.path);
    return name;
  }

  static File getSourceFile(String path, Directory packageRoot,
      {FileSystem fileSystem: const FileSystem()}) {
    var file = fileSystem.getFile(path);
    if (file.existsSync()) {
      return file.absolute;
    }
    file = fileSystem.getFile(packageRoot.path + "/packages/$path");
    file = fileSystem.getFile(file.resolveSymbolicLinksSync());
    return file.absolute;
  }
}

/// [Coverage] represents basic coverage information. Coverage
/// information consists of several LineValues.
class Coverage {
  final List<LineValue> values;

  /// Instantiates a new [Coverage] with the given [LineValue]s.
  Coverage(this.values);

  /// Parses the given LCOV numeration into [LineValue]s and
  /// instantiates a [Coverage] object with the parsed values
  static Coverage parse(String lcovContent) {
    var numeration =
        lcovContent.split("\n").where((str) => str.isNotEmpty).toList();
    var values = [];
    var current = 1;
    for (int i = 0; i < numeration.length; i++) {
      var lineValue = LineValue.parse(numeration[i]);
      int distance = lineValue.lineNumber - values.length - 1;
      if (distance > 0) values.addAll(
          new List.generate(distance, (_) => new LineValue.noCount(current++)));
      values.add(lineValue);
      current++;
    }
    return new Coverage(values);
  }
}

/// A [LineValue] represents a single line in an LCOV-File
class LineValue {
  final int lineNumber;
  final int lineCount;

  /// Instantiates a [LineValue] with the given line number and line count
  LineValue(this.lineNumber, this.lineCount);

  /// Instantiates a [LineValue] with the given line number and line count null
  LineValue.noCount(this.lineNumber) : lineCount = null;

  /// Parses a LineValue from a given LCOV Line and returns a LineValue instance
  ///
  /// An example for an LCOV line is "DA:3,4", which will be parsed into
  /// a [Linevalue] instance with line number 3 and line count 4
  static LineValue parse(String line) {
    var valuePair = line.split(":");
    var values = valuePair[1].split(",");
    var lineNumber = int.parse(values[0]);
    var lineCount = int.parse(values[1]);
    return new LineValue(lineNumber, lineCount);
  }

  String toString() => "$lineNumber:${lineCount}";
}

class SourceFileReports {
  final List<SourceFileReport> sourceFileReports;

  SourceFileReports(this.sourceFileReports);

  static SourceFileReports parse(LcovDocument lcov, Directory packageRoot,
      {bool excludeTestFiles: false}) {
    var filter =
        new PackageFilter.from(packageRoot, excludeTestFiles: excludeTestFiles);

    var relevantParts =
        lcov.parts.where((part) => filter.accept(part.fileName));

    var reports = relevantParts
        .map((part) => SourceFileReport.parse(part, packageRoot))
        .toList();
    return new SourceFileReports(reports);
  }
}

class CoverallsReport {
  final String repoToken;
  final GitData gitData;
  final SourceFileReports sourceFileReports;
  final String serviceName;

  CoverallsReport(
      this.repoToken, this.sourceFileReports, this.gitData, this.serviceName);

  static CoverallsReport parse(String repoToken, LcovDocument lcov,
      Directory packageRoot, String serviceName,
      {bool excludeTestFiles: false}) {
    var gitData = GitData.getGitData(packageRoot);
    var reports = SourceFileReports.parse(lcov, packageRoot,
        excludeTestFiles: excludeTestFiles);
    return new CoverallsReport(repoToken, reports, gitData, serviceName);
  }

  Map toJson() => {
    "repo_token": repoToken,
    "git": gitData,
    "service_name": serviceName,
    "source_files": sourceFileReports.sourceFileReports.toList()
  };
}

/// Yields the Dart files represented by [entity].
///
/// If [entity] is a Dart [File], it is yielded.
///
/// If [entity] is a [Directory], the sub-entities that are Dart files are
/// yielded recursively.
///
/// If the entity is none of the previous types, nothing is yielded.
Iterable<File> _getDartFiles(FileSystemEntity entity) sync* {
  if (entity is File) {
    if (".dart" == p.extension(entity.path)) {
      yield entity;
    }
  } else if (entity is Directory) {
    var subEntities = entity.listSync(recursive: false, followLinks: false);
    yield* subEntities.expand(_getDartFiles);
  }
}

Iterable<File> _getImplementationFiles(Directory packageDirectory) =>
    packageDirectory
        .listSync(recursive: false, followLinks: false)
        .where((entity) => !PackageDartFiles.isTestDirectory(entity))
        .expand(_getDartFiles);

Iterable<File> _getTestFiles(Directory packageDirectory) sync* {
  try {
    Directory testDirectory = packageDirectory
        .listSync(followLinks: false)
        .singleWhere(PackageDartFiles.isTestDirectory) as Directory;
    yield* _getDartFiles(testDirectory);
  } on StateError {}
}
