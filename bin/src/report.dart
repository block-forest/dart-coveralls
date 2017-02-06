library dart_coveralls.report;

import 'dart:async';
import 'dart:io';

import 'package:dart_coveralls/dart_coveralls.dart';
import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';

import "command_line.dart";

class ReportPart extends CommandLinePart {
  ReportPart() : super(_initializeParser());

  Future execute(ArgResults res) async {
    if (res["help"]) return print(parser.usage);

    var logLevelStr = res['log-level'];

    Level logLevel = Level.LEVELS
        .firstWhere((level) => level.name.toLowerCase() == logLevelStr);

    if (res['debug']) {
      if (logLevel == Level.OFF) {
        logLevel = Level.ALL;
      } else {
        return print("Cannot set both `--log-level` and `--debug`.");
      }
    }

    if (logLevel != Level.OFF) {
      log.onRecord.where((rec) => rec.level >= logLevel).listen((rec) {
        print(rec.message);
        if (rec.error != null) {
          print(rec.error);
        }
        if (rec.stackTrace != null) {
          print(new Chain.forTrace(rec.stackTrace).terse);
        }
      });
    }

    if (res.rest.length != 1) return print("Please specify a test file to run");

    FileSystemEntity pRoot = new File(res["packages"]);
    if (!pRoot.existsSync()) return print("Packages file does not exist");
    log.info(() => "Packages file is ${pRoot.absolute.path}");

    var file = new File(res.rest.single);
    if (!file.existsSync()) return print("Dart file does not exist");
    log.info(() => "Evaluated dart file is ${file.absolute.path}");

    var dryRun = res["dry-run"];
    var token = res["token"];
    token = CommandLineClient.getToken(token, Platform.environment);

    if (token == null) {
      if (!dryRun) return print("Please specify a repo token");
      token = "test";
    }
    // We don't print out the token here as it could end up in public build logs.
    log.info("Token is ${token.isEmpty ? 'empty' : 'not empty'}");

    var throwOnError = res["throw-on-error"];

    var errorFunction = (e, Chain chain) {
      log.severe('Exception', e, chain);
      if (throwOnError) throw e;
    };

    var workers = int.parse(res["workers"]);
    var retry = int.parse(res["retry"]);
    var throwOnConnectivityError = res["throw-on-connectivity-error"];
    var excludeTestFiles = res["exclude-test-files"];
    var printJson = res["print-json"];

    CoverallsResult result = await Chain.capture(() async {
      var commandLineClient =
          new CommandLineClient(packageRoot: pRoot.absolute.path, token: token);

      return await commandLineClient.reportToCoveralls(file.absolute.path,
          workers: workers,
          dryRun: dryRun,
          retry: retry,
          throwOnConnectivityError: throwOnConnectivityError,
          excludeTestFiles: excludeTestFiles,
          printJson: printJson);
    }, onError: errorFunction);

    if (result != null) {
      print("Coveralls ${result.message} – ${result.url}");
    }
  }
}

Iterable<String> get _logLevelOptions =>
    Level.LEVELS.map((l) => l.name.toLowerCase()).toList();

ArgParser _initializeParser() => new ArgParser(allowTrailingOptions: true)
  ..addFlag("help", help: "Displays this help", negatable: false)
  ..addOption("token",
      help: "Token for coveralls. If not provided environment values REPO_TOKEN"
      " and COVERALLS_TOKEN are used if they exist.")
  ..addOption("workers", help: "Number of workers for parsing", defaultsTo: "1")
  ..addOption("packages",
      help: 'Where to find the packages file, that is, "package:..." imports.',
      defaultsTo: ".packages")
  ..addOption("package-root",
      help: 'Ignored/Deprecated. Package directories are no longer supported.',
      defaultsTo: ".packages")
  ..addFlag("debug",
      help: "Prints all log information. Equivalent to `--log-level all`",
      negatable: false)
  ..addOption('log-level',
      help: 'The level at which logs are printed.',
      allowed: _logLevelOptions,
      defaultsTo: 'off')
  ..addOption("retry", help: "Number of retries", defaultsTo: "10")
  ..addFlag("dry-run",
      help: "If this flag is enabled, data won't be sent to coveralls",
      negatable: false)
  ..addFlag("throw-on-connectivity-error",
      help: "Should this throw an " "exception, if the upload to coveralls fails?",
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
