import '../common/call_options.dart';
import '../common/model_warning.dart';
import '../common/provider_metadata.dart';
import '../common/usage_stats.dart';
import '../content/content_part.dart';
import '../prompt/prompt_message.dart';
import '../stream/text_stream_event.dart';

enum FinishReason {
  stop,
  maxTokens,
  toolCalls,
  contentFilter,
  aborted,
  error,
  other,
}

final class GenerateTextOptions {
  final int? maxOutputTokens;
  final double? temperature;
  final List<String>? stopSequences;
  final double? topP;
  final int? topK;

  const GenerateTextOptions({
    this.maxOutputTokens,
    this.temperature,
    this.stopSequences,
    this.topP,
    this.topK,
  });
}

final class GenerateTextRequest {
  final List<PromptMessage> prompt;
  final GenerateTextOptions options;
  final CallOptions callOptions;

  GenerateTextRequest({
    required List<PromptMessage> prompt,
    this.options = const GenerateTextOptions(),
    this.callOptions = const CallOptions(),
  }) : prompt = List.unmodifiable(prompt);
}

final class GenerateTextResult {
  final List<ContentPart> content;
  final FinishReason finishReason;
  final String? rawFinishReason;
  final String? responseId;
  final DateTime? responseTimestamp;
  final String? responseModelId;
  final UsageStats? usage;
  final ProviderMetadata? providerMetadata;
  final List<ModelWarning> warnings;

  GenerateTextResult({
    required List<ContentPart> content,
    required this.finishReason,
    this.rawFinishReason,
    this.responseId,
    this.responseTimestamp,
    this.responseModelId,
    this.usage,
    this.providerMetadata,
    List<ModelWarning> warnings = const [],
  })  : content = List.unmodifiable(content),
        warnings = List.unmodifiable(warnings);

  String get text =>
      content.whereType<TextContentPart>().map((part) => part.text).join();

  String? get reasoningText {
    final value = content
        .whereType<ReasoningContentPart>()
        .map((part) => part.text)
        .join();
    return value.isEmpty ? null : value;
  }
}

abstract interface class LanguageModel {
  String get providerId;

  String get modelId;

  Future<GenerateTextResult> generate(GenerateTextRequest request);

  Stream<TextStreamEvent> stream(GenerateTextRequest request);
}

Future<GenerateTextResult> generateText({
  required LanguageModel model,
  required List<PromptMessage> prompt,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
}) {
  return model.generate(
    GenerateTextRequest(
      prompt: prompt,
      options: options,
      callOptions: callOptions,
    ),
  );
}

Stream<TextStreamEvent> streamText({
  required LanguageModel model,
  required List<PromptMessage> prompt,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
}) {
  return model.stream(
    GenerateTextRequest(
      prompt: prompt,
      options: options,
      callOptions: callOptions,
    ),
  );
}
