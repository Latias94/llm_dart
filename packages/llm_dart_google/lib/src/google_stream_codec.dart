import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_content_projection_support.dart';
import 'google_provider_metadata_support.dart';
import 'google_shared.dart';
import 'google_stream_part_codec.dart';
import 'google_stream_state.dart';

export 'google_stream_state.dart' show GoogleGenerateContentStreamState;

final class GoogleGenerateContentStreamCodec {
  static const GoogleStreamPartCodec _partCodec = GoogleStreamPartCodec();

  const GoogleGenerateContentStreamCodec();

  Iterable<LanguageModelStreamEvent> decodeChunk(
    Map<String, Object?> chunk,
    GoogleGenerateContentStreamState state,
  ) sync* {
    state.responseId = asString(chunk['responseId']) ?? state.responseId;
    state.modelVersion = asString(chunk['modelVersion']) ?? state.modelVersion;
    state.promptFeedback =
        asMap(chunk['promptFeedback']) ?? state.promptFeedback;
    state.usageMetadata = asMap(chunk['usageMetadata']) ?? state.usageMetadata;

    if (!state.emittedResponseMetadata &&
        (state.responseId != null || state.modelVersion != null)) {
      state.emittedResponseMetadata = true;
      yield ResponseMetadataEvent(
        responseId: state.responseId,
        modelId: state.modelVersion,
      );
    }

    final candidates = asList(chunk['candidates']);
    final candidate = candidates.isEmpty ? null : asMap(candidates.first);
    if (candidate == null) {
      return;
    }

    state.groundingMetadata =
        asMap(candidate['groundingMetadata']) ?? state.groundingMetadata;
    state.urlContextMetadata =
        asMap(candidate['urlContextMetadata']) ?? state.urlContextMetadata;
    final safetyRatings = asList(candidate['safetyRatings']);
    if (safetyRatings.isNotEmpty) {
      state.safetyRatings = safetyRatings;
    }
    state.rawFinishReason =
        asString(candidate['finishReason']) ?? state.rawFinishReason;
    state.finishMessage =
        asString(candidate['finishMessage']) ?? state.finishMessage;

    for (final event in emitGoogleGroundingSourceEvents(
      asMap(candidate['groundingMetadata']),
      emittedSourceKeys: state.emittedSourceKeys,
    )) {
      yield event;
    }

    final content = asMap(candidate['content']);
    final parts = asList(content?['parts']);
    for (final rawPart in parts) {
      final part = asMap(rawPart);
      if (part == null) {
        continue;
      }

      yield* _partCodec.decodePart(part, state);
    }

    if (asString(candidate['finishReason']) != null) {
      yield* _emitFinish(state);
    }
  }

  Iterable<LanguageModelStreamEvent> finish(
    GoogleGenerateContentStreamState state,
  ) sync* {
    if (state.finished) {
      return;
    }

    if (!state.emittedResponseMetadata &&
        (state.responseId != null || state.modelVersion != null)) {
      state.emittedResponseMetadata = true;
      yield ResponseMetadataEvent(
        responseId: state.responseId,
        modelId: state.modelVersion,
      );
    }

    if (state.responseId != null ||
        state.modelVersion != null ||
        state.usageMetadata != null) {
      yield* _emitFinish(state);
    }
  }

  Iterable<LanguageModelStreamEvent> _emitFinish(
    GoogleGenerateContentStreamState state,
  ) sync* {
    if (state.finished) {
      return;
    }

    yield* _partCodec.closeOpenBlocks(state);
    state.finished = true;
    yield FinishEvent(
      finishReason: mapGoogleFinishReason(
        state.rawFinishReason,
        hasClientToolCalls: state.hasClientToolCalls,
      ),
      rawFinishReason: state.rawFinishReason,
      usage: decodeGoogleUsage(state.usageMetadata),
      providerMetadata: buildGoogleGenerationMetadata(
        promptFeedback: state.promptFeedback,
        groundingMetadata: state.groundingMetadata,
        urlContextMetadata: state.urlContextMetadata,
        safetyRatings: state.safetyRatings,
        usageMetadata: state.usageMetadata,
        finishMessage: state.finishMessage,
      ),
    );
  }
}
