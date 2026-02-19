import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/compat.dart';
import 'package:test/test.dart';

class _TestResponse
    implements
        ChatResponseWithAssistantMessage,
        ChatResponseWithFinishReason,
        ChatResponseWithResponseMetadata {
  @override
  final String? text;

  @override
  final List<ToolCall>? toolCalls;

  @override
  final String? thinking;

  @override
  final UsageInfo? usage;

  @override
  final Map<String, dynamic>? providerMetadata;

  @override
  final ChatMessage assistantMessage;

  @override
  final LLMFinishReason? finishReason;

  @override
  final LLMResponseMetadataPart? responseMetadata;

  const _TestResponse({
    required this.text,
    required this.toolCalls,
    required this.thinking,
    required this.usage,
    required this.providerMetadata,
    required this.assistantMessage,
    required this.finishReason,
    required this.responseMetadata,
  });
}

void main() {
  group('wrapChatResponseWithProviderMetadataAlias', () {
    test('preserves responseMetadata and finishReason', () {
      final meta = LLMResponseMetadataPart(
        id: 'resp_1',
        modelId: 'gpt-test',
        headers: const {'x-test': '1'},
      );

      final response = _TestResponse(
        text: 'hello',
        toolCalls: const [],
        thinking: null,
        usage: null,
        providerMetadata: const {
          'openai': {'id': 'resp_1'}
        },
        assistantMessage: ChatMessage.assistant('hello'),
        finishReason: const LLMFinishReason(
          unified: LLMUnifiedFinishReason.stop,
          raw: 'stop',
        ),
        responseMetadata: meta,
      );

      final wrapped = wrapChatResponseWithProviderMetadataAlias(
        response,
        baseKey: 'openai',
        aliasKey: 'openai.chat',
      );

      expect(wrapped, isA<ChatResponseWithAssistantMessage>());
      expect(wrapped, isA<ChatResponseWithFinishReason>());
      expect(wrapped, isA<ChatResponseWithResponseMetadata>());

      final wrappedMeta =
          (wrapped as ChatResponseWithResponseMetadata).responseMetadata;
      expect(wrappedMeta, same(meta));

      final wrappedFinish =
          (wrapped as ChatResponseWithFinishReason).finishReason;
      expect(wrappedFinish, isNotNull);
      expect(wrappedFinish!.unified, equals(LLMUnifiedFinishReason.stop));

      final pm = wrapped.providerMetadata;
      expect(pm, isNotNull);
      expect(pm, contains('openai'));
      expect(pm, contains('openai.chat'));
      expect(pm!['openai.chat'], equals(pm['openai']));
    });
  });
}
