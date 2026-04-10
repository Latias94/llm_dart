import 'package:dio/dio.dart';

import '../common/transport_exception.dart';
import 'utf8_stream_decoder.dart';

typedef InvalidDioResponseBodyFactory = Object Function(String message);

/// Extracts a byte stream from a Dio streaming response payload.
Stream<List<int>> extractDioResponseByteStream(
  Object? responseBody, {
  String sourceName = 'response body',
  Uri? uri,
  InvalidDioResponseBodyFactory? invalidBodyErrorFactory,
}) {
  return switch (responseBody) {
    ResponseBody() => responseBody.stream,
    Stream<List<int>>() => responseBody,
    _ => throw _invalidResponseBodyError(
        responseBody,
        sourceName: sourceName,
        uri: uri,
        invalidBodyErrorFactory: invalidBodyErrorFactory,
      ),
  };
}

/// Decodes a Dio streaming response payload into a UTF-8 text stream.
Stream<String> decodeDioResponseTextStream(
  Object? responseBody, {
  String sourceName = 'response body',
  Uri? uri,
  InvalidDioResponseBodyFactory? invalidBodyErrorFactory,
}) {
  return extractDioResponseByteStream(
    responseBody,
    sourceName: sourceName,
    uri: uri,
    invalidBodyErrorFactory: invalidBodyErrorFactory,
  ).decodeUtf8Stream();
}

Never _invalidResponseBodyError(
  Object? responseBody, {
  required String sourceName,
  required Uri? uri,
  required InvalidDioResponseBodyFactory? invalidBodyErrorFactory,
}) {
  final message =
      'Expected a streaming $sourceName but received ${responseBody.runtimeType}';
  final factory = invalidBodyErrorFactory;
  if (factory != null) {
    throw factory(message);
  }

  throw TransportResponseFormatException(
    message,
    uri: uri,
  );
}
