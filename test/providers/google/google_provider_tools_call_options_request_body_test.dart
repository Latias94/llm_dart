import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';

void main() {
  group('Google providerTools call options request body', () {
    test('includes codeExecution tool when passed per-call', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.0-flash',
      );

      final client = FakeGoogleClient(
        config,
        defaultJsonResponse: {
          'modelVersion': config.model,
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'ok'}
                ],
              },
            },
          ],
        },
      );

      final chat = GoogleChat(client, config);

      await chat.chatPrompt(
        Prompt(
          messages: [
            PromptMessage(
              role: PromptRole.user,
              parts: [const TextPart('hi')],
            ),
          ],
        ),
        providerTools: const [
          ProviderTool(
            id: 'google.code_execution',
            name: 'code_execution',
          ),
        ],
      );

      final tools = client.lastBody?['tools'] as List?;
      expect(tools, isNotNull);
      expect(
        tools!.any((e) => e is Map && e.containsKey('codeExecution')),
        isTrue,
      );
    });
  });
}
