import 'dart:typed_data';

import 'package:dio/dio.dart' show FormData;
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_elevenlabs/client.dart';

class FakeElevenLabsClient extends ElevenLabsClient {
  String? lastEndpoint;
  Map<String, dynamic>? lastBody;
  Map<String, String>? lastQueryParams;

  FormData? lastFormData;

  Uint8List ttsBytes = Uint8List(0);
  Map<String, dynamic> sttJson = const <String, dynamic>{'text': ''};

  FakeElevenLabsClient(super.config);

  @override
  Future<Uint8List> postBinary(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastBody = data;
    lastQueryParams =
        queryParams == null ? null : Map<String, String>.from(queryParams);
    return ttsBytes;
  }

  @override
  Future<Map<String, dynamic>> postFormData(
    String endpoint,
    FormData formData, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastQueryParams =
        queryParams == null ? null : Map<String, String>.from(queryParams);
    lastFormData = formData;
    return sttJson;
  }
}
