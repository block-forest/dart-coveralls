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

    FileSystemEntity pRoot = handlePackages(res);
    if (pRoot == null) {
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

    var previewDart2 = res['preview-dart-2'];
    var collector = new LcovCollector(
        packageRoot: pRoot is Directory ? pRoot.absolute.path : null,
        packagesPath: pRoot is File ? pRoot.absolute.path : null,
        previewDart2: previewDart2);

    var r = await collector.getLcovInformation(file);

    if (res["output"] != null) {
      await new File(res["output"]).writeAsString(r);
    } else {
      print(r);
    }
  }
}

ArgParser _initializeParser() {
  ArgParser parser = new ArgParser(allowTrailingOptions: true)
    ..addOption("workers", help: "Ignored", defaultsTo: "1")
    ..addOption("output", help: "Output file path")
    ..addFlag("preview-dart-2",
        help: "Runs code coverage in Dart 2.", negatable: false);

  return CommandLinePart.addCommonOptions(parser);
}
