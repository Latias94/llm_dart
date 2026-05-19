import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_response_format.dart';
import 'google_safety_settings.dart';
import 'google_tools.dart';

const Object _unset = Object();

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

  GoogleGenerateTextOptions copyWith({
    Object? candidateCount = _unset,
    Object? thinkingBudgetTokens = _unset,
    Object? thinkingLevel = _unset,
    Object? includeThoughts = _unset,
    Object? responseModalities = _unset,
    Object? cachedContent = _unset,
    Object? safetySettings = _unset,
    Object? tools = _unset,
    Object? includeServerSideToolInvocations = _unset,
    Object? responseFormat = _unset,
  }) {
    return GoogleGenerateTextOptions(
      candidateCount: identical(candidateCount, _unset)
          ? this.candidateCount
          : candidateCount as int?,
      thinkingBudgetTokens: identical(thinkingBudgetTokens, _unset)
          ? this.thinkingBudgetTokens
          : thinkingBudgetTokens as int?,
      thinkingLevel: identical(thinkingLevel, _unset)
          ? this.thinkingLevel
          : thinkingLevel as GoogleThinkingLevel?,
      includeThoughts: identical(includeThoughts, _unset)
          ? this.includeThoughts
          : includeThoughts as bool?,
      responseModalities: identical(responseModalities, _unset)
          ? this.responseModalities
          : responseModalities as List<GoogleResponseModality>?,
      cachedContent: identical(cachedContent, _unset)
          ? this.cachedContent
          : cachedContent as String?,
      safetySettings: identical(safetySettings, _unset)
          ? this.safetySettings
          : safetySettings as List<GoogleSafetySetting>?,
      tools: identical(tools, _unset)
          ? this.tools
          : tools as List<GoogleNativeTool>?,
      includeServerSideToolInvocations:
          identical(includeServerSideToolInvocations, _unset)
              ? this.includeServerSideToolInvocations
              : includeServerSideToolInvocations as bool?,
      responseFormat: identical(responseFormat, _unset)
          ? this.responseFormat
          : responseFormat as GoogleJsonSchemaResponseFormat?,
    );
  }
}
