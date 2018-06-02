library dart_coveralls.test.coveralls_entities;

import 'dart:convert';

import 'package:dart_coveralls/dart_coveralls.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mock_classes.dart';

void _expectLineValue(LineValue lv, int lineNumber, int lineCount) {
  expect(lv.lineNumber, equals(lineNumber));
  expect(lv.lineCount, equals(lineCount));
}

FileMock _absoluteMock(String pathString, String absolutePathString) {
  var mock = new FileMock();
  var absolute = new FileMock();
  when(absolute.absolute).thenReturn(absolute);
  when(absolute.path).thenReturn(absolutePathString);
  when(mock.path).thenReturn(pathString);
  when(mock.absolute).thenReturn(absolute);
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
      expect(
          dartFiles.isTestFile(_absoluteMock(
              "test.dart", "/home/user/dart/dart_coveralls/test/test.dart")),
          isTrue);
      expect(
          dartFiles.isTestFile(_absoluteMock(
              "test.dart", "/home/user/dart/dart_coveralls/lib/program.dart")),
          isFalse);
    });

    test("isImplementationFile", () {
      expect(
          dartFiles.isImplementationFile(_absoluteMock(
              "test.dart", "/home/user/dart/dart_coveralls/test/test.dart")),
          isFalse);
      expect(
          dartFiles.isImplementationFile(_absoluteMock("program.dart",
              "/home/user/dart/dart_coveralls/lib/program.dart")),
          isTrue);
    });

    test("isSameAbsolutePath", () {
      var f1 = _absoluteMock("test.dart", "/root/test.dart");
      var f2 = _absoluteMock("./test.dart", "/root/./test.dart");
      var f3 = _absoluteMock("nottest.dart", "/root/nottest.dart");

      expect(PackageDartFiles.sameAbsolutePath(f1, f2), isTrue);
      verify(f1.absolute).called(1);
      verify(f2.absolute).called(1);
      expect(PackageDartFiles.sameAbsolutePath(f1, f3), isFalse);
    });

    test("isTestDirectory", () {
      var testDir = new DirectoryMock();
      when(testDir.path).thenReturn("test");

      var notTestDir = new DirectoryMock();
      when(notTestDir.path).thenReturn("nottest");

      var fileMock = new FileMock();

      expect(PackageDartFiles.isTestDirectory(testDir), isTrue);
      expect(PackageDartFiles.isTestDirectory(notTestDir), isFalse);
      expect(PackageDartFiles.isTestDirectory(fileMock), isFalse);
      verify(testDir.path).called(1);
      verify(notTestDir.path).called(1);
    });
  });

  group("PackageFilter", () {
    test("getPackageName", () {
      var fileSystem = new FileSystemMock();
      var fileMock = new FileMock();
      when(fileMock.readAsStringSync()).thenReturn("name: dart_coveralls");
      when(fileSystem.file("./pubspec.yaml")).thenReturn(fileMock);

      var name = PackageFilter.getPackageName('.', fileSystem);
      expect(name, equals("dart_coveralls"));
      verify(fileSystem.file("./pubspec.yaml")).called(1);
      verify(fileMock.readAsStringSync()).called(1);
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

      var fsMock = new FileSystemMock();
      when(fsMock.file("/home/user/dart/dart_coveralls/test/test.dart")).thenReturn(testFiles.first);
      var packageFilter = new PackageFilter(
          "dart_coveralls", new PackageDartFiles(testFiles, implFiles));
      var noTestFilter = new PackageFilter(
          "dart_coveralls", new PackageDartFiles(testFiles, implFiles),
          excludeTestFiles: true);

      expect(packageFilter.accept("dart_coveralls/program.dart"), isTrue);
      expect(packageFilter.accept("not_coveralls/program.dart"), isFalse);

      expect(
          packageFilter.accept(
              "/home/user/dart/dart_coveralls/test/test.dart", fsMock),
          isTrue);
      expect(
          noTestFilter.accept(
              "/home/user/dart/dart_coveralls/test/test.dart", fsMock),
          isFalse);
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
      var file = new SourceFile('a', utf8.encode('b'));

      var str = "DA:3,3\nDA:4,5\nDA:6,3";
      var coverage = Coverage.parse(str);

      var report = new SourceFileReport(file, coverage);

      expect(
          report.toJson(),
          equals({
            'name': 'a',
            'source_digest': '92eb5ffee6ae2fec3ad71c777531578f',
            'coverage': [null, null, 3, 5, null, 3]
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

        when(fileMock.existsSync()).thenReturn(true);
        when(fileMock.absolute).thenReturn(fileMock);
        when(fileSystem.file("test.file")).thenReturn(fileMock);
        var file =
            SourceFile.getSourceFile("test.file", '.', fileSystem: fileSystem);

        expect(identical(fileMock, file), isTrue);
      });

      test("Non existent File", () {
        var fileMock = new FileMock();
        var fileSystem = new FileSystemMock();
        var dirMock = new DirectoryMock();
        var resolvedFile = new FileMock();

        when(fileMock.existsSync()).thenReturn(false);
        when(dirMock.path).thenReturn(".");
        when(fileSystem.file("dart_coveralls/test.file")).thenReturn(fileMock);
        when(fileSystem.file("./packages/dart_coveralls/test.file")).thenReturn(fileMock);
        when(fileMock.resolveSymbolicLinksSync()).thenReturn("resolvedFile.dart");
        when(fileSystem.file("resolvedFile.dart")).thenReturn(resolvedFile);
        when(resolvedFile.absolute).thenReturn(resolvedFile);

        var file = SourceFile.getSourceFile("dart_coveralls/test.file", '.',
            fileSystem: fileSystem);

        expect(identical(file, resolvedFile), isTrue);
      });
    });
  });
}
