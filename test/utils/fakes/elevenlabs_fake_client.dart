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

  Map<String, String> ttsHeaders = const <String, String>{};
  Map<String, String> sttHeaders = const <String, String>{};

  FakeElevenLabsClient(super.config);

  @override
  Future<Uint8List> postBinary(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) async {
    final response = await postBinaryWithResponseHeaders(
      endpoint,
      data,
      queryParams: queryParams,
      cancelToken: cancelToken,
    );
    return response.data;
  }

  @override
  Future<({Uint8List data, Map<String, String> headers})>
      postBinaryWithResponseHeaders(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastBody = data;
    lastQueryParams =
        queryParams == null ? null : Map<String, String>.from(queryParams);
    return (data: ttsBytes, headers: ttsHeaders);
  }

  @override
  Future<Map<String, dynamic>> postFormData(
    String endpoint,
    FormData formData, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) async {
    final response = await postFormDataWithResponseHeaders(
      endpoint,
      formData,
      queryParams: queryParams,
      cancelToken: cancelToken,
    );
    return response.json;
  }

  @override
  Future<({Map<String, dynamic> json, Map<String, String> headers})>
      postFormDataWithResponseHeaders(
    String endpoint,
    FormData formData, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastQueryParams =
        queryParams == null ? null : Map<String, String>.from(queryParams);
    lastFormData = formData;
    return (json: sttJson, headers: sttHeaders);
  }
}
