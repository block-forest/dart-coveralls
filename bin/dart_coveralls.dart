import 'dart:io';

import 'package:stack_trace/stack_trace.dart';

import "src/command_line.dart";
import "src/calc.dart";
import "src/report.dart";
import "src/upload.dart";

void main(List<String> args) {
  var builder = new CommandLineHubBuilder()
    ..addPart("report", new ReportPart(),
        description: "Calculate and report coverage data to coveralls")
    ..addPart("calc", new CalcPart(),
        description: "Calculate coveralls data and output it or store " +
            "it in a file")
    ..addPart("upload", new UploadPart(), description: "Upload a report");
  var hub = builder.build();

  Chain.capture(() async {
    await hub.parseAndExecute(args);
    exit(0);
  }, onError: (error, chain) {
    print(error);
    print(chain.terse);
    // See http://www.retro11.de/ouxr/211bsd/usr/include/sysexits.h.html
    // EX_SOFTWARE
    exitCode = 70;
  });
}
