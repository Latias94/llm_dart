import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('GoogleProvider forwards providerTools', () {
    test('passes providerTools to chatPrompt request builder', () async {
      final config = const GoogleConfig(
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

      final provider = GoogleProvider(config, client: client);

      await provider.chatPrompt(
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
