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
    if (res.rest.length != 1) return print(
        "Please specify a directory containing VM coverage files");
    if (res["debug"]) {
      log.onRecord.listen((rec) {
        print(rec.message);
        if (rec.error != null) {
          print(rec.error);
        }
        if (rec.stackTrace != null) {
          print(new Chain.forTrace(rec.stackTrace).terse);
        }
      });
    }

    var pRoot = new File(res["packages"]);
    var directory = new Directory(res.rest.single);
    var dryRun = res["dry-run"];
    var token = res["token"];
    var workers = int.parse(res["workers"]);
    var retry = int.parse(res["retry"]);
    var throwOnError = res["throw-on-error"];
    var throwOnConnectivityError = res["throw-on-connectivity-error"];
    var excludeTestFiles = res["exclude-test-files"];
    var printJson = res["print-json"];

    if (!pRoot
        .existsSync()) return print("Packages file does not exist");
    log.info(() => "Packages file is ${pRoot.absolute.path}");
    if (!directory.existsSync()) return print(
        "Directory containing VM coverage files does not exist");
    log.info(() =>
        "Directory containing VM coverage files is ${directory.absolute.path}");
    if (token == null) {
      if (!dryRun) return print("Please specify a repo token");
      token = "test";
    }
    // We don't print out the token here as it could end up in public build logs.
    log.info("Token is ${token.isEmpty ? 'empty' : 'not empty'}");

    var errorFunction = (e, Chain chain) {
      log.severe('Exception', e, chain);
      if (throwOnError) throw e;
    };

    await Chain.capture(() async {
      var commandLineClient =
          new CommandLineClient(packageRoot: pRoot.absolute.path, token: token);

      await commandLineClient.convertAndUploadToCoveralls(directory.absolute,
          workers: workers,
          dryRun: dryRun,
          retry: retry,
          throwOnConnectivityError: throwOnConnectivityError,
          excludeTestFiles: excludeTestFiles,
          printJson: printJson);
    }, onError: errorFunction);
  }
}

ArgParser _initializeParser() => new ArgParser(allowTrailingOptions: true)
  ..addFlag("help", help: "Displays this help", negatable: false)
  ..addOption("token",
      help: "Token for coveralls", defaultsTo: Platform.environment["test"])
  ..addOption("workers", help: "Number of workers for parsing", defaultsTo: "1")
  ..addOption("packages",
      help: 'Where to find the packages file, that is, "package:..." imports.',
      defaultsTo: ".packages")
  ..addOption("package-root",
      help: 'Ignored/Deprecated. Package directories are no longer supported.',
      defaultsTo: ".packages")
  ..addFlag("debug", help: "Prints debug information", negatable: false)
  ..addOption("retry", help: "Number of retries", defaultsTo: "10")
  ..addFlag("dry-run",
      help: "If this flag is enabled, data won't be sent to coveralls",
      negatable: false)
  ..addFlag("throw-on-connectivity-error",
      help: "Should this throw an exception, if the upload to coveralls fails?",
      negatable: false,
      abbr: "C")
  ..addFlag("throw-on-error", help: "Should this throw if "
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
