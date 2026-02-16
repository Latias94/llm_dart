import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_groq/provider_tools.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';

void main() {
  group('Groq browser_search provider tool (OpenAI-compatible)', () {
    test('injects browser_search into chat/completions tools array', () async {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.groq.com/openai/v1/',
        model: 'openai/gpt-oss-20b',
      );

      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'groq',
        providerName: 'Groq',
      );
      final client = FakeOpenAIClient(config)
        ..jsonResponse = {
          'choices': [
            {
              'message': {'content': 'ok'},
            }
          ],
        };
      final chat = OpenAIChat(client, config);

      await chat.chat(
        [ChatMessage.user('hi')],
        providerTools: [GroqProviderTools.browserSearch()],
      );

      final body = client.lastJsonBody;
      expect(body, isNotNull);

      final tools = body!['tools'] as List?;
      expect(tools, isNotNull);
      expect(
        tools,
        anyElement(
          predicate(
            (t) => t is Map && t['type'] == 'browser_search',
            'tool type == browser_search',
          ),
        ),
      );
    });
  });
}
