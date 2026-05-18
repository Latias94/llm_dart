import 'dart:convert';

import '../common/transport_exception.dart';

/// Decodes provider HTTP response bodies into JSON objects without coupling
/// the parsing logic to any root compatibility error types.
abstract final class JsonObjectResponseDecoder {
  static Map<String, Object?> decode(
    Object? responseData, {
    String? sourceName,
  }) {
    final source = sourceName ?? 'Unknown';

    if (responseData is Map) {
      return _copyJsonObject(
        responseData,
        source: source,
      );
    }

    if (responseData is String) {
      if (responseData.trim().startsWith('<')) {
        throw TransportResponseFormatException(
          '$source API returned HTML page instead of JSON response. '
          'This usually indicates an incorrect API endpoint or authentication issue.',
          responseBody: _truncateResponse(responseData),
        );
      }

      try {
        final jsonData = jsonDecode(responseData);
        if (jsonData is Map) {
          return _copyJsonObject(
            jsonData,
            source: source,
          );
        }

        throw TransportResponseFormatException(
          '$source API returned JSON that is not an object',
          responseBody: _truncateResponse(responseData),
        );
      } on FormatException catch (error) {
        throw TransportResponseFormatException(
          '$source API returned invalid JSON: ${error.message}',
          responseBody: _truncateResponse(responseData),
          cause: error,
        );
      }
    }

    throw TransportResponseFormatException(
      '$source API returned unexpected response type: ${responseData.runtimeType}',
      responseBody: _truncateResponse(responseData),
    );
  }

  static Map<String, Object?> _copyJsonObject(
    Map value, {
    required String source,
  }) {
    final jsonObject = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw TransportResponseFormatException(
          '$source API returned JSON object with a non-string key.',
          responseBody: _truncateResponse(value),
        );
      }

      jsonObject[entry.key as String] = entry.value;
    }

    return jsonObject;
  }

  static String _truncateResponse(Object? responseData) {
    final stringValue = responseData?.toString() ?? '';
    if (stringValue.length <= 500) {
      return stringValue;
    }
    return '${stringValue.substring(0, 500)}...';
  }
}
