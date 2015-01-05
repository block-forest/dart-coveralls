part of dart_coveralls.test;

@proxy
class FileSystemMock extends Mock implements FileSystem {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

@proxy
class FileMock extends Mock implements File {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

@proxy
class DirectoryMock extends Mock implements Directory {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

@proxy
class ProcessResultMock extends Mock implements ProcessResult {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

@proxy
class ProcessSystemMock extends Mock implements ProcessSystem {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

@proxy
class SourceFilesReportsMock extends Mock implements SourceFileReports {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

@proxy
class GitDataMock extends Mock implements GitData {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
