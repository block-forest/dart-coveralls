library dart_coveralls.cli_client;

import 'dart:async' show Future, Completer;
import 'dart:io';

import 'package:mockable_filesystem/filesystem.dart';
import 'package:stack_trace/stack_trace.dart';

import 'collect_lcov.dart';
import 'coveralls_entities.dart';
import 'coveralls_endpoint.dart';
import 'process_system.dart';

class CommandLineClient {
  final FileSystem fileSystem;
  final Directory packageRoot;
  final String token;
  final String serviceName;

  CommandLineClient(Directory packageRoot, {String token,
      FileSystem fileSystem: const FileSystem(),
      Map<String, String> environment})
      : fileSystem = fileSystem,
        packageRoot = packageRoot,
        serviceName = getServiceName(environment),
        token = getToken(token, environment);

  Future<CoverageResult<String>> getLcovResult(File testFile,
      {int workers, ProcessSystem processSystem: const ProcessSystem()}) {
    var collector = new LcovCollector(packageRoot, testFile,
        fileSystem: fileSystem, processSystem: processSystem);
    return collector.getLcovInformation(workers: workers);
  }

  /// Returns [candidate] if not null, otherwise environment's REPO_TOKEN
  ///
  /// This first checks if the given candidate is null. If it is not null,
  /// the candidate will be returned. Otherwise, it searches the given
  /// environment for "REPO_TOKEN" and returns the content of it. If
  /// the given environment is null, it will be [Platform].environment.
  static String getToken(String candidate, [Map<String, String> environment]) {
    if (candidate != null && candidate.isNotEmpty) return candidate;
    if (null == environment) environment = Platform.environment;
    return environment["REPO_TOKEN"];
  }

  static String getServiceName([Map<String, String> environment]) {
    if (null == environment) environment = Platform.environment;
    var serviceName = environment["COVERALLS_SERVICE_NAME"];
    if (serviceName == null) return "local";
    return serviceName;
  }

  Future reportToCoveralls(File testFile, {int workers,
      ProcessSystem processSystem: const ProcessSystem(),
      String coverallsAddress, bool dryRun: false,
      bool throwOnConnectivityError: false, int retry: 0,
      bool excludeTestFiles: false}) async {
    var rawLcov = await getLcovResult(testFile,
        workers: workers, processSystem: processSystem);

    print(rawLcov.processResult.stdout);
    var lcov = LcovDocument.parse(rawLcov.result.toString());
    var report = CoverallsReport.parse(token, lcov, packageRoot, serviceName,
        excludeTestFiles: excludeTestFiles);
    var endpoint = new CoverallsEndpoint(coverallsAddress);
    if (dryRun) return;

    try {
      await _sendLoop(endpoint, report.covString(), retry: retry);
    } catch (e, stack) {
      if (throwOnConnectivityError) rethrow;
      stderr.writeln('Error sending results');
      stderr.writeln(e);
      stderr.writeln(new Chain.forTrace(stack).terse);
    }
  }
}

Future _sendLoop(CoverallsEndpoint endpoint, String covString,
                 {int retry: 0}) async {
  while (true) {
    try {
      await endpoint.sendToCoveralls(covString);
      return;
    } catch (_) {
      if (retry <= 0) {
        rethrow;
      }
      retry--;
    }
  }
}
