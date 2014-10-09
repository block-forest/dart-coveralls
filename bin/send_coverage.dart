import 'dart:io';
import 'package:dart_coveralls/dart_coveralls.dart';
import 'package:args/src/arg_parser.dart';


final parser = new ArgParser(allowTrailingOptions: true);


void setupParser() {
  parser.addFlag("help", help: "Displays this help", negatable: false);
  parser.addOption("token", help: "Token for coveralls");
  parser.addOption("package-root", help: "Root directory of the tested app, " +
                                      "defaults to current directory");
  parser.addOption("retry", help: "Number of retries", defaultsTo: "1");
}



void main(List<String> args) {
  setupParser();
  var results = parser.parse(args);
  
  if (results["help"]) return print(parser.getUsage());
  if (results.rest.length != 1) return print(parser.getUsage());
  
  var lcov = new File(results.rest.single);
  var directory = getPackageRoot(results["directory"]);
  var token = getToken(results["token"]);
  
  if (token != null) {
    CoverallsReport.getReportFromLcovFile(token, lcov,
        directory).then((report) {
      report.sendToCoveralls(retryCount: int.parse(results["retry"]))
        .then((_) => print("done"));
    });
    return null;
  }
  
  return print("No token specified or in environment");
}