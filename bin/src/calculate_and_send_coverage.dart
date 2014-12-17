library dart_coveralls.report;

import 'dart:io';
import 'package:dart_coveralls/dart_coveralls.dart';
import "command_line.dart";


class ReportPart extends Object with CommandLinePart {
  final ArgParser parser;
  
  ReportPart()
      : parser = _initializeParser();
  
  static ArgParser _initializeParser() {
    var _parser = new ArgParser(allowTrailingOptions: true);
    _parser.addFlag("help", help: "Displays this help", negatable: false);
    _parser.addOption("token", help: "Token for coveralls",
        defaultsTo: Platform.environment["test"]);
    _parser.addOption("workers", help: "Number of workers for parsing",
          defaultsTo: "1");
    _parser.addOption("package-root", help: "Root package", defaultsTo: ".");
    _parser.addFlag("debug", help: "Prints debug information");
    _parser.addOption("retry", help: "Number of retries", defaultsTo: "1");
    _parser.addFlag("dry-run", help: "If this flag is enabled, data won't" +
        " be sent to coveralls");
    return _parser;
  }
  
  execute(ArgResults res) {
    if (res["help"]) return print(parser.usage);
    if (res.rest.length != 1) return print(parser.usage);
    if (res["debug"]) {
      log.onRecord.listen((rec) => print(rec));
    }
    
    var pRoot = new Directory(res["package-root"]);
    var file = new File(res.rest.single);
    var token = getToken(res["token"]);
    
    if (!pRoot.existsSync()) return print("Root directory does not exist");
    log.info(() => "Package root is ${pRoot.absolute.path}");
    if (!file.existsSync()) return print("Dart file does not exist");
    log.info(() => "Evaluated dart file is ${file.absolute.path}");
    if (token == null) return print("Please specify a repo token");
    log.info("Token is $token");
    
    return getLcovInformation(int.parse(res["workers"]), file, pRoot).then((r) {
      CoverallsReport.getReportFromLcovString(token, r.toString(),
          pRoot).then((report) {
        if (!res["dry-run"])
          report.sendToCoveralls(retryCount: int.parse(res["retry"]));
      });
    });
  }
}