import "dart:io";
import "dart:async" show Future;
import "package:dart_coveralls/dart_coveralls.dart";
import "package:unittest/unittest.dart";
import "package:mock/mock.dart";
import "package:git/git.dart";
import "package:mockable_filesystem/mock_filesystem.dart";

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
class GitDirMock extends Mock implements GitDir {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

@proxy
class CommitMock extends Mock implements Commit {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

@proxy
class ProcessResultMock extends Mock implements ProcessResult {
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




void expectLineValue(LineValue lv, int lineNumber, int lineCount) {
  expect(lv.lineNumber, equals(lineNumber));
  expect(lv.lineCount, equals(lineCount));
}


main() {
  group("Top Level Function", () {
    test("getPackageName", () {
      var fileSystem = new FileSystemMock();
      var fileMock = new FileMock();
      var dirMock = new DirectoryMock();
      
      dirMock.when(callsTo("get path")).thenReturn(".");
      fileMock.when(callsTo("readAsStringSync"))
              .thenReturn("name: dart_coveralls");
      fileSystem.when(callsTo("getFile", "./pubspec.yaml"))
                .thenReturn(fileMock);
      
      var name = getPackageName(dirMock, fileSystem);
      expect(name, equals("dart_coveralls"));
      fileSystem.getLogs(callsTo("getFile", "./pubspec.yaml"))
                .verify(happenedOnce);
      fileMock.getLogs(callsTo("readAsStringSync"))
              .verify(happenedOnce);
      dirMock.getLogs(callsTo("get path"))
             .verify(happenedOnce);
    });
    
    test("getToken", () {
      var t1 = getToken("test");
      var t2 = getToken(null, {"REPO_TOKEN": "test"});
      
      expect(t1, equals("test"));
      expect(t2, equals("test"));
    });
  });
  
  group("LineValue", () {
    test("fromLcovNumeration", () {
      var str = "DA:27,0";
      var lineValue = new LineValue.fromLcovNumerationLine(str);
      
      expectLineValue(lineValue, 27, 0);
    });
    
    test("covString", () {
      var str = "DA:27,0";
      var lineValue1 = new LineValue.fromLcovNumerationLine(str);
      var lineValue2 = new LineValue.noCount(10);
      
      expect(lineValue1.covString(), equals("0"));
      expect(lineValue2.covString(), equals("null"));
    });
  });
  
  group("Coverage", () {
    test("fromLcovNumeration", () {
      var strings = ["DA:3,3", "DA:4,5", "DA:6,3"];
      var coverage = new Coverage.fromLcovNumeration(strings);
      var values = coverage.values;
      expectLineValue(values[0], 1, null);
      expectLineValue(values[1], 2, null);
      expectLineValue(values[2], 3, 3);
      expectLineValue(values[3], 4, 5);
      expectLineValue(values[4], 5, null);
      expectLineValue(values[5], 6, 3);
    });
    
    test("covString", () {
      var strings = ["DA:3,3", "DA:4,5", "DA:6,3"];
      var coverage = new Coverage.fromLcovNumeration(strings);
      
      expect(coverage.covString(),
          equals("\"coverage\": [null, null, 3, 5, null, 3]"));
    });
  });

  group("SourceFile", () {
    group("getSourceFile", () {
      test("existing File", () {
        var fileMock = new FileMock();
        var fileSystem = new FileSystemMock();
        var dirMock = new DirectoryMock();
        
        fileMock.when(callsTo("existsSync")).thenReturn(true);
        fileMock.when(callsTo("get absolute")).thenReturn(fileMock);
        fileSystem.when(callsTo("getFile", "test.file")).thenReturn(fileMock);
        var file = SourceFile.getSourceFile("test.file", dirMock,
            fileSystem: fileSystem);
        
        expect(identical(fileMock, file), isTrue);
      });
      
      test("Non existent File", () {
        var fileMock = new FileMock();
        var fileSystem = new FileSystemMock();
        var dirMock = new DirectoryMock();
        var resolvedFile = new FileMock();
        
        fileMock.when(callsTo("existsSync")).thenReturn(false);
        dirMock.when(callsTo("get path")).thenReturn(".");
        fileSystem.when(callsTo("getFile", "dart_coveralls/test.file"))
                  .thenReturn(fileMock);
        fileSystem.when(callsTo("getFile", "./packages/dart_coveralls/test.file"))
                  .thenReturn(fileMock);
        fileMock.when(callsTo("resolveSymbolicLinksSync"))
                .thenReturn("resolvedFile.dart");
        fileSystem.when(callsTo("getFile", "resolvedFile.dart"))
                  .thenReturn(resolvedFile);
        resolvedFile.when(callsTo("get absolute")).thenReturn(resolvedFile);
        
        var file = SourceFile.getSourceFile("dart_coveralls/test.file",
            dirMock, fileSystem: fileSystem);
        
        expect(identical(file, resolvedFile), isTrue);
      });
    });
  });
  
  group("GitPerson", () {
    test("getPersonName", () {
      var name = GitPerson.getPersonName("Adracus <adracus@gmail.com>");
      expect(name, equals("Adracus"));
    });
    
    test("getPersonMail", () {
      var name = GitPerson.getPersonMail("Adracus <adracus@gmail.com>");
      expect(name, equals("adracus@gmail.com"));
    });
  });
  
  group("GitCommitter", () {
    test("covString", () {
      var committer = new GitCommitter("Adracus", "adracus@gmail.com");
      
      expect(committer.covString(),
          equals('"committer_name": "Adracus", ' +
              '"committer_email": "adracus@gmail.com"'));
    });
  });
  
  group("GitAuthor", () {
    test("covString", () {
      var author = new GitAuthor("Adracus", "adracus@gmail.com");
      
      expect(author.covString(),
          equals('"author_name": "Adracus", ' +
              '"author_email": "adracus@gmail.com"'));
    });
  });
  
  group("GitCommit", () {
    test("getGitCommit", () {
      var dirMock = new GitDirMock();
      var commitMock = new CommitMock();
      
      commitMock.when(callsTo("get message")).thenReturn("message");
      commitMock.when(callsTo("get author"))
                .thenReturn("Adracus <adracus@gmail.com>");
      commitMock.when(callsTo("get committer"))
                .thenReturn("NotAdracus <notadracus@gmail.com>");
      commitMock.when(callsTo("get id")).thenReturn("id");
      dirMock.when(callsTo("getCommit", "id"))
             .thenReturn(new Future.value(commitMock));
      
      GitCommit.getGitCommit(dirMock, "id").then(expectAsync((GitCommit commit) {
        expect(commit.author.name, equals("Adracus"));
        expect(commit.author.mail, equals("adracus@gmail.com"));
        expect(commit.committer.name, equals("NotAdracus"));
        expect(commit.committer.mail, equals("notadracus@gmail.com"));
        expect(commit.message, equals("message"));
        expect(commit.id, equals("id"));
      }));
    });
    
    test("covString", () {
      var committer = new GitCommitter("NotAdracus", "notadracus@gmail.com");
      var author = new GitAuthor("Adracus", "adracus@gmail.com");
      var commit = new GitCommit("id", author, committer, "message");
      
      expect(commit.covString(), '{"id": "id", ${author.covString()}, ' +
          '${committer.covString()}, "message": "message"}');
    });
  });
  
  group("GitRemote", () {
    test("fromRemoteString", () {
      var remoteString = "origin\tgit@github.com:Adracus/dart-coveralls.git (fetch)";
      
      var remote = new GitRemote.fromRemoteString(remoteString);
      
      expect(remote.name, equals("origin"));
      expect(remote.address, equals("git@github.com:Adracus/dart-coveralls.git"));
    });
    
    test("getGitRemotes", () {
      var processResult = new ProcessResultMock();
      var mockDir = new GitDirMock();
      processResult.when(callsTo("get stdout"))
        .thenReturn("origin\tgit@github.com:Adracus/dart-coveralls.git (fetch)\n" +
                    "origin\tgit@github.com:Adracus/dart-coveralls.git (push)");
      mockDir.when(callsTo("runCommand", ["remote", "-v"])).thenReturn(
          new Future.value(processResult));
      GitRemote.getGitRemotes(mockDir).then(
          expectAsync((List<GitRemote> remotes) {
        expect(remotes.length, equals(1));
        expect(remotes.single.name, equals("origin"));
        expect(remotes.single.address,
            equals("git@github.com:Adracus/dart-coveralls.git"));
      }));
    });
    
    test("covString", () {
      var remote = new GitRemote("test", "git@github.com");
      var covString = remote.covString();
      
      expect(covString, equals('{"name": "test", "url": "git@github.com"}'));
    });
  });
  
  group("CoverallsReport", () {
    test("getServiceName", () {
      var s1 = CoverallsReport.getServiceName();
      var s2 = CoverallsReport.getServiceName({"COVERALLS_SERVICE_NAME": "name"});
      
      expect(s1, equals("local"));
      expect(s2, equals("name"));
    });
    
    test("covString", () {
      var sourceFileReports = new SourceFilesReportsMock();
      sourceFileReports.when(callsTo("covString"))
                       .thenReturn("{sourceFileCovString}");
      var gitDataMock = new GitDataMock();
      gitDataMock.when(callsTo("covString"))
                 .thenReturn("{gitDataCovString}");
      
      var report = new CoverallsReport("token", sourceFileReports, gitDataMock);
      
      var covString = report.covString();
      
      expect(covString, equals('{"repo_token": "token", {sourceFileCovString}, ' +
                               '"git": {gitDataCovString}, ' +
                               '"service_name": "local"}'));
    });
    
    test("writeToFile", () {
      var covString = '{"repo_token": "token", {sourceFileCovString}, ' +
          '"git": {gitDataCovString}, ' +
          '"service_name": "local"}';
      var sourceFileReports = new SourceFilesReportsMock();
      sourceFileReports.when(callsTo("covString"))
                       .thenReturn("{sourceFileCovString}");
      var gitDataMock = new GitDataMock();
      gitDataMock.when(callsTo("covString"))
                 .thenReturn("{gitDataCovString}");
      var report = new CoverallsReport("token", sourceFileReports, gitDataMock);
      var fileMock = new FileMock();
      var fileSystem = new FileSystemMock();
      fileMock.when(callsTo("createSync")).thenReturn(null);
      fileMock.when(callsTo("writeAsStringSync", covString)).thenReturn(null);
      
      fileSystem.when(callsTo("getFile", ".tempReport"))
                .thenReturn(fileMock);
      
      report.writeToFile(fileSystem);
      
      fileMock.getLogs(callsTo("createSync")).verify(happenedOnce);
      fileMock.getLogs(callsTo("writeAsStringSync", covString))
              .verify(happenedOnce);
    });
    
    test("getCoverallsRequest", () {
      var sourceFileReports = new SourceFilesReportsMock();
      sourceFileReports.when(callsTo("covString"))
                       .thenReturn("{sourceFileCovString}");
      var gitDataMock = new GitDataMock();
      gitDataMock.when(callsTo("covString"))
                 .thenReturn("{gitDataCovString}");
      var report = new CoverallsReport("token", sourceFileReports, gitDataMock);
      
      var request = report.getCoverallsRequest(address: "www.example.com",
          json: '{"some": "json"}');
      
      expect(request.files.length, equals(1));
      expect(request.files.single.field, equals("json_file"));
      
      request.files.single.finalize().toList().then(
          expectAsync((List<List<int>> vals) {
        var str = vals.map((vals2) => new String.fromCharCodes(vals2))
                      .join("\n");
        expect(str, equals('{"some": "json"}'));
      }));
    });
  });
}