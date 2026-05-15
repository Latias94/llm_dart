import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_chat_completions_stream_state.dart';
import 'openai_chat_completions_support.dart';
import 'openai_streaming_support.dart';

Map<String, Object?>? openAIChatCompletionsAsMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  return null;
}

List<Object?> openAIChatCompletionsAsList(Object? value) {
  if (value is List<Object?>) {
    return value;
  }

  if (value is List) {
    return List<Object?>.from(value);
  }

  return const [];
}

List<Object?>? openAIChatCompletionsJsonListOrNull(Object? value) {
  if (value is List<Object?>) {
    return value;
  }

  if (value is List) {
    return List<Object?>.from(value);
  }

  return null;
}

String? openAIChatCompletionsAsString(Object? value) =>
    value is String ? value : null;

int? openAIChatCompletionsAsInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return null;
}

DateTime? openAIChatCompletionsDecodeResponseTimestamp(
  Map<String, Object?> response,
) {
  final created = openAIChatCompletionsAsInt(response['created']);
  if (created == null) {
    return null;
  }

  return DateTime.fromMillisecondsSinceEpoch(
    created * 1000,
    isUtc: true,
  );
}

Map<String, Object?>? openAIChatCompletionsFirstChoice(
  Map<String, Object?> response,
) {
  final choices = openAIChatCompletionsAsList(response['choices']);
  if (choices.isEmpty) {
    return null;
  }

  return openAIChatCompletionsAsMap(choices.first);
}

List<Object?>? openAIChatCompletionsDecodeLogprobs(Object? value) {
  final logprobs = openAIChatCompletionsAsMap(value);
  return openAIChatCompletionsJsonListOrNull(logprobs?['content']);
}

UsageStats? openAIChatCompletionsDecodeUsage(Map<String, Object?>? usage) {
  if (usage == null) {
    return null;
  }

  final inputTokens = openAIChatCompletionsAsInt(usage['prompt_tokens']);
  final outputTokens = openAIChatCompletionsAsInt(usage['completion_tokens']);
  final totalTokens = openAIChatCompletionsAsInt(usage['total_tokens']) ??
      ((inputTokens != null && outputTokens != null)
          ? inputTokens + outputTokens
          : null);
  final completionDetails =
      openAIChatCompletionsAsMap(usage['completion_tokens_details']);

  return UsageStats(
    inputTokens: inputTokens,
    outputTokens: outputTokens,
    totalTokens: totalTokens,
    reasoningTokens: openAIChatCompletionsAsInt(
      completionDetails?['reasoning_tokens'],
    ),
  );
}

FinishReason openAIChatCompletionsMapFinishReason(String? rawReason) {
  return switch (rawReason) {
    null || 'stop' => FinishReason.stop,
    'length' => FinishReason.maxTokens,
    'tool_calls' => FinishReason.toolCalls,
    'content_filter' => FinishReason.contentFilter,
    'cancelled' => FinishReason.aborted,
    _ => FinishReason.other,
  };
}

String? openAIChatCompletionsExtractContentDelta(
  Map<String, Object?> delta,
) {
  return openAIChatCompletionsAsString(delta['content']);
}

String? openAIChatCompletionsExtractReasoningDelta(
  Map<String, Object?> delta,
) {
  return firstOpenAINonEmptyString([
    openAIChatCompletionsAsString(delta['reasoning_content']),
    openAIChatCompletionsAsString(delta['reasoning']),
    openAIChatCompletionsAsString(delta['thinking']),
  ]);
}

final class OpenAIChatCompletionsStreamMetadataAdapter {
  final OpenAIChatCompletionsSupport support;
  final OpenAIChatCompletionsStreamState state;
  final Map<String, Object?> chunk;

  const OpenAIChatCompletionsStreamMetadataAdapter({
    required this.support,
    required this.state,
    required this.chunk,
  });

  ProviderMetadata? response() => support.providerMetadata({
        'responseId': state.responseId,
      });

  ProviderMetadata? reasoning() => support.providerMetadata({
        'responseId': state.responseId,
      });

  ProviderMetadata? text(List<Object?>? logprobs) => support.providerMetadata({
        'responseId': state.responseId,
        'logprobs': logprobs,
      });

  ProviderMetadata? tool(int index) => support.providerMetadata({
        'responseId': state.responseId,
        'toolIndex': index,
      });

  ProviderMetadata? finish() => support.providerMetadata({
        'responseId': state.responseId,
        'systemFingerprint':
            openAIChatCompletionsAsString(chunk['system_fingerprint']),
        if (state.logprobs.isNotEmpty)
          'logprobs': List<Object?>.unmodifiable(state.logprobs),
      });
}
