import 'package:llm_dart_provider/llm_dart_provider.dart';

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
}
