import 'dart:convert';

import '../common/transport_exception.dart';

/// Decodes provider HTTP response bodies into JSON objects without coupling
/// the parsing logic to any root compatibility error types.
abstract final class JsonObjectResponseDecoder {
  static Map<String, dynamic> decode(
    Object? responseData, {
    String? sourceName,
  }) {
    final source = sourceName ?? 'Unknown';

    if (responseData is Map<String, dynamic>) {
      return responseData;
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
        if (jsonData is Map<String, dynamic>) {
          return jsonData;
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

  static String _truncateResponse(Object? responseData) {
    final stringValue = responseData?.toString() ?? '';
    if (stringValue.length <= 500) {
      return stringValue;
    }
    return '${stringValue.substring(0, 500)}...';
  }
}
