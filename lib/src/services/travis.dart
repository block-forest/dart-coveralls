library coveralls_dart.src.services.travis;

/// Returns the current branch name for the provided [environment] as defined
/// by Travis.
///
/// If none exists, return `null`.
String getBranch(Map<String, String> environment) =>
    environment["TRAVIS_BRANCH"];
