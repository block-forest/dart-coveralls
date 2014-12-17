library dart_coveralls;

import 'dart:io';
import 'dart:async' show Future, Timer;
import 'dart:convert' show JSON;
import 'package:http/http.dart' show MultipartRequest, MultipartFile;
import 'package:path/path.dart';
import 'package:coverage/coverage.dart';
import 'package:yaml/yaml.dart';
import 'package:git/git.dart';
import 'package:logging/logging.dart';
import 'package:mockable_filesystem/filesystem.dart';

export 'package:logging/logging.dart';

part "git_data.dart";

final Logger log = new Logger("dart_coveralls");

const String COVERALLS_ADDRESS = "https://coveralls.io/api/v1/jobs";


/// Returns the name of the package located in [packageRoot].
/// 
/// This searches [packageRoot] for a yaml file, which it then
/// parses for the top level attribute name, which it then returns.
String getPackageName(Directory packageRoot,
                      [FileSystem fileSystem = const FileSystem()]) {
  var pubspecFile = fileSystem.getFile(packageRoot.path + "/pubspec.yaml");
  var pubspecContent = pubspecFile.readAsStringSync();
  var yaml = loadYaml(pubspecContent);
  return yaml["name"];
}


/// Returns [candidate] if not null, otherwise environment's REPO_TOKEN
/// 
/// This first checks if the given candidate is null. If it is not null,
/// the candidate will be returned. Otherwise, it searches the given
/// environment for "REPO_TOKEN" and returns the content of it. If
/// the given environment is null, it will be [Platform].environment.
String getToken(String candidate, [Map<String, String> environment]) {
  if (candidate != null) return candidate;
  if (null == environment) environment = Platform.environment;
  return environment["REPO_TOKEN"];
}


/// Returns the root path of the Dart SDK
/// 
/// If the given environment is null, it will be [Platform].environment.
/// This checks the environment for "DART_SDK". If it exists, this
/// will return the normalized, absolute form of the path
/// to the dart sdk joined with "lib", otherwise this returns null.
String getSDKRootPath([Map<String, String> environment]) {
  if (null == environment) environment = Platform.environment;
  if (Platform.environment.containsKey("DART_SDK"))
    return join(absolute(normalize(Platform.environment["DART_SDK"])), "lib");
  return null;
}


/// Returns an LCOV string of the tested [File].
/// 
/// Calculates and returns LCOV information of the tested [File].
/// This uses [workers] to parse the collected information.
Future<String> getLcovInformation(int workers, File file, Directory packageRoot,
    {String sdkRoot, FileSystem fileSystem: const FileSystem()}) {
  var tempDir = fileSystem.getDirectory(".temp")..createSync();
  Process.runSync("dart", ["--enable-vm-service:9999",
    "--coverage_dir=${tempDir.absolute.path}", file.absolute.path]);
  if (sdkRoot == null) sdkRoot = getSDKRootPath();
  var reportFile = tempDir.listSync().where((e) => e is File).first;
  return parseCoverage([reportFile], workers).then((hitmap) {
    tempDir.deleteSync(recursive: true);
    var resolver = new Resolver(packageRoot: packageRoot.path,
        sdkRoot: sdkRoot);
    var formatter = new LcovFormatter(resolver);
    return formatter.format(hitmap);
  });
}


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
  
  
  factory SourceFileReport.fromLcovSourceFileReport(List<String> lines,
      Directory packageRoot) {
    var sourceFile = new SourceFile.fromLcovSourceFileHeading(lines.first,
        packageRoot);
    lines.removeAt(0);
    var coverage = new Coverage.fromLcovNumeration(lines);
    return new SourceFileReport(sourceFile, coverage);
  }
  
  static bool isReportOfInterest(arg, String packageName, Set<File> files) {
    var path = (arg is List ? arg.first.split(":")[1] : arg) as String;
    if (path.startsWith(packageName)) {
      log.info("ADDING $path");
      return true;
    }
    var paths = files.map((f) => normalize(f.absolute.path)).toSet();
    if (paths.contains(path)) {
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
  
  
  factory SourceFile.fromLcovSourceFileHeading(String heading,
      Directory packageRoot) {
    var path = heading.split(":")[1];
    var file = getSourceFile(path, packageRoot);
    var ctx = new Context(current: packageRoot.absolute.path);
    var name = ctx.relative(file.path);
    var sourceLines = file.readAsLinesSync();
    var source = sourceLines.join("\n");
    return new SourceFile(name, source);
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
  factory Coverage.fromLcovNumeration(List<String> numeration) {
    var values = [];
    var current = 1;
    for (int i = 0; i < numeration.length; i++) {
      var lineValue = new LineValue.fromLcovNumerationLine(numeration[i]);
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
  factory LineValue.fromLcovNumerationLine(String line) {
    var valuePair = line.split(":");
    var values = valuePair[1].split(",");
    var lineNumber = int.parse(values[0]);
    var lineCount = int.parse(values[1]);
    return new LineValue(lineNumber, lineCount);
  }
  
  
  String covString() => lineCount == null ? "null" : "$lineCount";
  
  String toString() => covString();
}



class SourceFileReports implements CoverallsReportable {
  final List<SourceFileReport> sourceFileReports;
  
  
  SourceFileReports(this.sourceFileReports);
  
  
  factory SourceFileReports.fromLcov(String lcov,
      Directory packageRoot) {
    var fileLines = lcov.split("\n");
    var files = packageRoot.listSync(recursive: true, followLinks: false)
                           .where((f) => f is File)
                           .map((f) => f as File).toSet();
    var packageName = getPackageName(packageRoot);
    var sourceFileReportStrings = _getSourceFileReportLines(fileLines);
    var sourceFileReports = sourceFileReportStrings
        .where((lines) =>
            SourceFileReport.isReportOfInterest(lines, packageName, files))
              .map((str) =>
        new SourceFileReport.fromLcovSourceFileReport(str, packageRoot)).toList();
    return new SourceFileReports(sourceFileReports);
  }
  
  
  static List<List<String>> _getSourceFileReportLines(List<String> lcovLines) {
    var list = [];
    var iterator = lcovLines.iterator;
    var curList = [];
    while (iterator.moveNext()) {
      if (iterator.current == "end_of_record") {
        list.add(curList);
        curList = [];
      } else {
        curList.add(iterator.current);
      }
    }
    return list;
  }
  
  
  String covString() => "\"source_files\": [" +
      sourceFileReports.map((rep) => rep.covString()).join(", ") + "]";
}



class CoverallsReport implements CoverallsReportable {
  final String repoToken;
  final GitData gitData;
  final SourceFileReports sourceFileReports;
  final String serviceName;
  
  
  CoverallsReport(this.repoToken, this.sourceFileReports, this.gitData)
      : serviceName = getServiceName();
  
  
  static String getServiceName([Map<String, String> environment]) {
    if (null == environment) environment = Platform.environment;
    var serviceName = environment["COVERALLS_SERVICE_NAME"];
    if (serviceName == null) return "local";
    return serviceName;
  }
  
  
  static Future<CoverallsReport> getReportFromLcovFile(String repoToken, File lcov,
      Directory packageRoot) {
    return getReportFromLcovString(repoToken, lcov.readAsStringSync(),
        packageRoot);
  }
  
  
  static Future<CoverallsReport> getReportFromLcovString(String repoToken, String lcov,
      Directory packageRoot) {
    return GitData.getGitData(packageRoot).then((data) {
      var dirName = basename(packageRoot.path);
      return new CoverallsReport(repoToken,
          new SourceFileReports.fromLcov(lcov, packageRoot), data);
    });
  }
  
  
  String covString() => "{" + "\"repo_token\": \"$repoToken\", " +
      sourceFileReports.covString() + ", \"git\": ${gitData.covString()}, " +
      "\"service_name\": \"$serviceName\"}";
  
  
  File writeToFile([FileSystem fileSystem = const FileSystem()]) => 
      fileSystem.getFile(".tempReport")
           ..createSync()
           ..writeAsStringSync(covString());
  
  // As soon as async is stable
  /*sendToCoveralls({String address: COVERALLS_ADDRESS, int retryCount: 0,
    Duration timeoutDuration: const Duration(seconds: 5)}) async {
    var json = covString();
    for (int i = 0; i <= retryCount; i++) {
      var req = new MultipartRequest("POST", Uri.parse(address));
      req.files.add(new MultipartFile.fromString("json_file", json,
              filename: "json_file"));
      var responses = await req.send().asStream().toList();
      var response = responses.single;
      var values = await response.stream.toList();
      var msg = values.map((line) => new String.fromCharCodes(line)).join("\n");
      if (200 == response.statusCode) return;
      log.warning(msg);
      if (retryCount == i-1) {
        throw new Exception(response.reasonPhrase + "\n$msg");
      }
    }
  }*/
  
  MultipartRequest getCoverallsRequest({String address: COVERALLS_ADDRESS,
    String json}) {
    var req = new MultipartRequest("POST", Uri.parse(address));
    if (null == json) json = covString();
    req.files.add(new MultipartFile.fromString("json_file", json,
        filename: "json_file"));
    return req;
  }
  
  
  Future sendToCoveralls({String address: COVERALLS_ADDRESS, int retryCount: 1,
    Duration timeoutDuration: const Duration(seconds: 5), String json}) {
    var req = getCoverallsRequest(address: address, json: json);
    return req.send().asStream().toList().then((responses) {
      responses.single.stream.toList().then((intValues) {
        var msg = intValues.map((line) =>
            new String.fromCharCodes(line)).join("\n");
        if (responses.single.statusCode == 200) return log.info("200 OK");
        if (retryCount > 0) {
          retryCount--;
          log.info("Transmission failed ($msg), retrying... in $timeoutDuration");
          return new Future.delayed(timeoutDuration, () =>
              sendToCoveralls(retryCount: retryCount,
                  timeoutDuration: timeoutDuration, json: json));
        }
        throw new Exception(responses.single.reasonPhrase + "\n$msg");
      });
    }).catchError(() => sendToCoveralls(retryCount: retryCount - 1,
    timeoutDuration: timeoutDuration, json: json));
  }
} 