import 'package:llm_dart_core/llm_dart_core.dart';

import 'openai_native_tools.dart';
import 'openai_response_format.dart';

final class OpenAIChatModelSettings implements ProviderModelOptions {
  final bool useResponsesApi;
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAIChatModelSettings({
    this.useResponsesApi = true,
    this.organization,
    this.project,
    this.headers = const {},
  });
}

final class OpenAIEmbeddingModelSettings implements ProviderModelOptions {
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAIEmbeddingModelSettings({
    this.organization,
    this.project,
    this.headers = const {},
  });
}

final class OpenAISpeechModelSettings implements ProviderModelOptions {
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAISpeechModelSettings({
    this.organization,
    this.project,
    this.headers = const {},
  });
}

final class OpenAITranscriptionModelSettings implements ProviderModelOptions {
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAITranscriptionModelSettings({
    this.organization,
    this.project,
    this.headers = const {},
  });
}

final class OpenAIEmbedOptions implements ProviderInvocationOptions {
  final String? encodingFormat;

  const OpenAIEmbedOptions({
    this.encodingFormat,
  });
}

final class OpenAISpeechOptions implements ProviderInvocationOptions {
  final String? outputFormat;
  final String? instructions;
  final double? speed;
  final String? language;

  const OpenAISpeechOptions({
    this.outputFormat,
    this.instructions,
    this.speed,
    this.language,
  });
}

enum OpenAITranscriptionResponseFormat {
  json('json'),
  text('text'),
  srt('srt'),
  verboseJson('verbose_json'),
  vtt('vtt');

  const OpenAITranscriptionResponseFormat(this.value);

  final String value;
}

enum OpenAITranscriptionTimestampGranularity {
  word('word'),
  segment('segment');

  const OpenAITranscriptionTimestampGranularity(this.value);

  final String value;
}

final class OpenAITranscriptionOptions implements ProviderInvocationOptions {
  final String? language;
  final String? prompt;
  final double? temperature;
  final OpenAITranscriptionResponseFormat? responseFormat;
  final List<OpenAITranscriptionTimestampGranularity> timestampGranularities;

  const OpenAITranscriptionOptions({
    this.language,
    this.prompt,
    this.temperature,
    this.responseFormat,
    this.timestampGranularities = const [],
  });
}

final class OpenAIGenerateTextOptions implements ProviderInvocationOptions {
  final String? previousResponseId;
  final bool? parallelToolCalls;
  final String? serviceTier;
  final String? verbosity;
  final List<OpenAIBuiltInTool>? builtInTools;
  final OpenAIJsonSchemaResponseFormat? responseFormat;

  const OpenAIGenerateTextOptions({
    this.previousResponseId,
    this.parallelToolCalls,
    this.serviceTier,
    this.verbosity,
    this.builtInTools,
    this.responseFormat,
  });
}
