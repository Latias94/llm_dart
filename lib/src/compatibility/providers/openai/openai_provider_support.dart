import '../../../../models/chat_models.dart';
import '../../../../providers/openai/config.dart';
import 'chat.dart';
import 'client.dart';
import 'embeddings.dart';

/// Provider-owned helper/support logic that should not keep inflating the main
/// compatibility delegation shell.
class OpenAIProviderSupport {
  final OpenAIConfig config;
  final OpenAIClient client;
  final OpenAIChat chat;
  final OpenAIEmbeddings embeddings;

  OpenAIProviderSupport({
    required this.config,
    required this.client,
    required this.chat,
    required this.embeddings,
  });

  Future<int> getEmbeddingDimensions() {
    return embeddings.getEmbeddingDimensions();
  }

  Future<({bool valid, String? error})> checkModel() async {
    try {
      final requestBody = {
        'model': config.model,
        'messages': [
          {'role': 'user', 'content': 'hi'}
        ],
        'stream': false,
        'max_tokens': 1,
      };

      await client.postJson('chat/completions', requestBody);
      return (valid: true, error: null);
    } catch (error) {
      return (valid: false, error: error.toString());
    }
  }

  Future<List<String>> generateSuggestions(List<ChatMessage> messages) async {
    try {
      if (messages.isEmpty) {
        return [];
      }

      final recentMessages = messages.length > 10
          ? messages.sublist(messages.length - 10)
          : messages;

      final conversationContext = recentMessages
          .map((message) => '${message.role.name}: ${message.content}')
          .join('\n');

      const systemPrompt = '''
You are a helpful assistant that generates relevant follow-up questions based on conversation history.

Rules:
1. Generate 3-5 questions that naturally continue the conversation
2. Questions should be specific and actionable
3. Avoid repeating topics already covered
4. Return only the questions, one per line
5. No numbering, bullets, or extra formatting
6. Keep questions concise and clear
''';

      final userPrompt = '''
Based on this conversation, suggest follow-up questions:

$conversationContext
''';

      final response = await chat.chatWithTools(
        [ChatMessage.system(systemPrompt), ChatMessage.user(userPrompt)],
        null,
      );

      return _parseQuestions(response.text ?? '');
    } catch (error) {
      client.logger.warning('Failed to generate suggestions: $error');
      return [];
    }
  }

  List<String> _parseQuestions(String responseText) {
    return responseText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && line.contains('?'))
        .map(
          (line) =>
              line.replaceAll(RegExp(r'^[\d\-\.\)\(•\*\s]*'), '').trim(),
        )
        .where((question) => question.isNotEmpty)
        .take(5)
        .toList();
  }
}
