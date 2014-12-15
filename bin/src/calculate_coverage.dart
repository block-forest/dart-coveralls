library dart_coveralls.calc;

import 'dart:io';
import 'package:dart_coveralls/dart_coveralls.dart';
import 'command_line.dart';


class CalcPart extends Object with CommandLinePart {
  final ArgParser parser;
  
  CalcPart()
      : parser = _initializeParser();
  
  static ArgParser _initializeParser() {
    var _parser = new ArgParser(allowTrailingOptions: true);
    _parser..addFlag("help", help: "Prints this help", negatable: false)
           ..addOption("workers", help: "Number of workers for parsing",
        defaultsTo: "1")
           ..addOption("output", help: "Output file path")
           ..addOption("package-root", help: "Root of the analyzed package",
        defaultsTo: ".");
    return _parser;
  }
  
  execute(ArgResults res) {
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
}