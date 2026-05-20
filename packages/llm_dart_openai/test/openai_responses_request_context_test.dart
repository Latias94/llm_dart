import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_openai/src/openai_responses_request_context.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI Responses request context', () {
    test('resolves defaults from model capabilities', () {
      final context = resolveOpenAIResponsesRequestContext(
        modelId: 'gpt-5-mini',
        providerOptions: const OpenAIGenerateTextOptions(),
      );

      expect(context.isReasoningModel, isTrue);
      expect(context.systemMessageMode, OpenAISystemMessageMode.developer);
      expect(context.store, isTrue);
      expect(context.hasConversation, isFalse);
    });

    test('provider options override reasoning and prompt context', () {
      final context = resolveOpenAIResponsesRequestContext(
        modelId: 'gpt-5-mini',
        providerOptions: const OpenAIGenerateTextOptions(
          conversation: 'conv_1',
          forceReasoning: false,
          store: false,
          systemMessageMode: OpenAISystemMessageMode.system,
        ),
      );

      expect(context.isReasoningModel, isFalse);
      expect(context.systemMessageMode, OpenAISystemMessageMode.system);
      expect(context.store, isFalse);
      expect(context.hasConversation, isTrue);
    });
  });
}
