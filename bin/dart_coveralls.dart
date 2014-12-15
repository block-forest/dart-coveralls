import "src/command_line.dart";
import "src/calculate_coverage.dart";
import "src/calculate_and_send_coverage.dart";
import "src/send_coverage.dart";


void main(List<String> args) {
  var builder = new CommandLineHubBuilder();
  builder..addPart("send", new SendPart())
         ..addPart("report", new ReportPart())
         ..addPart("calc", new CalcPart());
  var hub = builder.build();
  
  return hub.parseAndExecute(args);
}

