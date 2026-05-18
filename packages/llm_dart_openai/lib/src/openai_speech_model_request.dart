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

void validateOpenAISpeechRequest(
  SpeechGenerationRequest request,
  OpenAISpeechOptions? options,
) {
  validateOpenAISpeechOptions(options);

  final speed = request.speed;
  if (speed == null) {
    return;
  }

  if (speed < 0.25 || speed > 4.0) {
    throw ArgumentError.value(
      speed,
      'request.speed',
      'OpenAI speech speed must be between 0.25 and 4.0.',
    );
  }
}

String resolveOpenAISpeechOutputFormat(
  SpeechGenerationRequest request,
  OpenAISpeechOptions? options, {
  required List<ModelWarning> warnings,
}) {
  final outputFormat = request.outputFormat ?? options?.outputFormat;
  if (outputFormat == null || outputFormat.isEmpty) {
    return 'mp3';
  }

  if (_supportedOutputFormats.contains(outputFormat)) {
    return outputFormat;
  }

  warnings.add(
    ModelWarning(
      type: ModelWarningType.unsupported,
      field: request.outputFormat != null
          ? 'outputFormat'
          : 'providerOptions.outputFormat',
      message:
          'Unsupported OpenAI speech output format: $outputFormat. Using mp3 instead.',
    ),
  );
  return 'mp3';
}

void warnOpenAISpeechLanguageUnsupported(
  SpeechGenerationRequest request,
  OpenAISpeechOptions? options,
  List<ModelWarning> warnings,
) {
  final language = request.language ?? options?.language;
  if (language == null) {
    return;
  }

  warnings.add(
    ModelWarning(
      type: ModelWarningType.unsupported,
      field: request.language != null ? 'language' : 'providerOptions.language',
      message:
          'OpenAI speech models do not support language selection. Language parameter "$language" was ignored.',
    ),
  );
}

Map<String, Object?> buildOpenAISpeechRequestBody({
  required String modelId,
  required SpeechGenerationRequest request,
  required OpenAISpeechOptions? options,
  required String outputFormat,
}) {
  final instructions = request.instructions ?? options?.instructions;
  final speed = request.speed ?? options?.speed;

  return {
    'model': modelId,
    'input': request.text,
    'voice': request.voice ?? 'alloy',
    'response_format': outputFormat,
    if (instructions != null) 'instructions': instructions,
    if (speed != null) 'speed': speed,
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
