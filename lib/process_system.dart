library process_system;

import "dart:io" show Process, ProcessResult, SYSTEM_ENCODING;
import "dart:convert" show Encoding;
import "dart:async" show Future;


class ProcessSystem {
  const ProcessSystem();
  
  ProcessResult runProcessSync(String executable, List<String> arguments,
    {String workingDirectory, Map<String, String> environment,
     bool includeParentEnvironment: true, bool runInShell: false,
     Encoding stdoutEncoding: SYSTEM_ENCODING, 
     Encoding stderrEncoding: SYSTEM_ENCODING}) {
    var result = Process.runSync(executable, arguments,
        workingDirectory: workingDirectory, environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell, stdoutEncoding: stdoutEncoding,
        stderrEncoding: stderrEncoding);
    return result;
  }
  
  Future<ProcessResult> runProcess(String executable, List<String> arguments,
      {String workingDirectory, Map<String, String> environment,
       bool includeParentEnvironment: true, bool runInShell: false,
       Encoding stdoutEncoding: SYSTEM_ENCODING, 
       Encoding stderrEncoding: SYSTEM_ENCODING}) {
    var result = Process.runSync(executable, arguments,
        workingDirectory: workingDirectory, environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell, stdoutEncoding: stdoutEncoding,
        stderrEncoding: stderrEncoding);
    return result;
  }
}