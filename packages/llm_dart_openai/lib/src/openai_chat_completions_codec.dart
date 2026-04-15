import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'openai_chat_completions_support.dart';
import 'openai_model_capabilities.dart';
import 'openai_options.dart';
import 'openai_response_format.dart';
import 'openai_streaming_support.dart';
import 'resolved_openai_options.dart';

part 'openai_chat_completions_request_encoder.dart';
part 'openai_chat_completions_stream_decoder.dart';

final class OpenAIChatCompletionsRequest {
  final Map<String, Object?> body;
  final List<ModelWarning> warnings;

  OpenAIChatCompletionsRequest({
    required Map<String, Object?> body,
    List<ModelWarning> warnings = const [],
  })  : body = Map.unmodifiable(body),
        warnings = List.unmodifiable(warnings);
}

final class OpenAIChatCompletionsStreamState extends OpenAIStreamState {
  final Set<String> emittedSourceIds = {};
}

final class OpenAIChatCompletionsCodec {
  final String providerNamespace;

  const OpenAIChatCompletionsCodec({
    this.providerNamespace = 'openai',
  });

  OpenAIChatCompletionsSupport get _support => OpenAIChatCompletionsSupport(
        providerNamespace: providerNamespace,
      );

  OpenAIChatCompletionsRequest encodeRequest({
    required String modelId,
    required List<PromptMessage> prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required GenerateTextOptions options,
    required ResolvedOpenAIGenerateTextOptions providerOptions,
    required bool stream,
  }) {
    return _OpenAIChatCompletionsCodecRequestEncoder(this)._encodeRequest(
      modelId: modelId,
      prompt: prompt,
      tools: tools,
      toolChoice: toolChoice,
      options: options,
      providerOptions: providerOptions,
      stream: stream,
    );
  }

  GenerateTextResult decodeGenerateResponse(
    Map<String, Object?> response, {
    List<ModelWarning> warnings = const [],
  }) {
    _throwIfError(response);

    final choice = _firstChoice(response);
    final message = _asMap(choice?['message']) ?? const <String, Object?>{};
    final content = <ContentPart>[];
    final textLogprobs = _decodeChatLogprobs(choice?['logprobs']);

    final decodedText = _support.decodeAssistantText(message);
    if (decodedText.reasoning case final reasoning? when reasoning.isNotEmpty) {
      content.add(
        ReasoningContentPart(
          reasoning,
          providerMetadata: _providerMetadata({
            'finishReason': _asString(choice?['finish_reason']),
          }),
        ),
      );
    }

    if (decodedText.text.isNotEmpty) {
      content.add(
        TextContentPart(
          decodedText.text,
          providerMetadata: _providerMetadata({
            'finishReason': _asString(choice?['finish_reason']),
            'logprobs': textLogprobs,
          }),
        ),
      );
    }

    final toolCalls = _support.decodeToolCalls(
      _asList(message['tool_calls']),
    );
    content.addAll(toolCalls);
    content.addAll(_support.decodeTopLevelSources(response));

    return GenerateTextResult(
      content: content,
      finishReason: _mapFinishReason(_asString(choice?['finish_reason'])),
      rawFinishReason: _asString(choice?['finish_reason']),
      responseId: _asString(response['id']),
      responseTimestamp: _decodeResponseTimestamp(response),
      responseModelId: _asString(response['model']),
      usage: _decodeUsage(_asMap(response['usage'])),
      providerMetadata: _support.responseMetadata(
        response,
        choice,
        logprobs: textLogprobs,
      ),
      warnings: warnings,
    );
  }

  Iterable<TextStreamEvent> decodeStreamChunk(
    Map<String, Object?> chunk,
    OpenAIChatCompletionsStreamState state,
  ) sync* {
    yield* _decodeOpenAIChatCompletionsStreamChunk(this, chunk, state);
  }

  Iterable<TextStreamEvent> _finalizeToolCalls(
    OpenAIChatCompletionsStreamState state,
    _ChatCompletionsStreamMetadataAdapter metadata,
  ) sync* {
    for (final entry in state.toolCalls.sortedEntries()) {
      final toolState = entry.value;
      final startEvent = maybeCreateOpenAIToolInputStartEvent(
        toolState: toolState,
        fallbackToolCallId: 'tool_${entry.key}',
        metadata: () => metadata.tool(entry.key),
      );
      if (startEvent != null) {
        yield startEvent;
      }

      final resolvedInput = resolveOpenAIStreamToolInput(
        toolState: toolState,
        fallbackToolCallId: 'tool_${entry.key}',
      );
      if (resolvedInput.decodeError != null) {
        yield createOpenAIToolInputErrorEvent(
          input: resolvedInput,
          metadata: () => metadata.tool(entry.key),
        );
        continue;
      }

      final endEvent = maybeCreateOpenAIToolInputEndEvent(
        toolState: toolState,
        fallbackToolCallId: 'tool_${entry.key}',
        metadata: () => metadata.tool(entry.key),
      );
      if (endEvent != null) {
        yield endEvent;
      }
      yield ToolCallEvent(
        toolCall: ToolCallContent(
          toolCallId: resolvedInput.toolCallId,
          toolName: resolvedInput.toolName,
          input: resolvedInput.decodedInput,
        ),
        providerMetadata: metadata.tool(entry.key),
      );
    }
    state.toolCalls.clear();
  }

  int _encodeChatTopLogProbs(OpenAILogProbs logprobs) {
    return logprobs.topLogProbs ?? 0;
  }

  List<Object?>? _decodeChatLogprobs(Object? value) {
    final logprobs = _asMap(value);
    return _jsonListOrNull(logprobs?['content']);
  }

  ProviderMetadata? _providerMetadata(Map<String, Object?> values) {
    final scopedValues = <String, Object?>{};
    for (final entry in values.entries) {
      if (entry.value != null) {
        scopedValues[entry.key] = entry.value;
      }
    }

    if (scopedValues.isEmpty) {
      return null;
    }

    return ProviderMetadata({
      providerNamespace: scopedValues,
    });
  }

  UsageStats? _decodeUsage(Map<String, Object?>? usage) {
    if (usage == null) {
      return null;
    }

    final inputTokens = _asInt(usage['prompt_tokens']);
    final outputTokens = _asInt(usage['completion_tokens']);
    final totalTokens = _asInt(usage['total_tokens']) ??
        ((inputTokens != null && outputTokens != null)
            ? inputTokens + outputTokens
            : null);
    final completionDetails = _asMap(usage['completion_tokens_details']);

    return UsageStats(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: totalTokens,
      reasoningTokens: _asInt(completionDetails?['reasoning_tokens']),
    );
  }

  FinishReason _mapFinishReason(String? rawReason) {
    return switch (rawReason) {
      null || 'stop' => FinishReason.stop,
      'length' => FinishReason.maxTokens,
      'tool_calls' => FinishReason.toolCalls,
      'content_filter' => FinishReason.contentFilter,
      'cancelled' => FinishReason.aborted,
      _ => FinishReason.other,
    };
  }

  String? _extractContentDelta(Map<String, Object?> delta) {
    return _asString(delta['content']);
  }

  String? _extractReasoningDelta(Map<String, Object?> delta) {
    return firstOpenAINonEmptyString([
      _asString(delta['reasoning_content']),
      _asString(delta['reasoning']),
      _asString(delta['thinking']),
    ]);
  }

  Map<String, Object?>? _firstChoice(Map<String, Object?> response) {
    final choices = _asList(response['choices']);
    if (choices.isEmpty) {
      return null;
    }

    return _asMap(choices.first);
  }

  String _encodeJsonString(Object? value) {
    if (value == null) {
      return '{}';
    }

    if (value is String) {
      return value;
    }

    return jsonEncode(value);
  }

  String _encodeToolOutput({
    required Object? output,
    required bool isError,
  }) {
    if (output == null) {
      return isError ? 'Tool execution failed' : 'null';
    }

    if (output is String) {
      return output;
    }

    return jsonEncode(output);
  }

  void _throwIfError(Map<String, Object?> response) {
    final error = _asMap(response['error']);
    if (error == null) {
      return;
    }

    final message = _asString(error['message']) ?? 'OpenAI response error';
    final type = _asString(error['type']);
    final code = error['code'];
    throw StateError(
      'OpenAI chat-completions error: $message'
      '${type == null ? '' : ' (type: $type)'}'
      '${code == null ? '' : ' (code: $code)'}',
    );
  }

  Map<String, Object?>? _asMap(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }

    if (value is Map) {
      return Map<String, Object?>.from(value);
    }

    return null;
  }

  List<Object?> _asList(Object? value) {
    if (value is List<Object?>) {
      return value;
    }

    if (value is List) {
      return List<Object?>.from(value);
    }

    return const [];
  }

  List<Object?>? _jsonListOrNull(Object? value) {
    if (value is List<Object?>) {
      return value;
    }

    if (value is List) {
      return List<Object?>.from(value);
    }

    return null;
  }

  String? _asString(Object? value) {
    return value is String ? value : null;
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return null;
  }

  DateTime? _decodeResponseTimestamp(Map<String, Object?> response) {
    final created = _asInt(response['created']);
    if (created == null) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(
      created * 1000,
      isUtc: true,
    );
  }

  static const String _textId = 'text_0';
  static const String _reasoningId = 'reasoning_0';
}
