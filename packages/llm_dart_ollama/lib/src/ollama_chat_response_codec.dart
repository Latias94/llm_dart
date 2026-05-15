import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'ollama_tool_codec.dart';

final class OllamaChatResponseCodec {
  final String modelId;
  final OllamaToolCodec toolCodec;

  const OllamaChatResponseCodec({
    required this.modelId,
    this.toolCodec = const OllamaToolCodec(),
  });

  GenerateTextResult decodeGenerateResponse(
    Map<String, Object?> json, {
    required List<ModelWarning> warnings,
  }) {
    final content = <ContentPart>[
      ..._decodeReasoningContent(json),
      ..._decodeTextContent(json),
      ..._decodeToolCallContent(json),
    ];

    return GenerateTextResult(
      content: content,
      finishReason: decodeFinishReason(
        json,
        hasToolCalls: content.whereType<ToolCallContentPart>().isNotEmpty,
      ),
      rawFinishReason: asString(json['done_reason']),
      responseModelId: asString(json['model']) ?? modelId,
      responseTimestamp: parseTimestamp(json['created_at']),
      usage: decodeUsage(json),
      providerMetadata: decodeProviderMetadata(json),
      warnings: warnings,
    );
  }

  List<ContentPart> _decodeTextContent(Map<String, Object?> json) {
    final message = asObject(json['message']);
    final text = asString(message?['content']) ?? asString(json['response']);
    if (text == null || text.isEmpty) return const [];
    return [TextContentPart(text)];
  }

  List<ContentPart> _decodeReasoningContent(Map<String, Object?> json) {
    final message = asObject(json['message']);
    final text = asString(message?['thinking']) ?? asString(json['thinking']);
    if (text == null || text.isEmpty) return const [];
    return [ReasoningContentPart(text)];
  }

  List<ContentPart> _decodeToolCallContent(Map<String, Object?> json) {
    final toolCalls = toolCodec.decodeToolCalls(asObject(json['message']));
    if (toolCalls.isEmpty) return const [];
    return toolCalls
        .map((toolCall) => ToolCallContentPart(toolCall))
        .toList(growable: false);
  }

  UsageStats? decodeUsage(Map<String, Object?> json) {
    final inputTokens = asInt(json['prompt_eval_count']);
    final outputTokens = asInt(json['eval_count']);
    final usage = UsageStats(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: switch ((inputTokens, outputTokens)) {
        (final input?, final output?) => input + output,
        _ => null,
      },
    );
    return usage.isEmpty ? null : usage;
  }

  ProviderMetadata? decodeProviderMetadata(Map<String, Object?> json) {
    final values = <String, Object?>{
      if (json['created_at'] != null) 'createdAt': json['created_at'],
      if (json['done_reason'] != null) 'doneReason': json['done_reason'],
      if (json['total_duration'] != null)
        'totalDurationNanos': json['total_duration'],
      if (json['load_duration'] != null)
        'loadDurationNanos': json['load_duration'],
      if (json['prompt_eval_duration'] != null)
        'promptEvalDurationNanos': json['prompt_eval_duration'],
      if (json['eval_duration'] != null)
        'evalDurationNanos': json['eval_duration'],
    };
    if (values.isEmpty) return null;
    return ProviderMetadata.forNamespace('ollama', values);
  }

  FinishReason decodeFinishReason(
    Map<String, Object?> json, {
    required bool hasToolCalls,
  }) {
    if (hasToolCalls) return FinishReason.toolCalls;
    return switch (asString(json['done_reason'])) {
      'stop' || null => FinishReason.stop,
      'length' => FinishReason.maxTokens,
      'abort' => FinishReason.aborted,
      'error' => FinishReason.error,
      _ => FinishReason.other,
    };
  }

  Map<String, Object?>? asObject(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) return Map<String, Object?>.from(value);
    return null;
  }

  String? asString(Object? value) => value is String ? value : null;

  int? asInt(Object? value) => value is num ? value.toInt() : null;

  DateTime? parseTimestamp(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
