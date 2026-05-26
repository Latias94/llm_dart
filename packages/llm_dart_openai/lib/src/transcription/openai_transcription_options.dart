import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../provider/openai_provider_options_namespaces.dart';

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

final class OpenAITranscriptionOptions
    implements ProviderInvocationOptionsBagProjection {
  final List<String> include;
  final String? language;
  final String? prompt;
  final double? temperature;
  final OpenAITranscriptionResponseFormat? responseFormat;
  final List<OpenAITranscriptionTimestampGranularity> timestampGranularities;

  const OpenAITranscriptionOptions({
    this.include = const [],
    this.language,
    this.prompt,
    this.temperature,
    this.responseFormat,
    this.timestampGranularities = const [],
  });

  @override
  ProviderOptionsBag toProviderOptionsBag() {
    return ProviderOptionsBag.forProvider(openAIProviderOptionsNamespace, {
          'include': include.isEmpty ? null : include,
          'language': language,
          'prompt': prompt,
          'temperature': temperature,
          'response_format': responseFormat?.value,
          'timestamp_granularities': timestampGranularities.isEmpty
              ? null
              : timestampGranularities
                  .map((granularity) => granularity.value)
                  .toList(growable: false),
        }) ??
        ProviderOptionsBag.empty;
  }
}
