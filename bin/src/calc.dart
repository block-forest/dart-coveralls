library dart_coveralls.calc;

import 'dart:async';
import 'dart:io';

import 'package:dart_coveralls/dart_coveralls.dart';
import 'package:path/path.dart' as p;

import 'command_line.dart';

class CalcPart extends CommandLinePart {
  CalcPart() : super(_initializeParser());

  Future execute(ArgResults res) async {
    if (res["help"]) {
      print(parser.usage);
      return;
    }

    String packageRoot = res["package-root"];
    if (p.isRelative(packageRoot)) {
      packageRoot = p.absolute(packageRoot);
    }

    if (!FileSystemEntity.isDirectorySync(packageRoot)) {
      print("Package root directory does not exist");
      return;
    }

    if (res.rest.length != 1) {
      print("Please specify a test file to run");
      return;
    }

    var file = res.rest.single;
    if (p.isRelative(file)) {
      file = p.absolute(file);
    }

    if (!FileSystemEntity.isFileSync(file)) {
      print("Dart file does not exist");
      return;
    }

    var workers = int.parse(res["workers"]);
    var collector = new LcovCollector(packageRoot);

    var r = await collector.getLcovInformation(file, workers: workers);

    r.printSummary();
    if (res["output"] != null) {
      await new File(res["output"]).writeAsString(r.result);
    } else {
      print(r.result);
    }
  }
}

ArgParser _initializeParser() => new ArgParser(allowTrailingOptions: true)
  ..addFlag("help", help: "Prints this help", negatable: false)
  ..addOption("workers", help: "Number of workers for parsing", defaultsTo: "1")
  ..addOption("output", help: "Output file path")
  ..addOption("package-root",
      help: 'Where to find packages, that is, "package:..." imports.',
      defaultsTo: "packages");
