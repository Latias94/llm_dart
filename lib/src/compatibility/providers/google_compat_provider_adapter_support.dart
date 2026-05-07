part of 'google_compat_provider.dart';

final class _GoogleCompatAdapterSupport {
  const _GoogleCompatAdapterSupport();

  GoogleLegacyChatCapabilityAdapter buildAdapter({
    required LLMConfig originalConfig,
    required GoogleConfig legacyConfig,
    required modern_google.Google modernProvider,
  }) {
    return GoogleLegacyChatCapabilityAdapter(
      model: modernProvider.chatModel(originalConfig.model),
      config: originalConfig,
      providerOptions: buildProviderOptions(legacyConfig),
    );
  }

  modern_google.GoogleGenerateTextOptions buildProviderOptions(
    GoogleConfig config,
  ) {
    return modern_google.GoogleGenerateTextOptions(
      candidateCount: config.candidateCount,
      thinkingBudgetTokens: config.thinkingBudgetTokens,
      thinkingLevel: _mapThinkingLevel(config.reasoningEffort),
      includeThoughts: config.includeThoughts,
      responseModalities: _mapResponseModalities(config),
      safetySettings: _mapSafetySettings(config.safetySettings),
      tools: _buildNativeTools(config),
    );
  }

  modern_google.GoogleThinkingLevel? _mapThinkingLevel(
    ReasoningEffort? effort,
  ) {
    return switch (effort) {
      ReasoningEffort.minimal => modern_google.GoogleThinkingLevel.minimal,
      ReasoningEffort.low => modern_google.GoogleThinkingLevel.low,
      ReasoningEffort.medium => modern_google.GoogleThinkingLevel.medium,
      ReasoningEffort.high => modern_google.GoogleThinkingLevel.high,
      _ => null,
    };
  }

  List<modern_google.GoogleResponseModality>? _mapResponseModalities(
    GoogleConfig config,
  ) {
    final rawValues = config.responseModalities;
    final mapped = <modern_google.GoogleResponseModality>[];

    if (rawValues != null) {
      for (final rawValue in rawValues) {
        switch (rawValue.toString().toUpperCase()) {
          case 'TEXT':
            mapped.add(modern_google.GoogleResponseModality.text);
            break;
          case 'IMAGE':
            mapped.add(modern_google.GoogleResponseModality.image);
            break;
          default:
            break;
        }
      }
    } else if (config.enableImageGeneration == true) {
      mapped.addAll(const [
        modern_google.GoogleResponseModality.text,
        modern_google.GoogleResponseModality.image,
      ]);
    }

    return mapped.isEmpty ? null : mapped;
  }

  List<modern_google.GoogleSafetySetting>? _mapSafetySettings(
    List<SafetySetting>? settings,
  ) {
    if (settings == null || settings.isEmpty) {
      return null;
    }

    return settings
        .map(
          (setting) => modern_google.GoogleSafetySetting(
            category: modern_google.GoogleHarmCategory.values.firstWhere(
              (value) => value.value == setting.category.value,
              orElse: () => modern_google.GoogleHarmCategory.unspecified,
            ),
            threshold: modern_google.GoogleHarmBlockThreshold.values.firstWhere(
              (value) => value.value == setting.threshold.value,
              orElse: () => modern_google.GoogleHarmBlockThreshold.unspecified,
            ),
          ),
        )
        .toList(growable: false);
  }

  List<modern_google.GoogleNativeTool>? _buildNativeTools(
    GoogleConfig config,
  ) {
    if (!config.webSearchEnabled) {
      return null;
    }

    final timeRangeFilter = _buildTimeRangeFilter(config.webSearchConfig);

    return [
      modern_google.GoogleTools.googleSearch(
        timeRangeFilter: timeRangeFilter,
      ),
    ];
  }

  modern_google.GoogleTimeRangeFilter? _buildTimeRangeFilter(
    WebSearchConfig? config,
  ) {
    if (config == null || config.fromDate == null || config.toDate == null) {
      return null;
    }

    final startTime = DateTime.tryParse(config.fromDate!);
    final endTime = DateTime.tryParse(config.toDate!);
    if (startTime == null || endTime == null) {
      return null;
    }

    return modern_google.GoogleTimeRangeFilter(
      startTime: startTime,
      endTime: endTime,
    );
  }
}
