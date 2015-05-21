library dart_coveralls.test.coveralls_entities;

import 'package:dart_coveralls/dart_coveralls.dart';
import 'package:mock/mock.dart';
import 'package:test/test.dart';

import 'mock_classes.dart';

void _expectLineValue(LineValue lv, int lineNumber, int lineCount) {
  expect(lv.lineNumber, equals(lineNumber));
  expect(lv.lineCount, equals(lineCount));
}

FileMock _absoluteMock(String path, String absolutePath) {
  var mock = new FileMock();
  var absolute = new FileMock();
  absolute
    ..when(callsTo("get absolute")).alwaysReturn(absolute)
    ..when(callsTo("get path")).alwaysReturn(absolutePath);
  mock
    ..when(callsTo("get path")).alwaysReturn(path)
    ..when(callsTo("get absolute")).alwaysReturn(absolute);
  return mock;
}

void main() {
  group("PackageDartFiles", () {
    var testFiles = [
      _absoluteMock(
          "test/test.dart", "/home/user/dart/dart_coveralls/test/test.dart"),
      _absoluteMock("test/other_test.dart",
          "/home/user/dart/dart_coveralls/test/other_test.dart")
    ];
    var implFiles = [
      _absoluteMock(
          "lib/program.dart", "/home/user/dart/dart_coveralls/lib/program.dart")
    ];
    var dartFiles = new PackageDartFiles(testFiles, implFiles);

    test("isTestFile", () {
      expect(dartFiles.isTestFile(_absoluteMock(
              "test.dart", "/home/user/dart/dart_coveralls/test/test.dart")),
          isTrue);
      expect(dartFiles.isTestFile(_absoluteMock(
              "test.dart", "/home/user/dart/dart_coveralls/lib/program.dart")),
          isFalse);
    });

    test("isImplementationFile", () {
      expect(dartFiles.isImplementationFile(_absoluteMock(
              "test.dart", "/home/user/dart/dart_coveralls/test/test.dart")),
          isFalse);
      expect(dartFiles.isImplementationFile(_absoluteMock("program.dart",
          "/home/user/dart/dart_coveralls/lib/program.dart")), isTrue);
    });

    test("isSameAbsolutePath", () {
      var f1 = _absoluteMock("test.dart", "/root/test.dart");
      var f2 = _absoluteMock("./test.dart", "/root/./test.dart");
      var f3 = _absoluteMock("nottest.dart", "/root/nottest.dart");

      expect(PackageDartFiles.sameAbsolutePath(f1, f2), isTrue);
      f1.calls("get absolute").verify(happenedOnce);
      f2.calls("get absolute").verify(happenedOnce);
      expect(PackageDartFiles.sameAbsolutePath(f1, f3), isFalse);
    });

    test("isTestDirectory", () {
      var testDir = new DirectoryMock()
        ..when(callsTo("get path")).thenReturn("test");
      var notTestDir = new DirectoryMock()
        ..when(callsTo("get path")).thenReturn("nottest");
      var fileMock = new FileMock();

      expect(PackageDartFiles.isTestDirectory(testDir), isTrue);
      expect(PackageDartFiles.isTestDirectory(notTestDir), isFalse);
      expect(PackageDartFiles.isTestDirectory(fileMock), isFalse);
      testDir.calls("get path").verify(happenedOnce);
      notTestDir.calls("get path").verify(happenedOnce);
    });
  });

  group("PackageFilter", () {
    test("getPackageName", () {
      var fileSystem = new FileSystemMock();
      var fileMock = new FileMock();
      var dirMock = new DirectoryMock();

      dirMock.when(callsTo("get path")).thenReturn(".");
      fileMock
          .when(callsTo("readAsStringSync"))
          .thenReturn("name: dart_coveralls");
      fileSystem
          .when(callsTo("getFile", "./pubspec.yaml"))
          .thenReturn(fileMock);

      var name = PackageFilter.getPackageName(dirMock, fileSystem);
      expect(name, equals("dart_coveralls"));
      fileSystem
          .getLogs(callsTo("getFile", "./pubspec.yaml"))
          .verify(happenedOnce);
      fileMock.getLogs(callsTo("readAsStringSync")).verify(happenedOnce);
      dirMock.getLogs(callsTo("get path")).verify(happenedOnce);
    });

    test("accept", () {
      var testFiles = [
        _absoluteMock(
            "test/test.dart", "/home/user/dart/dart_coveralls/test/test.dart"),
        _absoluteMock("test/other_test.dart",
            "/home/user/dart/dart_coveralls/test/other_test.dart")
      ];
      var implFiles = [
        _absoluteMock("lib/program.dart",
            "/home/user/dart/dart_coveralls/lib/program.dart")
      ];

      var fsMock = new FileSystemMock()
        ..when(callsTo(
                "getFile", "/home/user/dart/dart_coveralls/test/test.dart"))
            .alwaysReturn(testFiles.first);

      var packageFilter = new PackageFilter(
          "dart_coveralls", new PackageDartFiles(testFiles, implFiles));
      var noTestFilter = new PackageFilter(
          "dart_coveralls", new PackageDartFiles(testFiles, implFiles),
          excludeTestFiles: true);

      expect(packageFilter.accept("dart_coveralls/program.dart"), isTrue);
      expect(packageFilter.accept("not_coveralls/program.dart"), isFalse);

      expect(packageFilter.accept(
          "/home/user/dart/dart_coveralls/test/test.dart", fsMock), isTrue);
      expect(noTestFilter.accept(
          "/home/user/dart/dart_coveralls/test/test.dart", fsMock), isFalse);
    });
  });

  group("LineValue", () {
    test("fromLcovNumeration", () {
      var str = "DA:27,0";
      var lineValue = LineValue.parse(str);

      _expectLineValue(lineValue, 27, 0);
    });

    test("covString", () {
      var str = "DA:27,0";
      var lineValue1 = LineValue.parse(str);
      var lineValue2 = new LineValue.noCount(10);

      expect(lineValue1.lineCount, equals(0));
      expect(lineValue2.lineCount, isNull);
    });
  });

  group('SourceFileReport', () {
    test('toJson', () {
      var file = new SourceFile('a', 'b');

      var str = "DA:3,3\nDA:4,5\nDA:6,3";
      var coverage = Coverage.parse(str);

      var report = new SourceFileReport(file, coverage);

      expect(report.toJson(), equals({
        'name': 'a',
        'source': 'b',
        "coverage": [null, null, 3, 5, null, 3]
      }));
    });
  });

  group("Coverage", () {
    test("fromLcovNumeration", () {
      var str = "DA:3,3\nDA:4,5\nDA:6,3";
      var coverage = Coverage.parse(str);
      var values = coverage.values;
      _expectLineValue(values[0], 1, null);
      _expectLineValue(values[1], 2, null);
      _expectLineValue(values[2], 3, 3);
      _expectLineValue(values[3], 4, 5);
      _expectLineValue(values[4], 5, null);
      _expectLineValue(values[5], 6, 3);
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
        fileSystem
            .when(callsTo("getFile", "dart_coveralls/test.file"))
            .thenReturn(fileMock);
        fileSystem
            .when(callsTo("getFile", "./packages/dart_coveralls/test.file"))
            .thenReturn(fileMock);
        fileMock
            .when(callsTo("resolveSymbolicLinksSync"))
            .thenReturn("resolvedFile.dart");
        fileSystem
            .when(callsTo("getFile", "resolvedFile.dart"))
            .thenReturn(resolvedFile);
        resolvedFile.when(callsTo("get absolute")).thenReturn(resolvedFile);

        var file = SourceFile.getSourceFile("dart_coveralls/test.file", dirMock,
            fileSystem: fileSystem);

        expect(identical(file, resolvedFile), isTrue);
      });
    });
  });
}
