import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/src/openai_options.dart';
import 'package:llm_dart_openai/src/openai_responses_codec.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIResponsesCodec', () {
    test('encodes assistant reasoning replay and skips unsupported replay-only parts', () {
      const codec = OpenAIResponsesCodec();

      final request = codec.encodeRequest(
        modelId: 'gpt-5-mini',
        prompt: [
          UserPromptMessage.text('Hi'),
          AssistantPromptMessage(
            parts: const [
              ReasoningPromptPart(
                'Thinking',
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'rs_1',
                    'encryptedContent': 'enc_1',
                  },
                }),
              ),
              ReasoningFilePromptPart(
                mediaType: 'image/png',
                bytes: [1, 2, 3],
              ),
              CustomPromptPart(
                kind: 'openai.compaction',
                data: {
                  'type': 'compaction',
                  'id': 'cmp_1',
                  'encrypted_content': 'enc_comp',
                },
              ),
            ],
          ),
        ],
        options: const GenerateTextOptions(),
        providerOptions: const OpenAIGenerateTextOptions(),
        stream: false,
      );

      expect(
        request.body['input'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text': 'Hi',
              },
            ],
          },
          {
            'type': 'reasoning',
            'id': 'rs_1',
            'encrypted_content': 'enc_1',
            'summary': [
              {
                'type': 'summary_text',
                'text': 'Thinking',
              },
            ],
          },
          {
            'type': 'compaction',
            'id': 'cmp_1',
            'encrypted_content': 'enc_comp',
          },
        ],
      );
    });
  });
}
