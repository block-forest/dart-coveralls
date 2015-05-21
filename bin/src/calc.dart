library dart_coveralls.calc;

import 'dart:async';
import 'dart:io';

import 'package:dart_coveralls/dart_coveralls.dart';

import 'command_line.dart';

class CalcPart extends CommandLinePart {
  final ArgParser parser;

  CalcPart() : parser = _initializeParser();

  static ArgParser _initializeParser() {
    return new ArgParser(allowTrailingOptions: true)
      ..addFlag("help", help: "Prints this help", negatable: false)
      ..addOption("workers",
          help: "Number of workers for parsing", defaultsTo: "1")
      ..addOption("output", help: "Output file path")
      ..addOption("package-root",
          help: "Root of the analyzed package", defaultsTo: ".");
  }

  Future execute(ArgResults res) async {
    if (res.rest.length != 1) {
      print("Please specify a test file to run");
      return;
    }

    var pRoot = new Directory(res["package-root"]);
    var file = new File(res.rest.single);
    var workers = int.parse(res["workers"]);

    if (!pRoot.existsSync()) {
      print("Root directory does not exist");
      return;
    }

    if (!file.existsSync()) {
      print("Dart file does not exist");
      return;
    }

    var collector = new LcovCollector(pRoot, file);

    var r = await collector.getLcovInformation(workers: workers);

    print(r.processResult.stdout);
    if (res["output"] != null) {
      await new File(res["output"]).writeAsString(r.result);
    } else {
      print(r.result);
    }
  }
}
