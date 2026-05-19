import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_shared.dart';
import 'google_stream_state.dart';

Iterable<LanguageModelStreamEvent> closeGoogleStreamBlocks(
  GoogleGenerateContentStreamState state,
) sync* {
  if (state.currentTextBlockId != null) {
    yield TextEndEvent(id: state.currentTextBlockId!);
    state.currentTextBlockId = null;
  }

  if (state.currentReasoningBlockId != null) {
    yield ReasoningEndEvent(id: state.currentReasoningBlockId!);
    state.currentReasoningBlockId = null;
  }
}

Iterable<LanguageModelStreamEvent> decodeGoogleStreamTextPart(
  Map<String, Object?> part, {
  required Object? textValue,
  required ProviderMetadata? metadata,
  required GoogleGenerateContentStreamState state,
}) sync* {
  final text = asString(textValue) ?? '';
  if (part['thought'] == true) {
    if (state.currentTextBlockId != null) {
      yield TextEndEvent(id: state.currentTextBlockId!);
      state.currentTextBlockId = null;
    }

    final shouldStart = state.currentReasoningBlockId == null;
    state.currentReasoningBlockId ??= '${state.blockCounter++}';

    if (shouldStart) {
      yield ReasoningStartEvent(
        id: state.currentReasoningBlockId!,
        providerMetadata: metadata,
      );
    }

    if (text.isEmpty) {
      if (metadata != null) {
        yield ReasoningDeltaEvent(
          id: state.currentReasoningBlockId!,
          delta: '',
          providerMetadata: metadata,
        );
      }
    } else {
      yield ReasoningDeltaEvent(
        id: state.currentReasoningBlockId!,
        delta: text,
        providerMetadata: metadata,
      );
    }
    return;
  }

  if (state.currentReasoningBlockId != null) {
    yield ReasoningEndEvent(id: state.currentReasoningBlockId!);
    state.currentReasoningBlockId = null;
  }

  final shouldStart = state.currentTextBlockId == null;
  state.currentTextBlockId ??= '${state.blockCounter++}';

  if (shouldStart) {
    yield TextStartEvent(
      id: state.currentTextBlockId!,
      providerMetadata: metadata,
    );
  }

  if (text.isEmpty) {
    if (metadata != null) {
      yield TextDeltaEvent(
        id: state.currentTextBlockId!,
        delta: '',
        providerMetadata: metadata,
      );
    }
  } else {
    yield TextDeltaEvent(
      id: state.currentTextBlockId!,
      delta: text,
      providerMetadata: metadata,
    );
  }
}
