import "src/command_line.dart";
import "src/calc.dart";
import "src/report.dart";

void main(List<String> args) {
  var builder = new CommandLineHubBuilder()
    ..addPart("report", new ReportPart(),
        description: "Calculate and report coverage data to coveralls")
    ..addPart("calc", new CalcPart(),
        description: "Calculate coveralls data and output it or store " +
            "it in a file");
  var hub = builder.build();

  hub.parseAndExecute(args);
}
