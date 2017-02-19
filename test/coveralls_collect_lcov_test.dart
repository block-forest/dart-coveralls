library dart_coveralls.test.collect_lcov;

import 'dart:io' show File;

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:dart_coveralls/dart_coveralls.dart';

void main() {
  var lcovTest =
      new File(p.join(p.current, 'test', 'lcov_test.txt')).readAsStringSync();

  group("LcovPart", () {
    test("parse", () {
      var document = LcovDocument.parse(lcovTest);
      expect(document.parts.length, equals(2));
      expect(
          document.parts.first.heading, equals("SF:collection/src/utils.dart"));
      expect(
          document.parts.first.fileName, equals("collection/src/utils.dart"));
      expect(document.parts.first.content, equals("DA:12,0\n"));
      expect(document.parts.last.heading,
          equals("SF:string_scanner/src/utils.dart"));
      expect(document.parts.last.fileName,
          equals("string_scanner/src/utils.dart"));
      expect(
          document.parts.last.content,
          equals("DA:10,0\nDA:14,0\nDA:15,0\nDA:16,0" +
              "\nDA:17,0\nDA:22,0\nDA:23,0\nDA:26,0\nDA:27,0"));
    });
  });
}
