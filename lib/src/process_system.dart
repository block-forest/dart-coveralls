library coveralls.process_system;

import "dart:async" show Future;
import "dart:convert" show Encoding;
import "dart:io" show Process, ProcessResult, ProcessStartMode, systemEncoding;

class ProcessSystem {
  const ProcessSystem();

  ProcessResult runProcessSync(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment: true,
      bool runInShell: false,
      Encoding stdoutEncoding: systemEncoding,
      Encoding stderrEncoding: systemEncoding}) {
    return Process.runSync(executable, arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        stdoutEncoding: stdoutEncoding,
        stderrEncoding: stderrEncoding);
  }

  Future<ProcessResult> runProcess(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment: true,
      bool runInShell: false,
      Encoding stdoutEncoding: systemEncoding,
      Encoding stderrEncoding: systemEncoding}) {
    return Process.run(executable, arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        stdoutEncoding: stdoutEncoding,
        stderrEncoding: stderrEncoding);
  }

  Future<Process> startProcess(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment: true,
      bool runInShell: false,
      ProcessStartMode mode: ProcessStartMode.normal}) {
    return Process.start(executable, arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        mode: mode);
  }
}
