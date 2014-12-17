part of dart_coveralls;


abstract class GitPerson implements CoverallsReportable {
  final String name;
  final String mail;
  
  
  GitPerson(this.name, this.mail);
  
  
  GitPerson.fromPersonString(String str)
      : name = getPersonName(str),
        mail = getPersonMail(str);
  
  
  static String getPersonName(String str) =>
      str.split("<")[0].trim();
  
  static String getPersonMail(String str) {
    var mail = new RegExp(r"<(.*?)>").firstMatch(str).group(0);
    return mail.substring(1, mail.length - 1);
  }
}



class GitCommitter extends GitPerson {
  GitCommitter(String name, String mail) : super(name, mail);
  
  
  GitCommitter.fromPersonString(String str) : super.fromPersonString(str);
  
  
  String covString() =>
      "\"committer_name\": ${JSON.encode(name)}, "
      + "\"committer_email\": ${JSON.encode(mail)}";
}



class GitAuthor extends GitPerson {
  GitAuthor(String name, String mail) : super(name, mail);
  
  
  GitAuthor.fromPersonString(String str) : super.fromPersonString(str);
  
  
  String covString() =>
      "\"author_name\": ${JSON.encode(name)}, "
      + "\"author_email\": ${JSON.encode(mail)}";
}



class GitCommit implements CoverallsReportable {
  final String id;
  final GitAuthor author;
  final GitCommitter committer;
  final String message;
  
  
  GitCommit(this.id, this.author, this.committer, this.message);
  
  
  static Future<GitCommit> getGitCommit(GitDir dir, String id) {
    return dir.getCommit(id).then((commit) {
      var message = commit.message;
      var author = new GitAuthor.fromPersonString(commit.author);
      var committer = new GitCommitter.fromPersonString(commit.committer);
      return new GitCommit(id, author, committer, message);
    });
  }
  
  
  String covString() => "{\"id\": \"$id\", ${author.covString()}, " + 
      "${committer.covString()}, \"message\": ${JSON.encode(message)}}";
}



class GitRemote implements CoverallsReportable {
  final String name;
  final String address;
  
  
  GitRemote(this.name, this.address);
  
  
  static Future<List<GitRemote>> getGitRemotes(GitDir dir) {
    return dir.runCommand(["remote", "-v"]).then((result) {
      var remotes = new Set<GitRemote>();
      var lines = (result.stdout as String).split("\n")..removeLast();
      remotes.addAll(lines.map((line) => new GitRemote.fromRemoteString(line)));
      return remotes.toList();
    });
  }
  
  
  factory GitRemote.fromRemoteString(String str) {
    var parts = str.split("\t");
    var name = parts[0].trim();
    var address = parts[1].split(" ")[0].trim();
    return new GitRemote(name, address);
  }
  
  
  bool operator==(other) => other is GitRemote ? other.name == name : false;
  
  
  int get hashCode => name.hashCode;
  
  
  String covString() => "{\"name\": ${JSON.encode(name)}, " + 
      "\"url\": ${JSON.encode(address)}}";
}



class GitData implements CoverallsReportable {
  final String branch;
  final List<GitRemote> remotes;
  final GitCommit headCommit;
  
  
  GitData(this.branch, this.remotes, this.headCommit);
  
  
  static Future<GitData> getGitData(Directory gitDir) {
    return GitDir.fromExisting(gitDir.path).then((gitDir) {
      return gitDir.getCurrentBranch().then((branch) {
        var branchName = branch.branchName;
        return GitRemote.getGitRemotes(gitDir).then((remotes) {
          return GitCommit.getGitCommit(gitDir, branch.sha).then((c) {
            return new GitData(branchName, remotes, c);
          });
        });
      });
    });
  }
  
  
  String covString() => "{\"head\": ${headCommit.covString()}, \"branch\": " +
      "\"$branch\", \"remotes\": [" +
          remotes.map((r) => r.covString()).join(", ") + "]}";
}