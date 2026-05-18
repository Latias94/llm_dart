import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_metadata_support.dart';
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
    state.container = decodeAnthropicContainerMetadata(
      anthropicStreamAsMap(message['container']),
    );

    ResponseMetadataEvent? metadataEvent;
    if (!state.emittedResponseMetadata) {
      state.emittedResponseMetadata = true;
      metadataEvent = ResponseMetadataEvent(
        responseMetadata: ModelResponseMetadata(
          id: state.responseId,
          modelId: state.responseModelId,
        ),
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
    state.container = decodeAnthropicContainerMetadata(
          anthropicStreamAsMap(delta?['container']),
        ) ??
        state.container;
    state.contextManagement =
        anthropicStreamAsMap(chunk['context_management']) ??
            state.contextManagement;
    state.rawUsage =
        mergeAnthropicStreamObjects(state.rawUsage, usage) ?? state.rawUsage;
  }

  FinishEvent decodeMessageStop(AnthropicMessagesStreamState state) {
    return FinishEvent(
      finishReason: mapAnthropicStopReason(state.rawFinishReason),
      rawFinishReason: state.rawFinishReason,
      usage: decodeAnthropicUsage(state.rawUsage),
      providerMetadata: anthropicStreamProviderMetadata({
        'usage': state.rawUsage,
        'stopSequence': state.stopSequence,
        'container': state.container,
        'contextManagement': state.contextManagement,
      }),
    );
  }
}
