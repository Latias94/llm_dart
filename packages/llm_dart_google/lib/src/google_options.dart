import 'package:llm_dart_core/llm_dart_core.dart';

import 'google_response_format.dart';
import 'google_tools.dart';

enum GoogleHarmCategory {
  unspecified('HARM_CATEGORY_UNSPECIFIED'),
  hateSpeech('HARM_CATEGORY_HATE_SPEECH'),
  dangerousContent('HARM_CATEGORY_DANGEROUS_CONTENT'),
  harassment('HARM_CATEGORY_HARASSMENT'),
  sexuallyExplicit('HARM_CATEGORY_SEXUALLY_EXPLICIT'),
  civicIntegrity('HARM_CATEGORY_CIVIC_INTEGRITY');

  const GoogleHarmCategory(this.value);

  final String value;
}

enum GoogleHarmBlockThreshold {
  unspecified('HARM_BLOCK_THRESHOLD_UNSPECIFIED'),
  blockLowAndAbove('BLOCK_LOW_AND_ABOVE'),
  blockMediumAndAbove('BLOCK_MEDIUM_AND_ABOVE'),
  blockOnlyHigh('BLOCK_ONLY_HIGH'),
  blockNone('BLOCK_NONE'),
  off('OFF');

  const GoogleHarmBlockThreshold(this.value);

  final String value;
}

enum GoogleThinkingLevel {
  minimal('minimal'),
  low('low'),
  medium('medium'),
  high('high');

  const GoogleThinkingLevel(this.value);

  final String value;
}

enum GoogleResponseModality {
  text('TEXT'),
  image('IMAGE');

  const GoogleResponseModality(this.value);

  final String value;
}

final class GoogleSafetySetting {
  final GoogleHarmCategory category;
  final GoogleHarmBlockThreshold threshold;

  const GoogleSafetySetting({
    required this.category,
    required this.threshold,
  });

  Map<String, Object?> toJson() {
    return {
      'category': category.value,
      'threshold': threshold.value,
    };
  }
}

final class GoogleChatModelSettings implements ProviderModelOptions {
  final Map<String, String> headers;
  final List<GoogleSafetySetting> safetySettings;
  final List<GoogleNativeTool> tools;
  final bool includeServerSideToolInvocations;

  const GoogleChatModelSettings({
    this.headers = const {},
    this.safetySettings = const [],
    this.tools = const [],
    this.includeServerSideToolInvocations = false,
  });
}

final class GoogleEmbeddingModelSettings implements ProviderModelOptions {
  final Map<String, String> headers;

  const GoogleEmbeddingModelSettings({
    this.headers = const {},
  });
}

final class GoogleImageModelSettings implements ProviderModelOptions {
  final Map<String, String> headers;
  final int? maxImagesPerCall;
  final List<GoogleSafetySetting> safetySettings;

  const GoogleImageModelSettings({
    this.headers = const {},
    this.maxImagesPerCall,
    this.safetySettings = const [],
  });
}

final class GoogleSpeechModelSettings implements ProviderModelOptions {
  final Map<String, String> headers;
  final String defaultVoice;

  const GoogleSpeechModelSettings({
    this.headers = const {},
    this.defaultVoice = 'Kore',
  });
}

final class GoogleEmbedOptions implements ProviderInvocationOptions {
  final String? taskType;
  final String? title;

  const GoogleEmbedOptions({
    this.taskType,
    this.title,
  });
}

enum GoogleImageAspectRatio {
  square1x1('1:1'),
  portrait3x4('3:4'),
  landscape4x3('4:3'),
  portrait9x16('9:16'),
  landscape16x9('16:9');

  const GoogleImageAspectRatio(this.value);

  final String value;
}

enum GooglePersonGeneration {
  dontAllow('dont_allow'),
  allowAdult('allow_adult'),
  allowAll('allow_all');

  const GooglePersonGeneration(this.value);

  final String value;
}

final class GoogleImageOptions implements ProviderInvocationOptions {
  final GoogleImageAspectRatio? aspectRatio;
  final GooglePersonGeneration? personGeneration;
  final List<GoogleSafetySetting>? safetySettings;

  const GoogleImageOptions({
    this.aspectRatio,
    this.personGeneration,
    this.safetySettings,
  });
}

final class GoogleSpeechSpeakerVoice {
  final String speaker;
  final String voice;

  const GoogleSpeechSpeakerVoice({
    required this.speaker,
    required this.voice,
  });
}

final class GoogleSpeechOptions implements ProviderInvocationOptions {
  final List<GoogleSpeechSpeakerVoice> speakers;
  final double? temperature;
  final double? topP;
  final int? topK;
  final int? maxOutputTokens;
  final List<String> stopSequences;

  const GoogleSpeechOptions({
    this.speakers = const [],
    this.temperature,
    this.topP,
    this.topK,
    this.maxOutputTokens,
    this.stopSequences = const [],
  });
}

final class GoogleGenerateTextOptions implements ProviderInvocationOptions {
  final int? candidateCount;
  final int? thinkingBudgetTokens;
  final GoogleThinkingLevel? thinkingLevel;
  final bool? includeThoughts;
  final List<GoogleResponseModality>? responseModalities;
  final String? cachedContent;
  final List<GoogleSafetySetting>? safetySettings;
  final List<GoogleNativeTool>? tools;
  final bool? includeServerSideToolInvocations;
  final GoogleJsonSchemaResponseFormat? responseFormat;

  const GoogleGenerateTextOptions({
    this.candidateCount,
    this.thinkingBudgetTokens,
    this.thinkingLevel,
    this.includeThoughts,
    this.responseModalities,
    this.cachedContent,
    this.safetySettings,
    this.tools,
    this.includeServerSideToolInvocations,
    this.responseFormat,
  });
}
