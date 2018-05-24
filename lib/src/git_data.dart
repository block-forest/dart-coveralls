library dart_coveralls.git_data;

import 'dart:io' show ProcessException, Platform;

import 'package:file/file.dart';

import 'log.dart';
import 'services/travis.dart' as travis;
import 'process_system.dart';

abstract class GitPerson {
  final String name;
  final String mail;

  GitPerson(this.name, this.mail);

  GitPerson.fromPersonString(String str)
      : name = getPersonName(str),
        mail = getPersonMail(str);

  static String getPersonName(String str) {
    if (!str.contains("<")) return "Unknown";
    return str.split("<")[0].trim();
  }

  static String getPersonMail(String str) {
    var mailCandidate = new RegExp(r"<(.*?)>").firstMatch(str);
    if (null == mailCandidate) return "Unknown";
    var mail = mailCandidate.group(0);
    return mail.substring(1, mail.length - 1);
  }
}

class GitCommitter extends GitPerson {
  GitCommitter(String name, String mail) : super(name, mail);

  GitCommitter.fromPersonString(String str) : super.fromPersonString(str);
}

class GitAuthor extends GitPerson {
  GitAuthor(String name, String mail) : super(name, mail);

  GitAuthor.fromPersonString(String str) : super.fromPersonString(str);
}

class GitCommit {
  final String id;
  final GitAuthor author;
  final GitCommitter committer;
  final String message;

  GitCommit(this.id, this.author, this.committer, this.message);

  static GitCommit getCommit(Directory dir, String id,
      {ProcessSystem processSystem: const ProcessSystem()}) {
    var args = ["show", "$id", "--format=full", "--quiet"];
    var res =
        processSystem.runProcessSync("git", args, workingDirectory: dir.path);
    if (0 != res.exitCode) throw new ProcessException("git", args, res.stderr);
    return GitCommit.parse(res.stdout);
  }

  static GitCommit parse(String commitString) {
    log.info(() => "Parsing commit $commitString");
    var lines = commitString.split("\n");
    var id = lines.first.split(" ").last;
    var author = new GitAuthor.fromPersonString(lines[1]);
    var committer = new GitCommitter.fromPersonString(lines[2]);
    var message = lines.sublist(4, getDiffStart(lines)).join("\n").trim();
    return new GitCommit(id, author, committer, message);
  }

  static int getDiffStart(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith("diff --git")) return i;
    }
    return lines.length;
  }

  Map toJson() => {
        "id": id,
        "message": message,
        "committer_name": committer.name,
        "committer_email": committer.mail,
        "author_name": author.name,
        "author_email": author.mail
      };
}

class GitRemote {
  final String name;
  final String address;

  GitRemote(this.name, this.address);

  static List<GitRemote> getGitRemotes(Directory dir,
      {ProcessSystem processSystem: const ProcessSystem()}) {
    var args = ["remote", "-v"];
    var res =
        processSystem.runProcessSync("git", args, workingDirectory: dir.path);
    if (0 != res.exitCode) throw new ProcessException("git", args, res.stderr);
    var lines = (res.stdout as String).split("\n").where((str) => "" != str);
    return lines
        .map((line) => new GitRemote.fromRemoteString(line))
        .toSet()
        .toList();
  }

  factory GitRemote.fromRemoteString(String str) {
    var parts = str.split("\t");
    var name = parts[0].trim();
    var address = parts[1].split(" ")[0].trim();
    return new GitRemote(name, address);
  }

  bool operator ==(other) => other is GitRemote ? other.name == name : false;

  int get hashCode => name.hashCode;

  Map toJson() => {"name": name, "url": address};
}

class GitBranch {
  final String name;
  final String reference;
  final String id;

  GitBranch(this.name, this.reference, this.id);

  static String getCurrentBranchName(Directory dir,
      {ProcessSystem processSystem: const ProcessSystem(),
      Map<String, String> environment}) {
    if (null == environment) environment = Platform.environment;
    if (null != environment["CI_BRANCH"]) return environment["CI_BRANCH"];

    var travisBranch = travis.getBranch(environment);
    if (travisBranch != null) return travisBranch;

    var args = ["rev-parse", "--abbrev-ref", "HEAD"];
    var result =
        processSystem.runProcessSync("git", args, workingDirectory: dir.path);
    if (0 != result.exitCode)
      throw new ProcessException("git", args, result.stderr, result.exitCode);
    var name = (result.stdout as String).trim();
    return name;
  }

  static GitBranch getCurrent(Directory dir,
      {ProcessSystem processSystem: const ProcessSystem()}) {
    var name = getCurrentBranchName(dir, processSystem: processSystem);
    var args = ["show-ref", "$name", "--heads"];
    var result =
        processSystem.runProcessSync("git", args, workingDirectory: dir.path);
    if (0 != result.exitCode)
      throw new ProcessException("git", args, result.stderr, result.exitCode);
    var parts = result.stdout.split("\n")[0].split(" ");
    var id = parts[0];
    var ref = parts[1];
    return new GitBranch(name, ref, id);
  }
}

class GitData {
  final String branch;
  final List<GitRemote> remotes;
  final GitCommit headCommit;

  GitData(this.branch, this.remotes, this.headCommit);

  static GitData getGitData(Directory dir,
      {ProcessSystem processSystem: const ProcessSystem()}) {
    var branch = GitBranch.getCurrent(dir, processSystem: processSystem);
    var remotes = GitRemote.getGitRemotes(dir);
    var commit =
        GitCommit.getCommit(dir, branch.id, processSystem: processSystem);
    return new GitData(branch.name, remotes, commit);
  }

  Map toJson() =>
      {"head": headCommit, "branch": branch, "remotes": remotes.toList()};
}
