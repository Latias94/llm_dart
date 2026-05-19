import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_shared.dart';

CustomContentPart googleFunctionResponseReplayContentPart({
  required String kind,
  required Map<String, Object?> data,
  ProviderMetadata? replayMetadata,
  ProviderMetadata? providerMetadata,
}) {
  return CustomContentPart(
    kind: kind,
    data: data,
    providerMetadata: mergeGoogleFunctionResponseReplayMetadata(
      replayMetadata,
      providerMetadata,
    ),
  );
}

CustomPromptPart googleFunctionResponseReplayPromptPart({
  required String kind,
  required Map<String, Object?> data,
  ProviderMetadata? replayMetadata,
  ProviderMetadata? providerMetadata,
}) {
  return CustomPromptPart(
    kind: kind,
    data: data,
    providerOptions: ProviderReplayPromptPartOptions.fromMetadata(
      mergeGoogleFunctionResponseReplayMetadata(
        replayMetadata,
        providerMetadata,
      ),
    ),
  );
}

CustomEvent googleFunctionResponseReplayEvent({
  required String kind,
  required Map<String, Object?> data,
  ProviderMetadata? replayMetadata,
  ProviderMetadata? providerMetadata,
}) {
  return CustomEvent(
    kind: kind,
    data: data,
    providerMetadata: mergeGoogleFunctionResponseReplayMetadata(
      replayMetadata,
      providerMetadata,
    ),
  );
}

ProviderMetadata? mergeGoogleFunctionResponseReplayMetadata(
  ProviderMetadata? replayMetadata,
  ProviderMetadata? providerMetadata,
) {
  return mergeProviderMetadata(replayMetadata, providerMetadata);
}

T? tryParseGoogleFunctionResponseReplay<T>(T Function() parse) {
  try {
    return parse();
  } on FormatException {
    return null;
  } on UnsupportedError {
    return null;
  } on ArgumentError {
    return null;
  }
}
