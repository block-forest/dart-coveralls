library dart_coveralls.test;

import 'coveralls_entities_test.dart' as coveralls_entities;
import 'coveralls_test.dart' as coveralls;
import 'coveralls_collect_lcov_test.dart' as coveralls_lcov;

void main() {
  coveralls_entities.main();
  coveralls.main();
  coveralls_lcov.main();
}
