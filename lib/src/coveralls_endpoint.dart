library dart_coveralls.coveralls_endpoint;

import 'dart:async' show Future;
import 'dart:convert' show json;

import 'package:http/http.dart' show MultipartRequest, MultipartFile, Response;

import 'coveralls_entities.dart';
import 'log.dart';

class CoverallsEndpoint {
  static const String COVERALLS_ADDRESS = "https://coveralls.io/api/v1/jobs";

  final Uri coverallsAddress;

  CoverallsEndpoint([coverallsAddress = COVERALLS_ADDRESS])
      : coverallsAddress = coverallsAddress is Uri
            ? coverallsAddress
            : Uri.parse(COVERALLS_ADDRESS);

  MultipartRequest _getCoverallsRequest(String jsonString) {
    var req = new MultipartRequest("POST", coverallsAddress);
    req.files.add(
        new MultipartFile.fromString("json_file", jsonString, filename: "json_file"));
    return req;
  }

  Future<CoverallsResult> sendToCoveralls(String jsonString) async {
    var req = _getCoverallsRequest(jsonString);
    log.info('Sending coverage information. JSON length: ${jsonString.length}');
    var streamedResponse = await req.send();
    Response response = await Response.fromStream(streamedResponse);
    log.info('Coverage information sent.');

    var msg = response.body;

    if (response.statusCode != 200) {
      throw new Exception("${response.reasonPhrase}");
    }
    log.info("200 OK");
    log.info("Response:\n$msg");

    var resultJson = json.decode(msg);
    return new CoverallsResult.fromJson(resultJson);
  }
}
