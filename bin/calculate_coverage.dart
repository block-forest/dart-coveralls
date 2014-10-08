import 'dart:io';
import 'package:args/args.dart';
import 'package:dart_coveralls/dart_coveralls.dart';
import 'package:coverage/coverage.dart';
import 'package:path/path.dart';


final ArgParser parser = new ArgParser(allowTrailingOptions: true);



void setupParser() {
  parser.addFlag("help", help: "Prints this help", negatable: false);
  parser.addOption("workers", help: "Number of workers for parsing",
      defaultsTo: "1");
  parser.addOption("output", help: "Output file path");
}


String getPackageRoot(String arg) {
  return absolute(normalize(arg));
}


main(List<String> args) {
  setupParser();
  var res = parser.parse(args);
  
  if (res.rest.length != 2) return print(parser.getUsage());
  
  var pRoot = new Directory(res.rest.first);
  var file = new File(res.rest.last);
  
  if (!pRoot.existsSync()) return print("Root directory does not exist");
  if (!file.existsSync()) return print("Dart file does not exist");
  
  return getLcovInformation(int.parse(res["workers"]), file, pRoot).then((r) {
    if (res["output"] != null) {
      return new File(res["output"]).writeAsStringSync(r);
    }
    return print(r);
  });
}