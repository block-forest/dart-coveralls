library dart_coveralls.test;

import "dart:io";
import "dart:async" show Future;
import "package:dart_coveralls/dart_coveralls.dart";
import "package:unittest/unittest.dart";
import "package:mock/mock.dart";
import "package:mockable_filesystem/mock_filesystem.dart";
import "package:dart_coveralls/process_system.dart";

part "mock_classes.dart";



void expectLineValue(LineValue lv, int lineNumber, int lineCount) {
  expect(lv.lineNumber, equals(lineNumber));
  expect(lv.lineCount, equals(lineCount));
}


main() {
  group("SourceFileReports", () {
    test("getPackageName", () {
      var fileSystem = new FileSystemMock();
      var fileMock = new FileMock();
      var dirMock = new DirectoryMock();
      
      dirMock.when(callsTo("get path")).thenReturn(".");
      fileMock.when(callsTo("readAsStringSync"))
              .thenReturn("name: dart_coveralls");
      fileSystem.when(callsTo("getFile", "./pubspec.yaml"))
                .thenReturn(fileMock);
      
      var name = SourceFileReports.getPackageName(dirMock, fileSystem);
      expect(name, equals("dart_coveralls"));
      fileSystem.getLogs(callsTo("getFile", "./pubspec.yaml"))
                .verify(happenedOnce);
      fileMock.getLogs(callsTo("readAsStringSync"))
              .verify(happenedOnce);
      dirMock.getLogs(callsTo("get path"))
             .verify(happenedOnce);
    });
  });
  
  group("LineValue", () {
    test("fromLcovNumeration", () {
      var str = "DA:27,0";
      var lineValue = LineValue.parse(str);
      
      expectLineValue(lineValue, 27, 0);
    });
    
    test("covString", () {
      var str = "DA:27,0";
      var lineValue1 = LineValue.parse(str);
      var lineValue2 = new LineValue.noCount(10);
      
      expect(lineValue1.covString(), equals("0"));
      expect(lineValue2.covString(), equals("null"));
    });
  });
  
  group("Coverage", () {
    test("fromLcovNumeration", () {
      var str = "DA:3,3\nDA:4,5\nDA:6,3";
      var coverage = Coverage.parse(str);
      var values = coverage.values;
      expectLineValue(values[0], 1, null);
      expectLineValue(values[1], 2, null);
      expectLineValue(values[2], 3, 3);
      expectLineValue(values[3], 4, 5);
      expectLineValue(values[4], 5, null);
      expectLineValue(values[5], 6, 3);
    });
    
    test("covString", () {
      var str = "DA:3,3\nDA:4,5\nDA:6,3";
      var coverage = Coverage.parse(str);
      
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
      var processSystem = new ProcessSystemMock();
      var processResult = new ProcessResultMock();
      var mockDir = new DirectoryMock();
      var args = ["remote", "-v"];
      mockDir.when(callsTo("get path")).thenReturn(".");
      processSystem.when(callsTo("runProcessSync", "git", args))
                   .thenReturn(processResult);
      processResult.when(callsTo("get stdout"))
        .thenReturn("origin\tgit@github.com:Adracus/dart-coveralls.git (fetch)\n" +
                    "origin\tgit@github.com:Adracus/dart-coveralls.git (push)");
      processResult.when(callsTo("get exitCode")).thenReturn(0);
      mockDir.when(callsTo("runCommand", ["remote", "-v"])).thenReturn(
          new Future.value(processResult));
      var remotes = GitRemote.getGitRemotes(mockDir,
          processSystem: processSystem);
      expect(remotes.length, equals(1));
      expect(remotes.single.name, equals("origin"));
      expect(remotes.single.address,
          equals("git@github.com:Adracus/dart-coveralls.git"));
    });
    
    test("covString", () {
      var remote = new GitRemote("test", "git@github.com");
      var covString = remote.covString();
      
      expect(covString, equals('{"name": "test", "url": "git@github.com"}'));
    });
  });
  
  group("CommandLineClient", () {
    test("getServiceName", () {
      var s1 = CommandLineClient.getServiceName();
      var s2 = CommandLineClient.getServiceName(
          {"COVERALLS_SERVICE_NAME": "name"});
      
      expect(s1, equals("local"));
      expect(s2, equals("name"));
    });
    
    group("getToken", () {
      test("with candidate", () {
        var t1 = CommandLineClient.getToken("test");
        expect(t1, equals("test"));
      });
      
      test("without candidate", () {
        var t2 = CommandLineClient.getToken(null, {"REPO_TOKEN": "test"});
        expect(t2, equals("test"));
      });
    });
  });
  
  group("CoverallsReport", () {
    
    test("covString", () {
      var sourceFileReports = new SourceFilesReportsMock();
      sourceFileReports.when(callsTo("covString"))
                       .thenReturn("{sourceFileCovString}");
      var gitDataMock = new GitDataMock();
      gitDataMock.when(callsTo("covString"))
                 .thenReturn("{gitDataCovString}");
      
      var report = new CoverallsReport("token", sourceFileReports,
          gitDataMock, "local");
      
      var covString = report.covString();
      
      expect(covString, equals('{"repo_token": "token", {sourceFileCovString}, ' +
                               '"git": {gitDataCovString}, ' +
                               '"service_name": "local"}'));
    });
  });
}