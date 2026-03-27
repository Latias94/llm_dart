import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/src/openai_options.dart';
import 'package:llm_dart_openai/src/openai_responses_codec.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIResponsesCodec', () {
    test(
        'encodes assistant replay metadata for text, reasoning, tool calls, and compaction',
        () {
      const codec = OpenAIResponsesCodec();

      final request = codec.encodeRequest(
        modelId: 'gpt-5-mini',
        prompt: [
          UserPromptMessage.text('Hi'),
          AssistantPromptMessage(
            parts: const [
              TextPromptPart(
                'Commentary',
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'msg_commentary',
                    'phase': 'commentary',
                  },
                }),
              ),
              TextPromptPart(
                'Final answer',
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'msg_final',
                    'phase': 'final_answer',
                  },
                }),
              ),
              ReasoningPromptPart(
                'Thinking step 1',
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'rs_1',
                    'encryptedContent': 'enc_1',
                  },
                }),
              ),
              ReasoningPromptPart(
                'Thinking step 2',
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'rs_1',
                    'reasoningEncryptedContent': 'enc_2',
                  },
                }),
              ),
              ToolCallPromptPart(
                toolCallId: 'call_1',
                toolName: 'weather',
                input: {
                  'city': 'Hong Kong',
                },
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'fc_1',
                  },
                }),
              ),
              CustomPromptPart(
                kind: 'openai.compaction',
                data: {
                  'encryptedContent': 'enc_comp',
                  'compact_threshold': 50000,
                },
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'cmp_1',
                  },
                }),
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
            'role': 'assistant',
            'id': 'msg_commentary',
            'phase': 'commentary',
            'content': [
              {
                'type': 'output_text',
                'text': 'Commentary',
              },
            ],
          },
          {
            'role': 'assistant',
            'id': 'msg_final',
            'phase': 'final_answer',
            'content': [
              {
                'type': 'output_text',
                'text': 'Final answer',
              },
            ],
          },
          {
            'type': 'reasoning',
            'id': 'rs_1',
            'encrypted_content': 'enc_2',
            'summary': [
              {
                'type': 'summary_text',
                'text': 'Thinking step 1',
              },
              {
                'type': 'summary_text',
                'text': 'Thinking step 2',
              },
            ],
          },
          {
            'type': 'function_call',
            'call_id': 'call_1',
            'id': 'fc_1',
            'name': 'weather',
            'arguments': '{"city":"Hong Kong"}',
          },
          {
            'type': 'compaction',
            'id': 'cmp_1',
            'encrypted_content': 'enc_comp',
            'compact_threshold': 50000,
          },
        ],
      );
    });

    test('decodes provider metadata needed for replay fidelity', () {
      const codec = OpenAIResponsesCodec();

      final result = codec.decodeGenerateResponse({
        'id': 'resp_1',
        'status': 'completed',
        'output': [
          {
            'id': 'msg_1',
            'type': 'message',
            'status': 'completed',
            'role': 'assistant',
            'phase': 'commentary',
            'content': [
              {
                'type': 'output_text',
                'text': 'Hello',
              },
            ],
          },
          {
            'id': 'rs_1',
            'type': 'reasoning',
            'encrypted_content': 'enc_reason',
            'summary': [
              {
                'type': 'summary_text',
                'text': 'Think',
              },
            ],
          },
          {
            'id': 'cmp_1',
            'type': 'compaction',
            'encrypted_content': 'enc_comp',
          },
        ],
      });

      final textPart = result.content.whereType<TextContentPart>().single;
      final reasoningPart =
          result.content.whereType<ReasoningContentPart>().single;
      final customPart = result.content.whereType<CustomContentPart>().single;

      expect(
        textPart.providerMetadata?['openai'],
        containsPair('itemId', 'msg_1'),
      );
      expect(
        textPart.providerMetadata?['openai'],
        containsPair('phase', 'commentary'),
      );
      expect(
        reasoningPart.providerMetadata?['openai'],
        containsPair('itemId', 'rs_1'),
      );
      expect(
        reasoningPart.providerMetadata?['openai'],
        containsPair('reasoningEncryptedContent', 'enc_reason'),
      );
      expect(customPart.kind, 'openai.compaction');
      expect(
        customPart.providerMetadata?['openai'],
        containsPair('itemId', 'cmp_1'),
      );
      expect(
        customPart.providerMetadata?['openai'],
        containsPair('encryptedContent', 'enc_comp'),
      );
    });
  });
}
