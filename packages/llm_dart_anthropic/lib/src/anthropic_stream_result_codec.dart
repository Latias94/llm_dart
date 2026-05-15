import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_stream_state.dart';
import 'anthropic_stream_util.dart';

final class AnthropicStreamMessageStart {
  final Map<String, Object?> message;
  final ResponseMetadataEvent? metadataEvent;
  final List<Map<String, Object?>> prepopulatedToolUseBlocks;

  const AnthropicStreamMessageStart({
    required this.message,
    required this.metadataEvent,
    required this.prepopulatedToolUseBlocks,
  });
}

final class AnthropicStreamResultCodec {
  const AnthropicStreamResultCodec();

  AnthropicStreamMessageStart? decodeMessageStart(
    Map<String, Object?> chunk,
    AnthropicMessagesStreamState state,
  ) {
    final message = anthropicStreamAsMap(chunk['message']);
    if (message == null) {
      return null;
    }

    state.responseId = anthropicStreamAsString(message['id']);
    state.responseModelId = anthropicStreamAsString(message['model']);
    state.rawFinishReason = anthropicStreamAsString(message['stop_reason']);
    state.rawUsage = anthropicStreamAsMap(message['usage']);
    state.container = decodeContainer(
      anthropicStreamAsMap(message['container']),
    );

    ResponseMetadataEvent? metadataEvent;
    if (!state.emittedResponseMetadata) {
      state.emittedResponseMetadata = true;
      metadataEvent = ResponseMetadataEvent(
        responseId: state.responseId,
        modelId: state.responseModelId,
      );
    }

    final prepopulatedToolUseBlocks = <Map<String, Object?>>[];
    for (final rawPart in anthropicStreamAsList(message['content'])) {
      final part = anthropicStreamAsMap(rawPart);
      if (part != null && anthropicStreamAsString(part['type']) == 'tool_use') {
        prepopulatedToolUseBlocks.add(part);
      }
    }

    return AnthropicStreamMessageStart(
      message: message,
      metadataEvent: metadataEvent,
      prepopulatedToolUseBlocks: prepopulatedToolUseBlocks,
    );
  }

  void updateMessageDelta(
    Map<String, Object?> chunk,
    AnthropicMessagesStreamState state,
  ) {
    final delta = anthropicStreamAsMap(chunk['delta']);
    final usage = anthropicStreamAsMap(chunk['usage']);
    state.rawFinishReason =
        anthropicStreamAsString(delta?['stop_reason']) ?? state.rawFinishReason;
    state.stopSequence =
        anthropicStreamAsString(delta?['stop_sequence']) ?? state.stopSequence;
    state.container =
        decodeContainer(anthropicStreamAsMap(delta?['container'])) ??
            state.container;
    state.contextManagement =
        anthropicStreamAsMap(chunk['context_management']) ??
            state.contextManagement;
    state.rawUsage =
        mergeAnthropicStreamObjects(state.rawUsage, usage) ?? state.rawUsage;
  }

  FinishEvent decodeMessageStop(AnthropicMessagesStreamState state) {
    return FinishEvent(
      finishReason: mapFinishReason(state.rawFinishReason),
      rawFinishReason: state.rawFinishReason,
      usage: decodeUsage(state.rawUsage),
      providerMetadata: anthropicStreamProviderMetadata({
        'usage': state.rawUsage,
        'stopSequence': state.stopSequence,
        'container': state.container,
        'contextManagement': state.contextManagement,
      }),
    );
  }

  FinishReason mapFinishReason(String? rawReason) {
    switch (rawReason) {
      case 'pause_turn':
      case 'end_turn':
      case 'stop_sequence':
        return FinishReason.stop;
      case 'tool_use':
        return FinishReason.toolCalls;
      case 'max_tokens':
      case 'model_context_window_exceeded':
        return FinishReason.maxTokens;
      case 'refusal':
        return FinishReason.contentFilter;
      default:
        return FinishReason.other;
    }
  }

  UsageStats? decodeUsage(Map<String, Object?>? usage) {
    if (usage == null) {
      return null;
    }

    final inputTokens = anthropicStreamAsInt(usage['input_tokens']);
    final outputTokens = anthropicStreamAsInt(usage['output_tokens']);
    return UsageStats(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: (inputTokens ?? 0) + (outputTokens ?? 0),
    );
  }

  Map<String, Object?>? decodeContainer(Map<String, Object?>? container) {
    if (container == null) {
      return null;
    }

    return {
      if (anthropicStreamAsString(container['id']) != null)
        'id': anthropicStreamAsString(container['id']),
      if (anthropicStreamAsString(container['expires_at']) != null)
        'expiresAt': anthropicStreamAsString(container['expires_at']),
      if (container['skills'] != null)
        'skills': normalizeJsonValue(container['skills']),
    };
  }
}
