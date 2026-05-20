import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_streaming_state.dart';

void captureOpenAIResponseMetadata({
  required OpenAIStreamState state,
  String? responseId,
  DateTime? responseTimestamp,
  String? responseModelId,
  String? serviceTier,
  String? rawFinishReason,
  UsageStats? usage,
  bool? hasToolCalls,
}) {
  if (responseId != null) {
    state.responseId = responseId;
  }
  if (responseTimestamp != null) {
    state.responseTimestamp = responseTimestamp;
  }
  if (responseModelId != null) {
    state.responseModelId = responseModelId;
  }
  if (serviceTier != null) {
    state.serviceTier = serviceTier;
  }
  if (rawFinishReason != null) {
    state.rawFinishReason = rawFinishReason;
  }
  if (usage != null) {
    state.usage = usage;
  }
  if (hasToolCalls == true) {
    state.hasToolCalls = true;
  }
}

ResponseMetadataEvent? maybeCreateOpenAIResponseMetadataEvent({
  required OpenAIStreamState state,
  required ProviderMetadata? Function() metadata,
}) {
  if (state.hasResponseMetadata) {
    return null;
  }

  if (state.responseId == null &&
      state.responseModelId == null &&
      state.responseTimestamp == null) {
    return null;
  }

  state.hasResponseMetadata = true;
  return ResponseMetadataEvent(
    responseMetadata: ModelResponseMetadata(
      id: state.responseId,
      timestamp: state.responseTimestamp,
      modelId: state.responseModelId,
    ),
    providerMetadata: metadata(),
  );
}
