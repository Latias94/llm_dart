import '../../../../core/capability.dart';
import '../../../../core/llm_error.dart';

final class AnthropicChatStreamErrorEvents {
  const AnthropicChatStreamErrorEvents();

  ChatStreamEvent? parseError(Map<String, dynamic> json) {
    final error = json['error'] as Map<String, dynamic>?;
    if (error == null) {
      return null;
    }

    final message = error['message'] as String? ?? 'Unknown error';
    final errorType = error['type'] as String? ?? 'api_error';

    return ErrorEvent(_mapAnthropicError(errorType, message));
  }

  LLMError _mapAnthropicError(String errorType, String message) {
    switch (errorType) {
      case 'authentication_error':
        return AuthError(message);
      case 'permission_error':
        return AuthError('Permission denied: $message');
      case 'invalid_request_error':
        return InvalidRequestError(message);
      case 'not_found_error':
        return InvalidRequestError('Not found: $message');
      case 'rate_limit_error':
        return RateLimitError(message);
      case 'api_error':
      case 'overloaded_error':
        return ProviderError('Anthropic API error: $message');
      default:
        return ProviderError('Anthropic API error ($errorType): $message');
    }
  }
}
