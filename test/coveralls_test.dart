library dart_coveralls.test;

import "package:dart_coveralls/dart_coveralls.dart";
import "package:mockito/mockito.dart";
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

  group("GitCommit", () {
    test("covString", () {
      var committer = new GitCommitter("NotAdracus", "notadracus@gmail.com");
      var author = new GitAuthor("Adracus", "adracus@gmail.com");
      var commit = new GitCommit("id", author, committer, "message");

      expect(commit.toJson(), {
        'id': 'id',
        'message': 'message',
        'committer_name': 'NotAdracus',
        'committer_email': 'notadracus@gmail.com',
        'author_name': 'Adracus',
        'author_email': 'adracus@gmail.com'
      });
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
      when(mockDir.path).thenReturn(".");
      when(processSystem.runProcessSync( "git", args)).thenReturn(processResult);
      when(processResult.stdout).thenReturn(
          "origin\tgit@github.com:Adracus/dart-coveralls.git (fetch)\n" +
              "origin\tgit@github.com:Adracus/dart-coveralls.git (push)");
      when(processResult.exitCode).thenReturn(0);

      //TODO(pq): fix stubbing here.

//      mockDir
//          .when(callsTo("runCommand", ["remote", "-v"]))
//          .thenReturn(new Future.value(processResult));
//      var remotes =
//          GitRemote.getGitRemotes(mockDir, processSystem: processSystem);
//      expect(remotes.length, equals(1));
//      expect(remotes.single.name, equals("origin"));
//      expect(remotes.single.address,
//          equals("git@github.com:Adracus/dart-coveralls.git"));
    });

    test("covString", () {
      var remote = new GitRemote("test", "git@github.com");

      expect(
          remote.toJson(), equals({"name": "test", "url": "git@github.com"}));
    });
  });

  group("CommandLineClient", () {
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
