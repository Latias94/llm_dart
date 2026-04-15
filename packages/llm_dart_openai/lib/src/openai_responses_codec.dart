import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'openai_model_capabilities.dart';
import 'openai_native_tools.dart';
import 'openai_options.dart';
import 'openai_response_format.dart';
import 'openai_responses_support.dart';
import 'openai_streaming_support.dart';

part 'openai_responses_request_encoder.dart';
part 'openai_responses_stream_decoder.dart';

final class OpenAIResponsesRequest {
  final Map<String, Object?> body;
  final List<ModelWarning> warnings;

  OpenAIResponsesRequest({
    required Map<String, Object?> body,
    List<ModelWarning> warnings = const [],
  })  : body = Map.unmodifiable(body),
        warnings = List.unmodifiable(warnings);
}

final class OpenAIResponsesStreamState extends OpenAIStreamState {
  final Set<String> emittedAnnotationKeys = {};
}

final class OpenAIResponsesCodec {
  const OpenAIResponsesCodec();

  OpenAIResponsesRequest encodeRequest({
    required String modelId,
    required List<PromptMessage> prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required GenerateTextOptions options,
    required OpenAIGenerateTextOptions providerOptions,
    required bool stream,
  }) {
    return _OpenAIResponsesCodecRequestEncoder(this)._encodeRequest(
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

    final content = <ContentPart>[];
    final collectedLogprobs = <Object?>[];
    var hasToolCalls = false;

    for (final item in _outputItems(response)) {
      final type = _asString(item['type']);
      if (type == 'message') {
        collectOpenAIResponsesMessageOutputLogprobs(
          item,
          into: collectedLogprobs,
        );
        content.addAll(decodeOpenAIResponsesMessageOutput(item));
        continue;
      }

      if (type == 'reasoning') {
        content.addAll(decodeOpenAIResponsesReasoningOutput(item));
        continue;
      }

      if (type == 'function_call') {
        hasToolCalls = true;
        final toolCall = decodeOpenAIResponsesFunctionCallOutput(item);
        if (toolCall != null) {
          content.add(toolCall);
        }
        continue;
      }

      if (type == 'mcp_approval_request') {
        hasToolCalls = true;
        content.addAll(decodeOpenAIResponsesMcpApprovalRequestOutput(item));
        continue;
      }

      if (type == 'mcp_call') {
        hasToolCalls = true;
        content.addAll(decodeOpenAIResponsesMcpCallOutput(item));
        continue;
      }

      final customPart = decodeOpenAIResponsesCustomOutput(item);
      if (customPart != null) {
        content.add(customPart);
      }
    }

    return GenerateTextResult(
      content: content,
      finishReason: _mapFinishReason(
        rawReason: _responseFinishReason(response),
        hasToolCalls: hasToolCalls,
        status: _asString(response['status']),
      ),
      rawFinishReason: _responseFinishReason(response),
      responseId: _asString(response['id']),
      responseTimestamp: _decodeResponseTimestamp(response),
      responseModelId: _asString(response['model']),
      usage: _decodeUsage(_asMap(response['usage'])),
      providerMetadata: openAIResponsesResponseMetadata(
        response,
        logprobs: collectedLogprobs,
      ),
      warnings: warnings,
    );
  }

  Iterable<TextStreamEvent> decodeStreamChunk(
    Map<String, Object?> chunk,
    OpenAIResponsesStreamState state,
  ) sync* {
    final chunkType = _asString(chunk['type']);
    if (chunkType == null) {
      return;
    }
    final metadata = _ResponsesStreamMetadataAdapter(
      state: state,
      chunk: chunk,
      customMetadataBuilder: _providerMetadata,
    );

    switch (chunkType) {
      case 'response.created':
        yield* _handleResponseCreatedChunk(chunk, state, metadata);
        return;
      case 'response.output_item.added':
        yield* _handleOutputItemAddedChunk(chunk, state, metadata);
        return;
      case 'response.output_text.delta':
        yield* _handleOutputTextDeltaChunk(chunk, state, metadata);
        return;
      case 'response.output_text.done':
        yield* _handleOutputTextDoneChunk(chunk, state, metadata);
        return;
      case 'response.reasoning_summary_part.added':
        yield* _handleReasoningSummaryPartAddedChunk(
          chunk,
          state,
          metadata,
        );
        return;
      case 'response.reasoning_summary_text.delta':
        yield* _handleReasoningSummaryTextDeltaChunk(
          chunk,
          state,
          metadata,
        );
        return;
      case 'response.reasoning_summary_part.done':
        yield* _handleReasoningSummaryPartDoneChunk(
          chunk,
          state,
          metadata,
        );
        return;
      case 'response.function_call_arguments.delta':
        yield* _handleFunctionCallArgumentsDeltaChunk(
          chunk,
          state,
          metadata,
        );
        return;
      case 'response.output_text.annotation.added':
        yield* _handleOutputTextAnnotationAddedChunk(chunk, state);
        return;
      case 'response.content_part.done':
        yield* _handleContentPartDoneChunk(chunk, state, metadata);
        return;
      case 'response.image_generation_call.partial_image':
        yield* _handlePartialImageChunk(chunk, state, metadata);
        return;
      case 'response.output_item.done':
        yield* _handleOutputItemDoneChunk(chunk, state, metadata);
        return;
      case 'response.completed':
      case 'response.incomplete':
      case 'response.failed':
        yield* _handleTerminalResponseChunk(
          chunkType,
          chunk,
          state,
          metadata,
        );
        return;
      case 'error':
        yield* _handleErrorChunk(chunk);
        return;
    }
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
      'OpenAI response error: $message'
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
    final createdAt = _asInt(response['created_at']);
    if (createdAt == null) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(
      createdAt * 1000,
      isUtc: true,
    );
  }

  String _normalizeImageMediaTypeForDataUrl(String mediaType) {
    if (mediaType == 'image/*') {
      return 'image/jpeg';
    }

    return mediaType;
  }
}
