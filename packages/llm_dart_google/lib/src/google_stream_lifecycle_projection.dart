import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_provider_metadata_support.dart';
import 'google_shared.dart';
import 'google_stream_block_projection.dart';
import 'google_stream_state.dart';

void captureGoogleStreamChunkMetadata(
  Map<String, Object?> chunk,
  GoogleGenerateContentStreamState state,
) {
  state.responseId = asString(chunk['responseId']) ?? state.responseId;
  state.modelVersion = asString(chunk['modelVersion']) ?? state.modelVersion;
  state.promptFeedback = asMap(chunk['promptFeedback']) ?? state.promptFeedback;
  state.usageMetadata = asMap(chunk['usageMetadata']) ?? state.usageMetadata;
}

void captureGoogleStreamCandidateMetadata(
  Map<String, Object?> candidate,
  GoogleGenerateContentStreamState state,
) {
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
}

LanguageModelStreamEvent? maybeCreateGoogleStreamResponseMetadataEvent(
  GoogleGenerateContentStreamState state,
) {
  if (state.emittedResponseMetadata ||
      (state.responseId == null && state.modelVersion == null)) {
    return null;
  }

  state.emittedResponseMetadata = true;
  return ResponseMetadataEvent(
    responseMetadata: ModelResponseMetadata(
      id: state.responseId,
      modelId: state.modelVersion,
    ),
  );
}

Iterable<LanguageModelStreamEvent> emitGoogleStreamFinish(
  GoogleGenerateContentStreamState state,
) sync* {
  if (state.finished) {
    return;
  }

  yield* closeGoogleStreamBlocks(state);
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
