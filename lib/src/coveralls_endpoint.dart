library dart_coveralls.coveralls_endpoint;

import 'dart:async' show Future;

import 'package:http/http.dart' show MultipartRequest, MultipartFile;

import 'log.dart';

class CoverallsEndpoint {
  static const String COVERALLS_ADDRESS = "https://coveralls.io/api/v1/jobs";

  final Uri coverallsAddress;

  CoverallsEndpoint([coverallsAddress = COVERALLS_ADDRESS])
      : coverallsAddress = coverallsAddress is Uri ? coverallsAddress :
      Uri.parse(COVERALLS_ADDRESS);

  MultipartRequest getCoverallsRequest(String json) {
    var req = new MultipartRequest("POST", coverallsAddress);
    req.files.add(
        new MultipartFile.fromString("json_file", json, filename: "json_file"));
    return req;
  }

  Future sendToCoveralls(String json) {
    var req = getCoverallsRequest(json);
    try {
      return req.send().asStream().toList().then((responses) {
        return responses.single.stream.toList().then((intValues) {
          var msg = stringFromIntLines(intValues);
          if (200 == responses.single.statusCode) return log.info("200 OK");
          throw new Exception(responses.single.reasonPhrase + "\n$msg");
        });
      });
    } catch (e) {
      return new Future.error(e);
    }
  }

  String stringFromIntLines(List<List<int>> lines) {
    return lines.map((line) => new String.fromCharCodes(line)).join("\n");
  }
}
