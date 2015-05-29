library coveralls_dart.src.services.travis;

/// Returns the current branch name for the provided [environment] as defined
/// by Travis.
///
/// If none exists, return `null`.
String getBranch(Map<String, String> environment) =>
    environment["TRAVIS_BRANCH"];

/// Following the coveralls conventions
/// See https://coveralls.zendesk.com/hc/en-us/articles/201774865-API-Introduction
String getServiceName(Map<String, String> environment) =>
    (environment['TRAVIS'] == 'true') ? 'travis-ci' : null;

/// Following the coveralls conventions
/// See https://coveralls.zendesk.com/hc/en-us/articles/201774865-API-Introduction
String getServiceJobId(Map<String, String> environment) =>
    environment['TRAVIS_JOB_ID'];
