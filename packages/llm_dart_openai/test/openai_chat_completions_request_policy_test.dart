import 'package:llm_dart_openai/src/provider/deepseek_options.dart';
import 'package:llm_dart_openai/src/chat_completions/openai_chat_completions_request_policy.dart';
import 'package:llm_dart_openai/src/language/openai_generate_text_options.dart';
import 'package:llm_dart_openai/src/provider/resolved_openai_options.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI chat completions request policy', () {
    test('projects DeepSeek provider-native request fields', () {
      final policy = openAIChatCompletionsRequestPolicyFor('deepseek');
      final body = <String, Object?>{};

      policy.addProviderRequestFields(
        modelId: 'deepseek-chat',
        body: body,
        providerOptions: const ResolvedOpenAIGenerateTextOptions(
          common: OpenAIGenerateTextOptions(
            logprobs: OpenAILogProbs.top(4),
          ),
          deepseek: DeepSeekGenerateTextOptions(
            logprobs: false,
            topLogprobs: 2,
            frequencyPenalty: 0.1,
            presencePenalty: 0.2,
          ),
        ),
        effectiveReasoningEffort: null,
      );

      expect(body, {
        'logprobs': false,
        'top_logprobs': 2,
        'frequency_penalty': 0.1,
        'presence_penalty': 0.2,
      });
    });

    test('drops unsupported DeepSeek reasoner fields with warnings', () {
      final policy = openAIChatCompletionsRequestPolicyFor('deepseek');
      final body = <String, Object?>{
        'logprobs': true,
        'top_logprobs': 2,
        'frequency_penalty': 0.1,
        'presence_penalty': 0.2,
      };
      final warnings = <ModelWarning>[];

      policy.applyCompatibilityRules(
        modelId: 'deepseek-reasoner',
        commonOptions: const OpenAIGenerateTextOptions(),
        body: body,
        warnings: warnings,
      );

      expect(body, isEmpty);
      expect(warnings.map((warning) => warning.field), [
        'logprobs',
        'topLogprobs',
        'frequencyPenalty',
        'presencePenalty',
      ]);
    });
  });
}
