part of 'dio_error_handler.dart';

Future<({String message, Map<String, dynamic>? responseData})>
    _extractDioErrorResponseDetails(
  dynamic data, {
  required String fallbackMessage,
  String? Function(Map<String, dynamic> responseData)? mapMessageExtractor,
}) async {
  if (data is Map<String, dynamic>) {
    return _buildErrorDetailsFromMap(
      data,
      mapMessageExtractor: mapMessageExtractor,
    );
  }

  if (data is ResponseBody || data is Stream<List<int>>) {
    try {
      final content = await collectDioResponseTextBody(data);
      if (content.isEmpty) {
        return (
          message: fallbackMessage,
          responseData: null,
        );
      }

      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        return _buildErrorDetailsFromMap(
          decoded,
          mapMessageExtractor: mapMessageExtractor,
        );
      }

      return (
        message: content,
        responseData: null,
      );
    } catch (streamError) {
      return (
        message: 'Failed to read error response: $streamError',
        responseData: null,
      );
    }
  }

  if (data != null) {
    return (
      message: data.toString(),
      responseData: null,
    );
  }

  return (
    message: fallbackMessage,
    responseData: null,
  );
}

({String message, Map<String, dynamic>? responseData})
    _buildErrorDetailsFromMap(
  Map<String, dynamic> responseData, {
  String? Function(Map<String, dynamic> responseData)? mapMessageExtractor,
}) {
  final extractedMessage = _extractErrorMessageFromMap(
    responseData,
    mapMessageExtractor: mapMessageExtractor,
  );

  return (
    message: extractedMessage ?? responseData.toString(),
    responseData: responseData,
  );
}

String? _extractErrorMessageFromMap(
  Map<String, dynamic> responseData, {
  String? Function(Map<String, dynamic> responseData)? mapMessageExtractor,
}) {
  final customMessage = mapMessageExtractor?.call(responseData);
  if (customMessage != null && customMessage.isNotEmpty) {
    return customMessage;
  }

  final error = responseData['error'];
  if (error is Map<String, dynamic>) {
    return error['message']?.toString() ??
        responseData['message']?.toString() ??
        responseData.toString();
  }

  if (error is String) {
    return error;
  }

  return responseData['message']?.toString();
}
