import 'package:llm_dart_core/llm_dart_core.dart';

import 'openai_native_tools.dart';
import 'openai_response_format.dart';

const Object _unset = Object();

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

final class OpenAIImageModelSettings implements ProviderModelOptions {
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAIImageModelSettings({
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

enum OpenAIImageStyle {
  vivid('vivid'),
  natural('natural');

  const OpenAIImageStyle(this.value);

  final String value;
}

enum OpenAIImageQuality {
  standard('standard'),
  hd('hd'),
  auto('auto'),
  low('low'),
  medium('medium'),
  high('high');

  const OpenAIImageQuality(this.value);

  final String value;
}

enum OpenAIImageBackground {
  auto('auto'),
  opaque('opaque'),
  transparent('transparent');

  const OpenAIImageBackground(this.value);

  final String value;
}

enum OpenAIImageOutputFormat {
  png('png'),
  jpeg('jpeg'),
  webp('webp');

  const OpenAIImageOutputFormat(this.value);

  final String value;
}

enum OpenAIImageResponseFormat {
  url('url'),
  base64Json('b64_json');

  const OpenAIImageResponseFormat(this.value);

  final String value;
}

final class OpenAIImageOptions implements ProviderInvocationOptions {
  final OpenAIImageStyle? style;
  final OpenAIImageQuality? quality;
  final OpenAIImageBackground? background;
  final OpenAIImageOutputFormat? outputFormat;
  final OpenAIImageResponseFormat? responseFormat;
  final String? user;

  const OpenAIImageOptions({
    this.style,
    this.quality,
    this.background,
    this.outputFormat,
    this.responseFormat,
    this.user,
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

enum OpenAIResponseTruncation {
  auto('auto'),
  disabled('disabled');

  const OpenAIResponseTruncation(this.value);

  final String value;
}

final class OpenAIGenerateTextOptions implements ProviderInvocationOptions {
  final String? previousResponseId;
  final bool? parallelToolCalls;
  final String? serviceTier;
  final String? verbosity;
  final String? instructions;
  final int? maxToolCalls;
  final Map<String, Object?>? metadata;
  final OpenAIResponseTruncation? truncation;
  final String? user;
  final List<OpenAIBuiltInTool>? builtInTools;
  final OpenAIJsonSchemaResponseFormat? responseFormat;

  const OpenAIGenerateTextOptions({
    this.previousResponseId,
    this.parallelToolCalls,
    this.serviceTier,
    this.verbosity,
    this.instructions,
    this.maxToolCalls,
    this.metadata,
    this.truncation,
    this.user,
    this.builtInTools,
    this.responseFormat,
  });

  OpenAIGenerateTextOptions copyWith({
    Object? previousResponseId = _unset,
    Object? parallelToolCalls = _unset,
    Object? serviceTier = _unset,
    Object? verbosity = _unset,
    Object? instructions = _unset,
    Object? maxToolCalls = _unset,
    Object? metadata = _unset,
    Object? truncation = _unset,
    Object? user = _unset,
    Object? builtInTools = _unset,
    Object? responseFormat = _unset,
  }) {
    return OpenAIGenerateTextOptions(
      previousResponseId: identical(previousResponseId, _unset)
          ? this.previousResponseId
          : previousResponseId as String?,
      parallelToolCalls: identical(parallelToolCalls, _unset)
          ? this.parallelToolCalls
          : parallelToolCalls as bool?,
      serviceTier: identical(serviceTier, _unset)
          ? this.serviceTier
          : serviceTier as String?,
      verbosity:
          identical(verbosity, _unset) ? this.verbosity : verbosity as String?,
      instructions: identical(instructions, _unset)
          ? this.instructions
          : instructions as String?,
      maxToolCalls: identical(maxToolCalls, _unset)
          ? this.maxToolCalls
          : maxToolCalls as int?,
      metadata: identical(metadata, _unset)
          ? this.metadata
          : metadata as Map<String, Object?>?,
      truncation: identical(truncation, _unset)
          ? this.truncation
          : truncation as OpenAIResponseTruncation?,
      user: identical(user, _unset) ? this.user : user as String?,
      builtInTools: identical(builtInTools, _unset)
          ? this.builtInTools
          : builtInTools as List<OpenAIBuiltInTool>?,
      responseFormat: identical(responseFormat, _unset)
          ? this.responseFormat
          : responseFormat as OpenAIJsonSchemaResponseFormat?,
    );
  }
}
