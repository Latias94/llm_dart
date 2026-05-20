import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_grounding_projection.dart';
import 'google_shared.dart';
import 'google_stream_lifecycle_projection.dart';
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
    captureGoogleStreamChunkMetadata(chunk, state);

    final metadataEvent = maybeCreateGoogleStreamResponseMetadataEvent(state);
    if (metadataEvent != null) {
      yield metadataEvent;
    }

    final candidates = asList(chunk['candidates']);
    final candidate = candidates.isEmpty ? null : asMap(candidates.first);
    if (candidate == null) {
      return;
    }

    captureGoogleStreamCandidateMetadata(candidate, state);

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
      yield* emitGoogleStreamFinish(state);
    }
  }

  Iterable<LanguageModelStreamEvent> finish(
    GoogleGenerateContentStreamState state,
  ) sync* {
    if (state.finished) {
      return;
    }

    final metadataEvent = maybeCreateGoogleStreamResponseMetadataEvent(state);
    if (metadataEvent != null) {
      yield metadataEvent;
    }

    if (state.responseId != null ||
        state.modelVersion != null ||
        state.usageMetadata != null) {
      yield* emitGoogleStreamFinish(state);
    }
  }
}
