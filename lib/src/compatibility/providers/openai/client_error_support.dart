import 'package:llm_dart_transport/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart' show Logger;

import '../../../../core/llm_error.dart';
import '../../../../utils/http_response_handler.dart';

/// OpenAI-family HTTP error adapter shared by the compatibility client facade.
class OpenAIClientErrorAdapter {
  final Logger logger;

  OpenAIClientErrorAdapter(this.logger);

  Future<void> ensureSuccessStatus(Response response, String endpoint) {
    return HttpResponseHandler.ensureSuccessStatus(
      response,
      providerName: 'OpenAI',
      logger: logger,
      onFailure: (failedResponse) => _handleErrorResponse(
        failedResponse,
        endpoint,
      ),
    );
  }

  Future<LLMError> handleDioError(DioException exception) async {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutError('Request timeout: ${exception.message}');
      case DioExceptionType.badResponse:
        final statusCode = exception.response?.statusCode;
        final responseData = exception.response?.data;

        if (statusCode == null) {
          return ResponseFormatError(
            'HTTP error without status code',
            responseData?.toString() ?? '',
          );
        }

        final details = await DioErrorHandler.extractErrorResponseDetails(
          responseData,
          fallbackMessage: '$statusCode',
          mapMessageExtractor: extractErrorMessageFromMap,
        );

        return HttpErrorMapper.mapStatusCode(
          statusCode,
          details.message,
          details.responseData,
        );
      case DioExceptionType.cancel:
        return CancelledError(exception.message ?? 'Request cancelled');
      case DioExceptionType.connectionError:
        return const GenericError('Connection error');
      case DioExceptionType.badCertificate:
        return const GenericError('SSL certificate error');
      case DioExceptionType.unknown:
        return GenericError('Unknown error: ${exception.message}');
    }
  }

  String? extractErrorMessageFromMap(Map<String, dynamic> responseData) {
    final error = responseData['error'] as Map<String, dynamic>?;
    if (error != null) {
      final message = error['message'] as String?;
      final type = error['type'] as String?;
      final code = error['code']?.toString();

      if (message != null) {
        final parts = <String>[message];
        if (type != null) {
          parts.add('type: $type');
        }
        if (code != null) {
          parts.add('code: $code');
        }
        return parts.join(', ');
      }
    }

    final directMessage = responseData['message'] as String?;
    if (directMessage != null) {
      return directMessage;
    }

    return null;
  }

  Future<void> _handleErrorResponse(Response response, String endpoint) async {
    final statusCode = response.statusCode;
    final errorData = response.data;

    if (statusCode == null) {
      throw ResponseFormatError(
        'OpenAI $endpoint API returned unknown error',
        errorData?.toString() ?? '',
      );
    }

    final details = await DioErrorHandler.extractErrorResponseDetails(
      errorData,
      fallbackMessage:
          'OpenAI $endpoint API returned error status: $statusCode',
      mapMessageExtractor: extractErrorMessageFromMap,
    );

    throw HttpErrorMapper.mapStatusCode(
      statusCode,
      details.message,
      details.responseData,
    );
  }
}
