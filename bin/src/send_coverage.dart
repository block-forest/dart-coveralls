library dart_coveralls.send;

import 'dart:io';
import 'package:dart_coveralls/dart_coveralls.dart';
import 'command_line.dart';

class SendPart extends Object with CommandLinePart {
  ArgParser parser;
  
  SendPart()
      : parser = _initializeParser();

  static ArgParser _initializeParser() {
    var _parser = new ArgParser(allowTrailingOptions: true);
    _parser..addFlag("help", help: "Displays this help", negatable: false)
           ..addOption("token", help: "Token for coveralls")
           ..addOption("package-root", help: "Root directory of the tested app, " +
        "defaults to current directory", defaultsTo: ".")
           ..addOption("retry", help: "Number of retries", defaultsTo: "1");
    return _parser;
  }
  
  
  
  execute(ArgResults results) {
    if (results["help"]) return print(parser.usage);
    if (results.rest.length != 1) return print(parser.usage);
    
    var lcov = new File(results.rest.single);
    var directory = new Directory(results["package-root"]);
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

}