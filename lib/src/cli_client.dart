library dart_coveralls.cli_client;

import 'dart:io';
import 'dart:async' show Future, Completer;
import 'package:dart_coveralls/src/collect_lcov.dart';
import 'package:mockable_filesystem/filesystem.dart';
import 'package:dart_coveralls/process_system.dart';
import 'package:dart_coveralls/src/coveralls_entities.dart';
import 'package:dart_coveralls/src/coveralls_endpoint.dart';


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
  
  Future<String> getRawLcov(File testFile,
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
    if (candidate != null) return candidate;
    if (null == environment) environment = Platform.environment;
    return environment["REPO_TOKEN"];
  }
  
  static String getServiceName([Map<String, String> environment]) {
    if (null == environment) environment = Platform.environment;
    var serviceName = environment["COVERALLS_SERVICE_NAME"];
    if (serviceName == null) return "local";
    return serviceName;
  }
  
  Future reportToCoveralls(File testFile, 
        {int workers, ProcessSystem processSystem: const ProcessSystem(),
          String coverallsAddress, bool dryRun: false}) {
    return getRawLcov(testFile, workers: workers,
        processSystem: processSystem).then((rawLcov) {
      var lcov = LcovDocument.parse(rawLcov.toString());
      var report = CoverallsReport.parse(token, lcov, packageRoot,
          serviceName);
      var endpoint = new CoverallsEndpoint(coverallsAddress);
      print(report.covString());
      if (dryRun) return new Future.value();
      return _sendLoop(endpoint, report.covString());
    });
  }
  
  Future _sendLoop(CoverallsEndpoint endpoint, String covString,
                   [Completer completer]) {
    if (null == completer) completer = new Completer();
    endpoint.sendToCoveralls(covString).then((_) => completer.complete())
            .catchError(() => _sendLoop(endpoint, covString, completer));
    return completer.future;
  }
}