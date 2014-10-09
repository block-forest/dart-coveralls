import 'dart:io';
import 'package:dart_coveralls/dart_coveralls.dart';
import 'package:args/args.dart';


final parser = new ArgParser(allowTrailingOptions: true);


void setupParser() {
  parser.addFlag("help", help: "Displays this help", negatable: false);
  parser.addOption("token", help: "Token for coveralls");
  parser.addOption("workers", help: "Number of workers for parsing",
        defaultsTo: "1");
  parser.addOption("package-root", help: "Root package");
  parser.addFlag("debug", help: "Prints debug information");
  parser.addOption("retry", help: "Number of retries", defaultsTo: "1");
}


main(List<String> args) {
  setupParser();
  var res = parser.parse(args);

  if (res["help"]) return print(parser.getUsage());
  if (res.rest.length != 1) return print(parser.getUsage());
  if (res["debug"]) {
    log.onRecord.listen((rec) => print(rec.loggerName + ": " + rec.message));
  }
  
  var pRoot = getPackageRoot(res["package-root"]);
  var file = new File(res.rest.single);
  var token = getToken(res["token"]);
  
  if (!pRoot.existsSync()) return print("Root directory does not exist");
  if (!file.existsSync()) return print("Dart file does not exist");
  if (token == null) return print("Please specify a repo token");
  
  return getLcovInformation(int.parse(res["workers"]), file, pRoot).then((r) {
    CoverallsReport.getReportFromLcovString(token, r.toString(),
        pRoot).then((report) {
      report.sendToCoveralls(retryCount: int.parse(res["retry"]));
    });
  });
}