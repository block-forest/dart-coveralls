library dart_coveralls.cli_client;

import 'dart:async' show Future, Completer;
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:stack_trace/stack_trace.dart';

import 'collect_lcov.dart';
import 'coveralls_endpoint.dart';
import 'coveralls_entities.dart';
import 'log.dart';
import 'process_system.dart';
import 'services/travis.dart' as travis;

class CommandLineClient {
  final String projectDirectory;
  final String packageRoot;
  final String token;

  CommandLineClient._(this.projectDirectory, this.packageRoot, this.token);

  factory CommandLineClient({String projectDirectory, String packageRoot,
      String token, Map<String, String> environment}) {
    if (projectDirectory == null) {
      projectDirectory = p.current;
    }

    packageRoot = _calcPackageRoot(projectDirectory, packageRoot);

    return new CommandLineClient._(projectDirectory, packageRoot, token);
  }

  Future<CoverageResult<String>> getLcovResult(String testFile,
      {int workers, ProcessSystem processSystem: const ProcessSystem()}) {
    var collector =
        new LcovCollector(packageRoot, testFile, processSystem: processSystem);
    return collector.getLcovInformation(workers: workers);
  }

  /// Returns [candidate] if not `null`, otherwise environment's `REPO_TOKEN` or
  /// `COVERALLS_TOKEN` if one is set. Otherwise; `null`.
  ///
  /// If [environment] is `null`, [Platform.environment] is used.
  static String getToken(String candidate, [Map<String, String> environment]) {
    if (candidate != null && candidate.isNotEmpty) return candidate;
    if (null == environment) environment = Platform.environment;

    candidate = environment["REPO_TOKEN"];
    if (candidate != null) return candidate;

    return environment['COVERALLS_TOKEN'];
  }

  Future reportToCoveralls(String testFile, {int workers,
      ProcessSystem processSystem: const ProcessSystem(),
      String coverallsAddress, bool dryRun: false,
      bool throwOnConnectivityError: false, int retry: 0,
      bool excludeTestFiles: false, bool printJson}) async {
    var rawLcov = await getLcovResult(testFile,
        workers: workers, processSystem: processSystem);

    rawLcov.printSummary();
    var lcov = LcovDocument.parse(rawLcov.result.toString());

    var serviceName = travis.getServiceName(Platform.environment);
    var serviceJobId = travis.getServiceJobId(Platform.environment);

    var report = CoverallsReport.parse(token, lcov, projectDirectory,
        excludeTestFiles: excludeTestFiles,
        serviceName: serviceName,
        serviceJobId: serviceJobId);

    if (printJson) {
      print(const JsonEncoder.withIndent('  ').convert(report));
    }

    if (dryRun) return;

    var endpoint = new CoverallsEndpoint(coverallsAddress);

    try {
      var encoded = JSON.encode(report);
      await _sendLoop(endpoint, encoded, retry: retry);
    } catch (e, stack) {
      if (throwOnConnectivityError) rethrow;
      stderr.writeln('Error sending results');
      stderr.writeln(e);
      stderr.writeln(new Chain.forTrace(stack).terse);
    }
  }
}

String _calcPackageRoot(String packageDir, String packageRoot) {
  assert(p.isAbsolute(packageDir));

  if (packageRoot == null) {
    packageRoot = 'packages';
  }

  if (p.isRelative(packageRoot)) {
    packageRoot = p.join(packageDir, packageRoot);
  }

  return p.normalize(packageRoot);
}

Future _sendLoop(CoverallsEndpoint endpoint, String covString,
    {int retry: 0}) async {
  var currentRetryCount = 0;
  while (true) {
    try {
      await endpoint.sendToCoveralls(covString);
      return;
    } catch (e) {
      if (currentRetryCount >= retry) {
        rethrow;
      }
      currentRetryCount++;
      log.warning('Error sending', e);
      log.info("Retrying $currentRetryCount of $retry.");
    }
  }
}
