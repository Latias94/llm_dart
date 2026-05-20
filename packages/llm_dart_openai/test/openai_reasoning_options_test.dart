import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI reasoning options', () {
    test('maps shared reasoning effort to OpenAI effort levels', () {
      final warnings = <ModelWarning>[];

      expect(
        mapSharedOpenAIReasoningEffort(
          const GenerateTextReasoningOptions.enabled(
            effort: ReasoningEffort.high,
          ),
          warnings: warnings,
        ),
        OpenAIReasoningEffort.high,
      );
      expect(warnings, isEmpty);
    });

    test('disabled shared reasoning maps to none', () {
      final warnings = <ModelWarning>[];

      expect(
        mapSharedOpenAIReasoningEffort(
          const GenerateTextReasoningOptions.disabled(),
          warnings: warnings,
        ),
        OpenAIReasoningEffort.none,
      );
      expect(warnings, isEmpty);
    });

    test('budget tokens are warning-dropped', () {
      final warnings = <ModelWarning>[];

      expect(
        mapSharedOpenAIReasoningEffort(
          const GenerateTextReasoningOptions.enabled(
            effort: ReasoningEffort.low,
            budgetTokens: 1024,
          ),
          warnings: warnings,
        ),
        OpenAIReasoningEffort.low,
      );
      expect(warnings, hasLength(1));
      expect(warnings.single.field, 'options.reasoning.budgetTokens');
    });

    test('generate text options facade still exports split option types', () {
      const options = OpenAIGenerateTextOptions(
        reasoningEffort: OpenAIReasoningEffort.xhigh,
        logprobs: OpenAILogProbs.enabled(),
        truncation: OpenAIResponseTruncation.disabled,
        include: [OpenAIResponsesInclude.reasoningEncryptedContent],
        promptCacheRetention: OpenAIPromptCacheRetention.twentyFourHours,
        systemMessageMode: OpenAISystemMessageMode.developer,
      );

      expect(options.reasoningEffort, OpenAIReasoningEffort.xhigh);
      expect(options.logprobs, isA<OpenAILogProbs>());
      expect(options.truncation, OpenAIResponseTruncation.disabled);
      expect(
          options.include, [OpenAIResponsesInclude.reasoningEncryptedContent]);
      expect(
        options.promptCacheRetention,
        OpenAIPromptCacheRetention.twentyFourHours,
      );
      expect(options.systemMessageMode, OpenAISystemMessageMode.developer);
    });
  });
}
