library dart_coveralls;

import 'dart:io';
import 'dart:async' show Future;
import 'dart:convert' show JSON;
import 'package:http/http.dart' show MultipartRequest, MultipartFile;
import 'package:path/path.dart';
import 'package:coverage/coverage.dart';
import 'package:git/git.dart';

part "git_data.dart";


const String COVERALLS_ADDRESS = "https://coveralls.io/api/v1/jobs";



String getToken(String candidate) {
  if (candidate != null) return candidate;
  if (Platform.environment.containsKey("REPO_TOKEN"))
    return Platform.environment["REPO_TOKEN"];
  return null;
}



String getSDKRootPath() {
  if (Platform.environment.containsKey("DART_SDK"))
    return join(absolute(normalize(Platform.environment["DART_SDK"])), "lib");
  return null;
}



Future<String> getLcovInformation(int workers, File file, Directory packageRoot,
    [String sdkRoot]) {
  var tempDir = new Directory(".temp")..createSync();
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



abstract class CoverallsReportable {
  String covString();
}



class SourceFileReport implements CoverallsReportable {
  final SourceFile sourceFile;
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
  
  static bool isReportOfInterest(arg, Directory packageRoot) {
    var path = arg is List ? arg.first.split(":")[1] : arg;
    var testFile = new File(path);
    if (testFile.existsSync()) return true;
    var dirName = basename(packageRoot.path);
    path = path.substring(packageRoot.path.length);
    return path.startsWith(dirName, 1);
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
    var file = _getSourceFile(path, packageRoot);
    var name = file.absolute.path.substring(packageRoot.path.length + 1);
    var sourceLines = file.readAsLinesSync();
    var source = sourceLines.join("\n");
    return new SourceFile(name, source);
  }
  
  
  static File _getSourceFile(String path, Directory packageRoot) {
    var file = new File(path);
    if (file.existsSync()) return file;
    var dirName = basename(packageRoot.path);
    var index = path.lastIndexOf(dirName);
    //path = path.substring(0, packageRoot.path.length) + "/packages" + 
    //    path.substring(packageRoot.path.length);
    path = path.substring(0, packageRoot.path.length) + "/lib" + 
        path.substring(packageRoot.path.length + dirName.length + 1);
    return new File(path);
  }
  
  
  String covString() =>
      "\"name\": \"$name\", \"source\": ${JSON.encode(source)}";
}



class Coverage implements CoverallsReportable {
  final List<LineValue> values;
  
  
  Coverage(this.values);
  
  
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
    }
    return new Coverage(values);
  }
  
  
  String covString() =>
      "\"coverage\": [" +
          values.map((val) => val.covString()).join(", ") + "]";
}



class LineValue implements CoverallsReportable {
  final int lineNumber;
  final int lineCount;
  
  
  LineValue(this.lineNumber, this.lineCount);
  
  
  LineValue.noCount(this.lineNumber) : lineCount = null;
  
  
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
    var sourceFileReportStrings = _getSourceFileReportLines(fileLines);
    var sourceFileReports = sourceFileReportStrings
        .where((lines) =>
            SourceFileReport.isReportOfInterest(lines, packageRoot))
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
  
  
  static String getServiceName() {
    var serviceName = Platform.environment["COVERALLS_SERVICE_NAME"];
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
      sourceFileReports.covString() + ", \"git\": ${gitData.covString()} }";
  
  
  File writeToFile(String path) => 
      new File(".tempReport")
           ..createSync()
           ..writeAsStringSync(covString());
  
  
  Future sendToCoveralls([String address = COVERALLS_ADDRESS]) {
    var req = new MultipartRequest("POST", Uri.parse(address));
    req.files.add(new MultipartFile.fromString("json_file", covString(),
        filename: "json_file"));
    return req.send().asStream().toList().then((responses) {
      if (responses.single.statusCode == 200) return;
      throw new Exception(responses.single.reasonPhrase);
    });
  }
} 