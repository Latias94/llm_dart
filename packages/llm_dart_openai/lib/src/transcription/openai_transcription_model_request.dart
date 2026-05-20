import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../provider/openai_model_settings.dart';
import '../common/openai_non_text_model_support.dart';
import '../provider/openai_provider_options_bag.dart';
import 'openai_transcription_options.dart';

OpenAITranscriptionModelSettings resolveOpenAITranscriptionModelSettings(
  ProviderModelOptions settings,
) {
  return resolveOpenAIModelSettings<OpenAITranscriptionModelSettings>(
    settings,
    parameterName: 'settings',
    expectedTypeName:
        'OpenAITranscriptionModelSettings for OpenAI-family transcription models',
  );
}

OpenAITranscriptionOptions? resolveOpenAITranscriptionProviderOptions(
  CallOptions callOptions,
) {
  return resolveOpenAITranscriptionOptionsFromInvocation(
    callOptions.providerOptions,
  );
}

void validateOpenAITranscriptionOptions(
  OpenAITranscriptionOptions? options,
) {
  if (options == null || options.temperature == null) {
    return;
  }

  final temperature = options.temperature!;
  if (temperature < 0 || temperature > 1) {
    throw ArgumentError.value(
      temperature,
      'providerOptions.temperature',
      'OpenAI transcription temperature must be between 0 and 1.',
    );
  }
}

OpenAITranscriptionResponseFormat resolveOpenAITranscriptionResponseFormat({
  required String modelId,
  required OpenAITranscriptionOptions? options,
}) {
  if (options?.responseFormat case final responseFormat?) {
    return responseFormat;
  }

  if (options == null || options.timestampGranularities.isEmpty) {
    return OpenAITranscriptionResponseFormat.json;
  }

  if (usesOpenAIJsonTimestampTranscriptionFormat(modelId)) {
    return OpenAITranscriptionResponseFormat.json;
  }

  return OpenAITranscriptionResponseFormat.verboseJson;
}

void validateOpenAITranscriptionTimestampResponseFormat({
  required String modelId,
  required OpenAITranscriptionResponseFormat responseFormat,
  required OpenAITranscriptionOptions? options,
}) {
  if (options == null || options.timestampGranularities.isEmpty) {
    return;
  }

  if (responseFormat == OpenAITranscriptionResponseFormat.verboseJson) {
    return;
  }

  if (usesOpenAIJsonTimestampTranscriptionFormat(modelId) &&
      responseFormat == OpenAITranscriptionResponseFormat.json) {
    return;
  }

  final expected = usesOpenAIJsonTimestampTranscriptionFormat(modelId)
      ? 'json or verboseJson'
      : 'verboseJson';
  throw ArgumentError(
    'OpenAITranscriptionOptions.timestampGranularities require responseFormat=$expected for $modelId.',
  );
}

bool usesOpenAIJsonTimestampTranscriptionFormat(String modelId) {
  return modelId == 'gpt-4o-transcribe' || modelId == 'gpt-4o-mini-transcribe';
}
