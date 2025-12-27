/// Google provider-native web search tool options.
///
/// This mirrors the input schema used by the Vercel AI SDK `google.google_search`
/// ProviderTool (e.g. `mode`, `dynamicThreshold`).
///
/// Notes:
/// - This is intentionally **provider-specific** (Vercel-style).
/// - Unknown keys should not be sent to the provider.
library;

/// Dynamic retrieval mode for Gemini grounding tools.
///
/// Reference (Vercel AI SDK): `googleSearch` provider tool schema.
enum GoogleDynamicRetrievalMode {
  /// Run retrieval only when the system decides it is necessary.
  dynamic('MODE_DYNAMIC'),

  /// Always trigger retrieval.
  unspecified('MODE_UNSPECIFIED');

  final String apiValue;
  const GoogleDynamicRetrievalMode(this.apiValue);

  static GoogleDynamicRetrievalMode? fromApiValue(String value) {
    for (final v in values) {
      if (v.apiValue == value) return v;
    }
    return null;
  }
}

class GoogleWebSearchToolOptions {
  final GoogleDynamicRetrievalMode? mode;
  final double? dynamicThreshold;

  const GoogleWebSearchToolOptions({
    this.mode,
    this.dynamicThreshold,
  });

  Map<String, dynamic> toJson() => {
        if (mode != null) 'mode': mode!.apiValue,
        if (dynamicThreshold != null) 'dynamicThreshold': dynamicThreshold,
      };

  factory GoogleWebSearchToolOptions.fromJson(Map<String, dynamic> json) {
    GoogleDynamicRetrievalMode? parsedMode;
    final rawMode = json['mode'];
    if (rawMode is String) {
      parsedMode = GoogleDynamicRetrievalMode.fromApiValue(rawMode);
    }

    double? parsedThreshold;
    final rawThreshold = json['dynamicThreshold'] ?? json['dynamic_threshold'];
    if (rawThreshold is num) parsedThreshold = rawThreshold.toDouble();

    return GoogleWebSearchToolOptions(
      mode: parsedMode,
      dynamicThreshold: parsedThreshold,
    );
  }
}
