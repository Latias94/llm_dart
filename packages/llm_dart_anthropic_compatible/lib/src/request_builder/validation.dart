part of 'package:llm_dart_anthropic_compatible/request_builder.dart';

extension _AnthropicRequestBuilderValidation on AnthropicRequestBuilder {
  void _validateMessageSequence(List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) return;

    if (messages.first['role'] != 'user') {
      throw const InvalidRequestError(
        'First non-system message must be from the user (Anthropic requirement).',
      );
    }

    for (final message in messages) {
      final content = message['content'];
      if (content is List && content.isEmpty) {
        throw const InvalidRequestError('Message content cannot be empty');
      }
      if (content is String && content.trim().isEmpty) {
        throw const InvalidRequestError('Message content cannot be empty');
      }
    }
  }
}
