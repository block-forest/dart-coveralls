import "package:dart_coveralls/dart_coveralls.dart";
import "package:unittest/unittest.dart";


void expectLineValue(LineValue lv, int lineNumber, int lineCount) {
  expect(lv.lineNumber, equals(lineNumber));
  expect(lv.lineCount, equals(lineCount));
}


main() {
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

  });
}