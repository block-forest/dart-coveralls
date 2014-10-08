import 'dart:io';
import 'package:dart_coveralls/dart_coveralls.dart';
import 'package:args/args.dart';


final parser = new ArgParser(allowTrailingOptions: true);


void setupParser() {
  parser.addFlag("help", help: "Displays this help", negatable: false);
  parser.addOption("token", help: "Token for coveralls");
  parser.addOption("workers", help: "Number of workers for parsing",
        defaultsTo: "1");
}


main(List<String> args) {
  setupParser();
  var res = parser.parse(args);

  if (res.rest.length != 2) return print(parser.getUsage());
  
  var pRoot = new Directory(res.rest.first);
  var file = new File(res.rest.last);
  var token = getToken(res["token"]);
  
  if (!pRoot.existsSync()) return print("Root directory does not exist");
  if (!file.existsSync()) return print("Dart file does not exist");
  if (token == null) return print("Please specify a repo token");
  
  return getLcovInformation(int.parse(res["workers"]), file, pRoot).then((r) {
    CoverallsReport.getReportFromLcovString(token, r.toString(),
        pRoot).then((report) {
      report.sendToCoveralls();
    });
  });
}