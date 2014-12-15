library cmdpart;

import "package:args/args.dart";

export "package:args/args.dart";


abstract class CommandLinePart {
  ArgParser get parser;
  
  parseAndExecute(List<String> args) =>
      execute(parser.parse(args));
  
  execute(ArgResults res);
}


class CommandLineHubBuilder {
  final Map<String, CommandLinePart> _parts = {};
  
  void addPart(String name, CommandLinePart part) {
    _parts[name] = part;
  }
  
  CommandLinePart removePart(String name) => _parts.remove(name);
  
  CommandLineHub build() => new CommandLineHub._(_parts);
}


class CommandLineHub extends Object with CommandLinePart {
  final Map<String, CommandLinePart> _parts;
  final ArgParser parser;
  final String _usage;
  
  CommandLineHub._(Map<String, CommandLinePart> parts)
      : _parts = parts,
        parser = _initializeParser(parts),
        _usage = "Possible commands are: ${parts.keys.join(", ")}";
  
  execute(ArgResults results) {
    if (results["help"]) return print(_usage);
    if (null == results.command) {
      return print(_usage);
    }
    var part = _parts[results.command.name];
    part.execute(results.command);
  }
  
  static ArgParser _initializeParser(Map<String, CommandLinePart> parts) {
    var parser = new ArgParser(allowTrailingOptions: false);
    parts.forEach((name, part) => parser.addCommand(name, part.parser));
    parser.addFlag("help", negatable: false);
    return parser;
  }
}