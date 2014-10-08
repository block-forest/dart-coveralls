import 'dart:io';
import 'package:dart_coveralls/dart_coveralls.dart';
import 'package:args/src/arg_parser.dart';


final parser = new ArgParser(allowTrailingOptions: true);


void setupParser() {
  parser.addFlag("help", help: "Displays this help", negatable: false);
  parser.addOption("token", help: "Token for coveralls");
  parser.addOption("directory", help: "Root directory of the tested app, " +
                                      "defaults to current directory");
}


Directory getDirectory(String dirPath) {
  if (dirPath == null) return Directory.current;
  return new Directory(dirPath);
}


void main(List<String> args) {
  setupParser();
  var results = parser.parse(args);
  
  if (results["help"]) return print(parser.getUsage());
  
  if (results.rest.length != 1) return print(parser.getUsage());
  
  var lcov = new File(results.rest.single);
  var directory = getDirectory(results["directory"]);
  var token = getToken(results["token"]);
  
  if (token != null) {
    var f = CoverallsReport.getReportFromLcovFile(token, lcov,
        directory);
    return f.then((report) {
      report.sendToCoveralls().then((_) => print("done"));
    });
  }
  
  return print("No token specified or in environment");
}