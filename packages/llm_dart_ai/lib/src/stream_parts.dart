import 'package:llm_dart_core/llm_dart_core.dart';

import 'call_options_dispatch.dart';
import 'ensure_stream_start.dart';
import 'ensure_block_ids.dart';
import 'ensure_block_ends.dart';
import 'ensure_provider_metadata.dart';
import 'ensure_response_metadata.dart';
import 'ensure_single_finish.dart';
import 'prompt_input.dart';

export 'package:llm_dart_core/core/stream_parts.dart';

/// Stream chat as provider-agnostic stream parts (Vercel-style).
///
/// This is a forward-compatible surface that adds block boundaries and allows
/// provider-native tools/metadata to be observed without forcing a "perfect"
/// abstraction.
Stream<LLMStreamPart> streamChatParts({
  required ChatCapability model,
  String? system,
  String? prompt,
  List<ChatMessage>? messages,
  Prompt? promptIr,
  List<Tool>? tools,
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async* {
  yield* ensureStreamStartPart(
    ensureBlockEndsPart(
      ensureBlockIdsPart(
        ensureSingleFinishPart(
          ensureProviderMetadataPart(
            ensureResponseMetadataPart(
              _streamChatPartsInternal(
                model: model,
                system: system,
                prompt: prompt,
                messages: messages,
                promptIr: promptIr,
                tools: tools,
                callOptions: callOptions,
                cancelToken: cancelToken,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Stream<LLMStreamPart> _streamChatPartsInternal({
  required ChatCapability model,
  String? system,
  String? prompt,
  List<ChatMessage>? messages,
  Prompt? promptIr,
  List<Tool>? tools,
  required LLMCallOptions callOptions,
  CancelToken? cancelToken,
}) async* {
  final input = standardizePromptInput(
    system: system,
    prompt: prompt,
    messages: messages,
    promptIr: promptIr,
  );

  final upstream = chatStreamPartsBestEffort(
    model: model,
    input: input,
    tools: tools,
    callOptions: callOptions,
    cancelToken: cancelToken,
  );

  await for (final part in upstream) {
    switch (part) {
      case LLMFinishPart(
          response: final response,
          usage: final usage,
          finishReason: final finishReason,
        ):
        yield LLMFinishPart(
          response,
          usage: usage ?? response.usage,
          finishReason: finishReason ??
              (response is ChatResponseWithFinishReason
                  ? response.finishReason
                  : null),
        );
      default:
        yield part;
    }
  }
}
