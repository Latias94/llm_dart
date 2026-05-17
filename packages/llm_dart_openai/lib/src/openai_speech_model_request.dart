import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_non_text_model_support.dart';
import 'openai_options.dart';

OpenAISpeechModelSettings resolveOpenAISpeechModelSettings(
  ProviderModelOptions settings,
) {
  return resolveOpenAIModelSettings<OpenAISpeechModelSettings>(
    settings,
    parameterName: 'settings',
    expectedTypeName:
        'OpenAISpeechModelSettings for OpenAI-family speech models',
  );
}

OpenAISpeechOptions? resolveOpenAISpeechProviderOptions(
  CallOptions callOptions,
) {
  return resolveOpenAIProviderOptions<OpenAISpeechOptions>(
    callOptions,
    parameterName: 'request.callOptions.providerOptions',
    expectedTypeName: 'OpenAISpeechOptions for OpenAI-family speech models',
  );
}

void validateOpenAISpeechOptions(OpenAISpeechOptions? options) {
  if (options == null || options.speed == null) {
    return;
  }

  final speed = options.speed!;
  if (speed < 0.25 || speed > 4.0) {
    throw ArgumentError.value(
      speed,
      'providerOptions.speed',
      'OpenAI speech speed must be between 0.25 and 4.0.',
    );
  }
}

String resolveOpenAISpeechOutputFormat(
  String? outputFormat, {
  required List<ModelWarning> warnings,
}) {
  if (outputFormat == null || outputFormat.isEmpty) {
    return 'mp3';
  }

  if (_supportedOutputFormats.contains(outputFormat)) {
    return outputFormat;
  }

  warnings.add(
    ModelWarning(
      type: ModelWarningType.unsupported,
      field: 'providerOptions.outputFormat',
      message:
          'Unsupported OpenAI speech output format: $outputFormat. Using mp3 instead.',
    ),
  );
  return 'mp3';
}

void warnOpenAISpeechLanguageUnsupported(
  OpenAISpeechOptions? options,
  List<ModelWarning> warnings,
) {
  if (options?.language case final language?) {
    warnings.add(
      ModelWarning(
        type: ModelWarningType.unsupported,
        field: 'providerOptions.language',
        message:
            'OpenAI speech models do not support language selection. Language parameter "$language" was ignored.',
      ),
    );
  }
}

Map<String, Object?> buildOpenAISpeechRequestBody({
  required String modelId,
  required SpeechGenerationRequest request,
  required OpenAISpeechOptions? options,
  required String outputFormat,
}) {
  return {
    'model': modelId,
    'input': request.text,
    'voice': request.voice ?? 'alloy',
    'response_format': outputFormat,
    if (options?.instructions case final instructions?)
      'instructions': instructions,
    if (options?.speed case final speed?) 'speed': speed,
  };
}

const Set<String> _supportedOutputFormats = {
  'mp3',
  'opus',
  'aac',
  'flac',
  'wav',
  'pcm',
};
