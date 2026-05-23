import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../provider/openai_model_settings.dart';
import '../common/openai_non_text_model_support.dart';
import '../provider/openai_family_invocation_options.dart';
import 'openai_speech_options.dart';

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
  return resolveOpenAISpeechInvocationOptions(callOptions.providerOptions);
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
      feature: request.outputFormat != null
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
      feature:
          request.language != null ? 'language' : 'providerOptions.language',
      message:
          'OpenAI speech models do not support language selection. Language parameter "$language" was ignored.',
    ),
  );
}

const Set<String> _supportedOutputFormats = {
  'mp3',
  'opus',
  'aac',
  'flac',
  'wav',
  'pcm',
};
