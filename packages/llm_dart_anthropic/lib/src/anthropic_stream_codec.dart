import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_stream_content_codec.dart';
import 'anthropic_stream_result_codec.dart';
import 'anthropic_stream_state.dart';
import 'anthropic_stream_tool_codec.dart';
import 'anthropic_stream_util.dart';

export 'anthropic_stream_state.dart' show AnthropicMessagesStreamState;

final class AnthropicStreamCodec {
  final AnthropicStreamContentCodec contentCodec;
  final AnthropicStreamResultCodec resultCodec;
  final AnthropicStreamToolCodec toolCodec;

  const AnthropicStreamCodec()
      : toolCodec = const AnthropicStreamToolCodec(),
        resultCodec = const AnthropicStreamResultCodec(),
        contentCodec = const AnthropicStreamContentCodec(
          toolCodec: AnthropicStreamToolCodec(),
        );

  Iterable<LanguageModelStreamEvent> decodeChunk(
    Map<String, Object?> chunk,
    AnthropicMessagesStreamState state,
  ) sync* {
    final chunkType = anthropicStreamAsString(chunk['type']);
    if (chunkType == null || chunkType == 'ping') {
      return;
    }

    if (chunkType == 'message_start') {
      final messageStart = resultCodec.decodeMessageStart(chunk, state);
      if (messageStart == null) {
        return;
      }

      final metadataEvent = messageStart.metadataEvent;
      if (metadataEvent != null) {
        yield metadataEvent;
      }

      for (final part in messageStart.prepopulatedToolUseBlocks) {
        yield* toolCodec.emitPrepopulatedToolCall(part, state);
      }
      return;
    }

    if (chunkType == 'content_block_start') {
      yield* contentCodec.decodeContentBlockStart(chunk, state);
      return;
    }

    if (chunkType == 'content_block_delta') {
      yield* contentCodec.decodeContentBlockDelta(chunk, state);
      return;
    }

    if (chunkType == 'content_block_stop') {
      yield* contentCodec.decodeContentBlockStop(chunk, state);
      return;
    }

    if (chunkType == 'message_delta') {
      resultCodec.updateMessageDelta(chunk, state);
      return;
    }

    if (chunkType == 'message_stop') {
      yield resultCodec.decodeMessageStop(state);
      return;
    }

    if (chunkType == 'error') {
      yield ErrorEvent(
        ModelError.fromUnknown(
          chunk['error'] ?? chunk,
          kind: ModelErrorKind.provider,
        ),
      );
    }
  }
}
