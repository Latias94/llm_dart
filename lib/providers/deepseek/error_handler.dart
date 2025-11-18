import 'package:dio/dio.dart';

import '../../core/llm_error.dart';

/// DeepSeek-specific error handler
///
/// This class provides specialized error handling for DeepSeek API responses,
/// mapping DeepSeek error codes and messages to appropriate LLM error types.
/// Reference: https://api-docs.deepseek.com/quick_start/error_codes
class DeepSeekErrorHandler {
  /// Handle DeepSeek-specific errors from API responses
  static LLMError handleDeepSeekError(
    int statusCode,
    String message,
    Map<String, dynamic>? responseData,
  ) {
    // Check for DeepSeek-specific error patterns first
    final deepSeekError = _mapDeepSeekSpecificError(
      statusCode,
      message,
      responseData,
    );
    if (deepSeekError != null) return deepSeekError;

    // Fall back to standard HTTP error mapping
    return HttpErrorMapper.mapStatusCode(statusCode, message, responseData);
  }

  /// Handle Dio errors specifically for DeepSeek
  static Future<LLMError> handleDioError(DioException e) async {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    if (statusCode != null) {
      String errorMessage = 'DeepSeek API error';

      // Extract error message from DeepSeek response format
      if (responseData is Map<String, dynamic>) {
        final error = responseData['error'];
        if (error is Map<String, dynamic>) {
          errorMessage = error['message']?.toString() ?? errorMessage;
        } else if (error is String) {
          errorMessage = error;
        }
      } else if (responseData is String) {
        errorMessage = responseData;
      }

      return handleDeepSeekError(
        statusCode,
        errorMessage,
        responseData is Map<String, dynamic> ? responseData : null,
      );
    }

    // Fall back to standard Dio error handling
    return await DioErrorHandler.handleDioError(e, 'DeepSeek');
  }

  /// Map DeepSeek-specific error patterns
  static LLMError? _mapDeepSeekSpecificError(
    int statusCode,
    String message,
    Map<String, dynamic>? responseData,
  ) {
    switch (statusCode) {
      case 400:
        // DeepSeek: Invalid Format
        if (message.toLowerCase().contains('invalid format') ||
            message.toLowerCase().contains('invalid request body')) {
          return InvalidRequestError('Invalid request format: $message');
        }
        break;

      case 401:
        // DeepSeek: Authentication Fails
        if (message.toLowerCase().contains('authentication fails') ||
            message.toLowerCase().contains('wrong api key')) {
          return AuthError(
              'Authentication failed: Check your DeepSeek API key');
        }
        break;

      case 402:
        // DeepSeek: Insufficient Balance
        if (message.toLowerCase().contains('insufficient balance') ||
            message.toLowerCase().contains('run out of balance')) {
          return QuotaExceededError(
            'Insufficient balance: Please top up your DeepSeek account',
            quotaType: 'credits',
          );
        }
        break;

      case 422:
        // DeepSeek: Invalid Parameters
        if (message.toLowerCase().contains('invalid parameters')) {
          return InvalidRequestError('Invalid parameters: $message');
        }
        break;

      case 429:
        // DeepSeek: Rate Limit Reached
        if (message.toLowerCase().contains('rate limit') ||
            message.toLowerCase().contains('sending requests too quickly')) {
          return RateLimitError(
            'Rate limit exceeded: Please pace your requests reasonably',
            retryAfter: _extractRetryAfter(responseData),
          );
        }
        break;

      case 500:
        // DeepSeek: Server Error
        if (message.toLowerCase().contains('server encounters an issue')) {
          return ServerError(
            'DeepSeek server error: Please retry after a brief wait',
            statusCode: statusCode,
          );
        }
        break;

      case 503:
        // DeepSeek: Server Overloaded
        if (message.toLowerCase().contains('server is overloaded') ||
            message.toLowerCase().contains('high traffic')) {
          return ServerError(
            'DeepSeek server overloaded: Please retry after a brief wait',
            statusCode: statusCode,
          );
        }
        break;
    }

    return null;
  }

  /// Extract retry-after duration from DeepSeek response
  static Duration? _extractRetryAfter(Map<String, dynamic>? responseData) {
    if (responseData == null) return null;

    // Check for retry_after in various formats
    final retryAfter = responseData['retry_after'] ??
        responseData['retry-after'] ??
        responseData['Retry-After'];

    if (retryAfter is int) {
      return Duration(seconds: retryAfter);
    } else if (retryAfter is String) {
      final seconds = int.tryParse(retryAfter);
      if (seconds != null) {
        return Duration(seconds: seconds);
      }
    }

    return null;
  }

  /// Check if error indicates model not available
  static bool isModelNotAvailable(String message) {
    return message.toLowerCase().contains('model') &&
        (message.toLowerCase().contains('not found') ||
            message.toLowerCase().contains('not available') ||
            message.toLowerCase().contains('unsupported'));
  }

  /// Check if error indicates insufficient quota/balance
  static bool isQuotaExceeded(String message) {
    return message.toLowerCase().contains('insufficient balance') ||
        message.toLowerCase().contains('quota') ||
        message.toLowerCase().contains('billing') ||
        message.toLowerCase().contains('run out of balance');
  }

  /// Check if error indicates rate limiting
  static bool isRateLimited(String message) {
    return message.toLowerCase().contains('rate limit') ||
        message.toLowerCase().contains('too quickly') ||
        message.toLowerCase().contains('too many requests');
  }

  /// Check if error indicates server issues
  static bool isServerError(String message) {
    return message.toLowerCase().contains('server error') ||
        message.toLowerCase().contains('server encounters') ||
        message.toLowerCase().contains('server overloaded') ||
        message.toLowerCase().contains('high traffic');
  }
}
