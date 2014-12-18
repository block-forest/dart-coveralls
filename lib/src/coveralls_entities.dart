library dart_coveralls.coveralls_entities;

import 'dart:convert' show JSON;
import 'dart:io' show Directory, File, Platform;
import 'package:dart_coveralls/dart_coveralls.dart';
import 'package:mockable_filesystem/filesystem.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

/// An interface for Coveralls-Convertable Entity
abstract class CoverallsReportable {
  /// Converts this into a json representation for Coveralls
  String covString();
}


/// A Report of a single Source File
class SourceFileReport implements CoverallsReportable {
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
  
  static bool isPartOfInterest(LcovPart lcovPart, String packageName,
                                 {FileSystem fileSystem: const FileSystem()}) {
    var path = lcovPart.heading.split(":").last;
    var file = fileSystem.getFile(path);
    if (path.startsWith(packageName) || file.isAbsolute) { //test file if absolute
      log.info("ADDING $path");
      return true;
    }
    log.info("IGNORING $path");
    return false;
  }
  
  
  String covString() => "{" + sourceFile.covString() + ", " +
      coverage.covString() + "}";
}



class SourceFile implements CoverallsReportable {
  final String name;
  final String source;
  
  
  SourceFile(this.name, this.source);
  
  static SourceFile parse(String heading, Directory packageRoot,
                   {FileSystem fileSystem: const FileSystem()}) {
    var path = heading.split(":").last;
    var name = resolveName(path, packageRoot, fileSystem: fileSystem);
    var sourceFile = getSourceFile(path, packageRoot,
        fileSystem: fileSystem);
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
    var ctx = new Context(current: packageRoot.absolute.path);
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
  
  
  String covString() =>
      "\"name\": \"$name\", \"source\": ${JSON.encode(source)}";
  }
  
  
  /// [Coverage] represents basic coverage information. Coverage
  /// information consists of several LineValues.
  class Coverage implements CoverallsReportable {
  final List<LineValue> values;
  
  /// Instantiates a new [Coverage] with the given [LineValue]s.
  Coverage(this.values);
  
  
  /// Parses the given LCOV numeration into [LineValue]s and
  /// instantiates a [Coverage] object with the parsed values
  static Coverage parse(String lcovContent) {
    var numeration = lcovContent.split("\n")
                                .where((str) => str.isNotEmpty).toList();
    var values = [];
    var current = 1;
    for (int i = 0; i < numeration.length; i++) {
      var lineValue = LineValue.parse(numeration[i]);
      int distance = lineValue.lineNumber - values.length - 1;
      if (distance > 0)
        values.addAll(new List.generate(distance, (_) =>
            new LineValue.noCount(current++)));
      values.add(lineValue);
      current++;
    }
    return new Coverage(values);
  }
  
  
  String covString() =>
      "\"coverage\": [" +
          values.map((val) => val.covString()).join(", ") + "]";
}


/// A [LineValue] represents a single line in an LCOV-File
class LineValue implements CoverallsReportable {
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
  
  
  String covString() => lineCountRepresentation();
  
  String lineCountRepresentation() =>
      lineCount == null ? "null" : "$lineCount";
  
  String toString() => "$lineNumber:${lineCountRepresentation()}";
}



class SourceFileReports implements CoverallsReportable {
  final List<SourceFileReport> sourceFileReports;
  
  
  SourceFileReports(this.sourceFileReports);
  
  
  static SourceFileReports parse(LcovDocument lcov, Directory packageRoot) {
    var packageName = getPackageName(packageRoot);
    var relevantParts = lcov.parts.where((part) =>
        SourceFileReport.isPartOfInterest(part, packageName));
    var reports = relevantParts.map((part) =>
        SourceFileReport.parse(part, packageRoot)).toList();
    return new SourceFileReports(reports);
  }
  
  
  String covString() => "\"source_files\": [" +
      sourceFileReports.map((rep) => rep.covString()).join(", ") + "]";
  
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



class CoverallsReport implements CoverallsReportable {
  final String repoToken;
  final GitData gitData;
  final SourceFileReports sourceFileReports;
  final String serviceName;
  
  
  CoverallsReport(this.repoToken, this.sourceFileReports,
      this.gitData, this.serviceName);
  
  
  static CoverallsReport parse(String repoToken, LcovDocument lcov,
      Directory packageRoot, String serviceName) {
    var gitData = GitData.getGitData(packageRoot);
    var dirName = basename(packageRoot.path);
    var reports = SourceFileReports.parse(lcov, packageRoot);
    return new CoverallsReport(repoToken, reports, gitData, serviceName);
  }
  
  
  String covString() => "{" + "\"repo_token\": \"$repoToken\", " +
      sourceFileReports.covString() + ", \"git\": ${gitData.covString()}, " +
      "\"service_name\": \"$serviceName\"}";
} 