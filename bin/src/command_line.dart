library cmdpart;

import 'dart:async';
import "dart:math" show max;

import "package:args/args.dart";

export "package:args/args.dart";

abstract class CommandLinePart {
  ArgParser get parser;

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

class CommandLineHub extends Object with CommandLinePart {
  final Map<PartInfo, CommandLinePart> _parts;
  final ArgParser parser;

  CommandLineHub._(Map<PartInfo, CommandLinePart> parts)
      : _parts = parts,
        parser = _initializeParser(parts);

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

  static ArgParser _initializeParser(Map<PartInfo, CommandLinePart> parts) {
    var parser = new ArgParser(allowTrailingOptions: false);
    parts.forEach((info, part) => parser.addCommand(info.name, part.parser));
    parser.addFlag("help", negatable: false);
    return parser;
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
