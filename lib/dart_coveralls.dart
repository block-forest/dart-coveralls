library dart_coveralls;


import 'package:logging/logging.dart';

export 'src/collect_lcov.dart';
export 'src/coveralls_endpoint.dart';
export 'src/git_data.dart';
export 'src/cli_client.dart';
export 'src/coveralls_entities.dart';

final Logger log = new Logger("dart_coveralls");