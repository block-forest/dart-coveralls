library dart_coveralls.coveralls_entities;

import 'package:file/file.dart';
import 'package:file/local.dart' show LocalFileSystem;
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:crypto/crypto.dart';

import 'collect_lcov.dart';
import 'git_data.dart';
import 'log.dart';

class PackageFilter {
  final bool excludeTestFiles;
  final PackageDartFiles dartFiles;
  final String packageName;

  PackageFilter(this.packageName, this.dartFiles,
      {this.excludeTestFiles: false});

  PackageFilter.from(String projectDirectory,
      {this.excludeTestFiles: false, FileSystem fileSystem: const LocalFileSystem()})
      : packageName = getPackageName(projectDirectory, fileSystem),
        dartFiles = new PackageDartFiles.from(projectDirectory);

  bool accept(String fileName, [FileSystem fileSystem = const LocalFileSystem()]) {
    log.info("ANALYZING $fileName");

    if (fileName.startsWith(packageName)) {
      log.info("  ADDING $fileName");
      return true;
    }

    var file = fileSystem.file(fileName);
    log.info(
        () => "  implementation file? ${dartFiles.isImplementationFile(file)}");
    log.info(() => "  test file? ${dartFiles.isTestFile(file)}");
    if (dartFiles.isImplementationFile(file) ||
        (!excludeTestFiles && dartFiles.isTestFile(file))) {
      log.info("  ADDING $fileName");
      return true;
    }
    log.info("  IGNORING $fileName");
    return false;
  }

  /// Returns the name of the package located in [projectDirectory].
  ///
  /// This searches [projectDirectory] for a yaml file, which it then
  /// parses for the top level attribute name, which it then returns.
  static String getPackageName(String projectDirectory,
      [FileSystem fileSystem = const LocalFileSystem()]) {
    var pubspecFile =
        fileSystem.file(p.join(projectDirectory, "pubspec.yaml"));
    var pubspecContent = pubspecFile.readAsStringSync();
    var yaml = loadYaml(pubspecContent);
    return yaml["name"];
  }
}

class PackageDartFiles {
  final List<File> testFiles;
  final List<File> implementationFiles;

  PackageDartFiles(this.testFiles, this.implementationFiles);

  factory PackageDartFiles.from(String projectDirectory) {
    var dir = const LocalFileSystem().directory(projectDirectory);
    var testFiles = _getTestFiles(dir).toList();
    var implementationFiles = _getImplementationFiles(dir).toList();

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

  static SourceFileReport parse(LcovPart lcov, String packageDir) {
    var sourceFile = SourceFile.parse(lcov.heading, packageDir);
    var coverage = Coverage.parse(lcov.content);
    return new SourceFileReport(sourceFile, coverage);
  }

  Map toJson() => {
        "name": sourceFile.name,
        "source_digest": sourceFile.sourceDigest,
        "coverage": coverage.values.map((lv) => lv.lineCount).toList()
      };
}

class SourceFile {
  final String name;
  final String sourceDigest;

  SourceFile(this.name, List<int> bytes)
      : sourceDigest = md5.convert(bytes).toString();

  static SourceFile parse(String heading, String packageDir,
      {FileSystem fileSystem: const LocalFileSystem()}) {
    var path = heading.split(":").last;
    var name = resolveName(path, packageDir, fileSystem: fileSystem);
    var sourceFile = getSourceFile(path, packageDir, fileSystem: fileSystem);
    var bytes = sourceFile.readAsBytesSync();
    return new SourceFile(name, bytes);
  }

  static String resolveName(String path, String projectDirectory,
      {FileSystem fileSystem: const LocalFileSystem()}) {
    var file = fileSystem.file(path);
    if (!file.isAbsolute) {
      var packagePath = p.join(projectDirectory, 'packages', path);
      file = fileSystem.file(packagePath);
      file = fileSystem.file(file.resolveSymbolicLinksSync());
    }

    return p.relative(file.path, from: projectDirectory);
  }

  static File getSourceFile(String path, String packageDir,
      {FileSystem fileSystem: const LocalFileSystem()}) {
    var file = fileSystem.file(path);
    if (file.existsSync()) {
      return file.absolute;
    }
    file = fileSystem.file(p.join(packageDir, 'packages', path));
    file = fileSystem.file(file.resolveSymbolicLinksSync());
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
    List<LineValue> values = [];
    var current = 1;
    for (int i = 0; i < numeration.length; i++) {
      var lineValue = LineValue.parse(numeration[i]);
      int distance = lineValue.lineNumber - values.length - 1;
      if (distance > 0)
        values.addAll(new List.generate(
            distance, (_) => new LineValue.noCount(current++)));
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

  static SourceFileReports parse(LcovDocument lcov, String projectDirectory,
      {bool excludeTestFiles: false}) {
    var filter = new PackageFilter.from(projectDirectory,
        excludeTestFiles: excludeTestFiles);

    var relevantParts =
        lcov.parts.where((part) => filter.accept(part.fileName));

    var reports = relevantParts
        .map((part) => SourceFileReport.parse(part, projectDirectory))
        .toList();
    return new SourceFileReports(reports);
  }
}

class CoverallsReport {
  final String repoToken;
  final GitData gitData;
  final SourceFileReports sourceFileReports;
  final String serviceName;
  final String serviceJobId;

  CoverallsReport(this.repoToken, this.sourceFileReports, this.gitData,
      {this.serviceName, this.serviceJobId});

  static CoverallsReport parse(
      String repoToken, LcovDocument lcov, String projectDirectory,
      {String serviceName, String serviceJobId, bool excludeTestFiles: false}) {
    var gitData = GitData.getGitData(const LocalFileSystem().directory(projectDirectory));
    var reports = SourceFileReports.parse(lcov, projectDirectory,
        excludeTestFiles: excludeTestFiles);
    return new CoverallsReport(repoToken, reports, gitData,
        serviceName: serviceName, serviceJobId: serviceJobId);
  }

  Map toJson() {
    var data = <String, dynamic>{
      "repo_token": repoToken,
      "git": gitData,
      "source_files": sourceFileReports.sourceFileReports.toList()
    };

    if (serviceName != null) {
      data['service_name'] = serviceName;
    }

    if (serviceJobId != null) {
      data['service_job_id'] = serviceJobId;
    }

    return data;
  }
}

/// Represents a successful coverage report to Coveralls.
class CoverallsResult {
  final String message;
  final Uri url;

  CoverallsResult(this.message, this.url);

  factory CoverallsResult.fromJson(Map<String, dynamic> json) =>
      new CoverallsResult(json['message'], Uri.parse(json['url']));
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

Iterable<File> _getImplementationFiles(Directory projectDirectory) =>
    projectDirectory
        .listSync(recursive: false, followLinks: false)
        .where((entity) => !PackageDartFiles.isTestDirectory(entity))
        .expand(_getDartFiles);

Iterable<File> _getTestFiles(Directory projectDirectory) sync* {
  try {
    Directory testDirectory = projectDirectory
        .listSync(followLinks: false)
        .singleWhere(PackageDartFiles.isTestDirectory) as Directory;
    yield* _getDartFiles(testDirectory);
  } on StateError {}
}
