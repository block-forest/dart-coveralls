library cmdpart;

import 'dart:async';
import 'dart:io' show Directory, File, FileSystemEntity, Platform;
import "dart:math" show max;

import "package:args/args.dart";
import 'package:dart_coveralls/dart_coveralls.dart' show CommandLineClient, log;
import 'package:logging/logging.dart';
import 'package:stack_trace/src/chain.dart';

export "package:args/args.dart";

final Logger _log = new Logger("dart_coveralls");

abstract class CommandLinePart {
  final ArgParser parser;

  CommandLinePart(this.parser);

  bool handleLogging(ArgResults res) {
    var logLevelStr = res['log-level'];

    Level logLevel = Level.LEVELS
        .firstWhere((level) => level.name.toLowerCase() == logLevelStr);

    if (res['debug']) {
      if (logLevel == Level.OFF) {
        logLevel = Level.ALL;
      } else {
        print("Cannot set both `--log-level` and `--debug`.");
        return false;
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

    return true;
  }

  /// Performs checks on options --packages, --package-root and --token
  /// before returning a `CommandLineClient` instance.
  CommandLineClient getCommandLineClient(ArgResults res) {

    var token = res["token"];
    token = CommandLineClient.getToken(token, Platform.environment);
    if (token == null) {
      if (!res["dry-run"]) {
        print("Please specify a repo token");
        return null;
      }
      token = "test";
    }
    // We don't print out the token here as it could end up in public build logs.
    _log.info("Token is ${token.isEmpty ? 'empty' : 'not empty'}");

    FileSystemEntity pRoot;
      String type;
      if(res["package-root"] != null){
        if(res["packages"] != null){
          print("You cannot use both --packages and --package-root options at the same time.");
          return null;
        }
        pRoot = new Directory(res["package-root"]);
        type = "directory";

      }
      else{
        String pFilePath = res["packages"] ?? ".packages";
        pRoot = new File(pFilePath);
        type = "file";
      }
      if (!pRoot.existsSync()) {
        print("Packages $type does not exist");
        return null;
      }

      _log.info(() => "Using packages ${type}: ${pRoot.path}");
      return new CommandLineClient(packageRoot: pRoot is Directory ? pRoot.absolute.path : null, packagesPath: pRoot is File ? pRoot.absolute.path : null, token: token);
  }
  
    static ArgParser addCommonOptions(ArgParser parser) {
        return parser
          ..addFlag("help", help: "Displays this help", negatable: false)
          ..addOption("packages",
              help: 'Specifies the path to the package resolution configuration file. This option cannot be used with --package-root.',)
          ..addOption("package-root",
              help: 'Specifies where to find imported libraries. This option cannot be used with --packages.');
        }
  Future parseAndExecute(List<String> args) => execute(parser.parse(args));

  Future execute(ArgResults res);
}

class CommandLineHubBuilder {
  final Map<PartInfo, CommandLinePart> _parts = {};

  void addPart(String name, CommandLinePart part, {String description: ""}) {
    _parts[new PartInfo(name, description: description)] = part;
  }

  CommandLinePart removePart(String name) => _parts.remove(name);

  CommandLineHub build() => new CommandLineHub._(_parts);
}

class CommandLineHub extends CommandLinePart {
  final Map<PartInfo, CommandLinePart> _parts;

  CommandLineHub._(Map<PartInfo, CommandLinePart> parts)
      : _parts = parts,
        super(_initializeParser(parts));

  Future execute(ArgResults results) async {
    if (results["help"]) {
      print(usage);
      return;
    }
    if (null == results.command) {
      print(usage);
      return;
    }
    var part = partByName(results.command.name);
    await part.execute(results.command);
  }

  CommandLinePart partByName(String name) {
    var partInfo = _parts.keys.firstWhere((info) => info.name == name);
    return _parts[partInfo];
  }

  int _getLongestNameLength() {
    var longest = 0;
    _parts.keys.forEach((part) => longest = max(longest, part.name.length));
    return longest;
  }

  String get usage {
    int len = _getLongestNameLength();
    return "Possible commands are: \n\n" +
        _parts.keys.map((info) => info.toString(len)).join("\n");
  }
}

class PartInfo {
  final String name;
  final String description;

  PartInfo(this.name, {this.description: ""});

  bool operator ==(other) {
    if (other is! PartInfo) return false;
    return other.name == this.name;
  }

  int get hashCode => name.hashCode;

  String toString([int nameLength]) {
    if (null == nameLength) nameLength = name.length;
    return "  ${name.padRight(nameLength)}\t$description";
  }
}

ArgParser _initializeParser(Map<PartInfo, CommandLinePart> parts) {
  var parser = new ArgParser(allowTrailingOptions: false);
  parts.forEach((info, part) => parser.addCommand(info.name, part.parser));
  parser.addFlag("help", negatable: false);
  return parser;
}
