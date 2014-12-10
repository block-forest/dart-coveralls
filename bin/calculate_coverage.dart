import 'dart:io';
import 'package:args/args.dart';
import 'package:dart_coveralls/dart_coveralls.dart';
import 'package:path/path.dart';


final ArgParser parser = new ArgParser(allowTrailingOptions: true);



void setupParser() {
  parser.addFlag("help", help: "Prints this help", negatable: false);
  parser.addOption("workers", help: "Number of workers for parsing",
      defaultsTo: "1");
  parser.addOption("output", help: "Output file path");
  parser.addOption("package-root", help: "Root of the analyzed package",
      defaultsTo: ".");
}


String getPackageRoot(String arg) {
  return absolute(normalize(arg));
}


main(List<String> args) {
  setupParser();
  var res = parser.parse(args);
  
  if (res.rest.length != 1) return print(parser.usage);
  
  var pRoot = new Directory(res["package-root"]);
  var file = new File(res.rest.single);
  
  if (!pRoot.existsSync()) return print("Root directory does not exist");
  if (!file.existsSync()) return print("Dart file does not exist");
  
  return getLcovInformation(int.parse(res["workers"]), file, pRoot).then((r) {
    if (res["output"] != null) {
      return new File(res["output"]).writeAsStringSync(r);
    }
    return print(r);
  });
}