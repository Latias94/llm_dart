import '../../../../core/llm_error.dart';

void validateAnthropicMessageSequence(List<Map<String, dynamic>> messages) {
  if (messages.isEmpty) {
    return;
  }

  if (messages.first['role'] != 'user') {
    // Anthropic prefers user-led conversations, but legacy callers have
    // historically relied on the server to reject stricter cases.
  }

  for (var index = 0; index < messages.length; index++) {
    final content = messages[index]['content'];
    if (content is List && content.isEmpty) {
      throw const InvalidRequestError('Message content cannot be empty');
    }
    if (content is String && content.trim().isEmpty) {
      throw const InvalidRequestError('Message content cannot be empty');
    }
  }
}
