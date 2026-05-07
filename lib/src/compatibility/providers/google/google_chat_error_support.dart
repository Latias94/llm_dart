part of 'chat.dart';

final class _GoogleChatErrorSupport {
  const _GoogleChatErrorSupport();

  Future<LLMError> handleDioError(DioException e) async {
    if (e.response?.data is Map<String, dynamic>) {
      final errorData = e.response!.data as Map<String, dynamic>;
      try {
        return handleGoogleApiError(errorData);
      } catch (googleError) {
        if (googleError is LLMError) {
          return googleError;
        }
      }
    }

    return await DioErrorHandler.handleDioError(e, 'Google');
  }

  LLMError handleGoogleApiError(Map<String, dynamic> responseData) {
    if (!responseData.containsKey('error')) {
      throw ArgumentError('No error found in response data');
    }

    final error = responseData['error'] as Map<String, dynamic>;
    final message = error['message'] as String? ?? 'Unknown error';
    final details = error['details'] as List?;

    if (details != null) {
      for (final detail in details) {
        if (detail is Map && detail['reason'] == 'API_KEY_INVALID') {
          return const AuthError('Invalid Google API key');
        }
      }
    }

    return ProviderError('Google API error: $message');
  }

  GoogleChatResponse parseResponse(Map<String, dynamic> responseData) {
    if (responseData.containsKey('error')) {
      throw handleGoogleApiError(responseData);
    }

    return GoogleChatResponse(responseData);
  }
}
