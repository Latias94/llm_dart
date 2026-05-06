import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_chat_completions_support.dart';
import 'openai_model_capabilities.dart';
import 'openai_options.dart';
import 'openai_response_format.dart';
import 'openai_streaming_support.dart';
import 'resolved_openai_options.dart';

part 'openai_chat_completions_request_encoder.dart';
part 'openai_chat_completions_prompt_encoder.dart';
part 'openai_chat_completions_request_support.dart';
part 'openai_chat_completions_response_decoder.dart';
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
  }) =>
      _decodeGenerateResponse(response, warnings: warnings);

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

  String _encodeJsonString(Object? value) {
    if (value == null) {
      return '{}';
    }

    if (value is String) {
      return value;
    }

    return jsonEncode(value);
  }

  String _encodeToolOutput(ToolOutput output) {
    if (output is ExecutionDeniedToolOutput) {
      return output.reason ?? 'Tool execution denied';
    }

    if (output is ContentToolOutput) {
      throw UnsupportedError(
        'OpenAI-family chat-completions tool result replay does not support ContentToolOutput yet.',
      );
    }

    final value = output.value;
    if (value == null) {
      return output.isError ? 'Tool execution failed' : 'null';
    }

    if (value is String) {
      return value;
    }

    return jsonEncode(value);
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
