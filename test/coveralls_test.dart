library dart_coveralls.test;

import "dart:async";

import "package:dart_coveralls/dart_coveralls.dart";
import "package:mock/mock.dart";
import "package:test/test.dart";

import "mock_classes.dart";

void main() {
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

      expect(committer.covString(), equals('"committer_name": "Adracus", ' +
          '"committer_email": "adracus@gmail.com"'));
    });
  });

  group("GitAuthor", () {
    test("covString", () {
      var author = new GitAuthor("Adracus", "adracus@gmail.com");

      expect(author.covString(), equals('"author_name": "Adracus", ' +
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
      var remoteString =
          "origin\tgit@github.com:Adracus/dart-coveralls.git (fetch)";

      var remote = new GitRemote.fromRemoteString(remoteString);

      expect(remote.name, equals("origin"));
      expect(
          remote.address, equals("git@github.com:Adracus/dart-coveralls.git"));
    });

    test("getGitRemotes", () {
      var processSystem = new ProcessSystemMock();
      var processResult = new ProcessResultMock();
      var mockDir = new DirectoryMock();
      var args = ["remote", "-v"];
      mockDir.when(callsTo("get path")).thenReturn(".");
      processSystem
          .when(callsTo("runProcessSync", "git", args))
          .thenReturn(processResult);
      processResult.when(callsTo("get stdout")).thenReturn(
          "origin\tgit@github.com:Adracus/dart-coveralls.git (fetch)\n" +
              "origin\tgit@github.com:Adracus/dart-coveralls.git (push)");
      processResult.when(callsTo("get exitCode")).thenReturn(0);
      mockDir
          .when(callsTo("runCommand", ["remote", "-v"]))
          .thenReturn(new Future.value(processResult));
      var remotes =
          GitRemote.getGitRemotes(mockDir, processSystem: processSystem);
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
      var s2 =
          CommandLineClient.getServiceName({"COVERALLS_SERVICE_NAME": "name"});

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
}
