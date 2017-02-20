library dart_coveralls.upload;

import 'dart:async';
import 'dart:io';

import 'package:dart_coveralls/dart_coveralls.dart';
import 'package:stack_trace/stack_trace.dart';

import 'command_line.dart';

class UploadPart extends CommandLinePart {
  UploadPart() : super(_initializeParser());

  Future execute(ArgResults res) async {
    if (res["help"]) return print(parser.usage);

    if (handleLogging(res) == false) {
      return null;
    }

    if (res.rest.length != 1)
      return print("Please specify a directory containing VM coverage files");

    var directory = new Directory(res.rest.single);
    var dryRun = res["dry-run"];
    var retry = int.parse(res["retry"]);
    var throwOnError = res["throw-on-error"];
    var throwOnConnectivityError = res["throw-on-connectivity-error"];
    var excludeTestFiles = res["exclude-test-files"];
    var printJson = res["print-json"];

    if (!directory.existsSync())
      return print("Directory containing VM coverage files does not exist");
    log.info(() =>
        "Directory containing VM coverage files is ${directory.absolute.path}");

    var errorFunction = (e, Chain chain) {
      log.severe('Exception', e, chain);
      if (throwOnError) throw e;
    };

    await Chain.capture(() async {
      var commandLineClient = getCommandLineClient(res);
      if (commandLineClient == null) {
        return null;
      }

      await commandLineClient.convertAndUploadToCoveralls(directory.absolute,
          dryRun: dryRun,
          retry: retry,
          throwOnConnectivityError: throwOnConnectivityError,
          excludeTestFiles: excludeTestFiles,
          printJson: printJson);
    }, onError: errorFunction);
  }
}

ArgParser _initializeParser() {
  ArgParser parser = new ArgParser(allowTrailingOptions: true)
    ..addOption("token",
        help: "Token for coveralls", defaultsTo: Platform.environment["test"])
    ..addFlag("debug", help: "Prints debug information", negatable: false)
    ..addOption("retry", help: "Number of retries", defaultsTo: "10")
    ..addFlag("dry-run",
        help: "If this flag is enabled, data won't be sent to coveralls",
        negatable: false)
    ..addFlag("throw-on-connectivity-error",
        help:
            "Should this throw an exception, if the upload to coveralls fails?",
        negatable: false,
        abbr: "C")
    ..addFlag("throw-on-error",
        help: "Should this throw if "
            "an error in the dart_coveralls implementation happens?",
        negatable: false,
        abbr: "E")
    ..addFlag("exclude-test-files",
        abbr: "T",
        help: "Should test files be included in the coveralls report?",
        negatable: false)
    ..addFlag("print-json",
        abbr: 'p',
        help: "Pretty-print the json that will be sent to coveralls.",
        negatable: false);

  return CommandLinePart.addCommonOptions(parser);
}
