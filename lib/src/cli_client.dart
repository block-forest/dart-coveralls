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

class CommandLineClient {
  final String projectDirectory;
  final String packageRoot;
  final String token;
  final String serviceName;

  CommandLineClient._(
      this.projectDirectory, this.packageRoot, this.token, this.serviceName);

  factory CommandLineClient({String projectDirectory, String packageRoot,
      String token, Map<String, String> environment}) {
    if (projectDirectory == null) {
      projectDirectory = p.current;
    }

    packageRoot = _calcPackageRoot(projectDirectory, packageRoot);

    var serviceName = getServiceName(environment);
    token = getToken(token, environment);

    return new CommandLineClient._(
        projectDirectory, packageRoot, token, serviceName);
  }

  Future<CoverageResult<String>> getLcovResult(String testFile,
      {int workers, ProcessSystem processSystem: const ProcessSystem()}) {
    var collector =
        new LcovCollector(packageRoot, testFile, processSystem: processSystem);
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

  Future reportToCoveralls(String testFile, {int workers,
      ProcessSystem processSystem: const ProcessSystem(),
      String coverallsAddress, bool dryRun: false,
      bool throwOnConnectivityError: false, int retry: 0,
      bool excludeTestFiles: false, bool printJson}) async {
    var rawLcov = await getLcovResult(testFile,
        workers: workers, processSystem: processSystem);

    print(rawLcov.processResult.stdout);
    var lcov = LcovDocument.parse(rawLcov.result.toString());
    var report = CoverallsReport.parse(
        token, lcov, projectDirectory, serviceName,
        excludeTestFiles: excludeTestFiles);
    var endpoint = new CoverallsEndpoint(coverallsAddress);

    if (printJson) {
      print(const JsonEncoder.withIndent('  ').convert(report));
    }

    if (dryRun) return;

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
