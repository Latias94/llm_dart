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

  const GoogleChatModelSettings({
    this.headers = const {},
    this.safetySettings = const [],
    this.tools = const [],
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
    this.responseFormat,
  });
}
