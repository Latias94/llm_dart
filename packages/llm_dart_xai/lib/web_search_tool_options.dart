library;

/// Options for the xAI Responses API `web_search` provider tool.
///
/// Mirrors Vercel AI SDK args shape for `xai.web_search`.
class XAIWebSearchToolOptions {
  final List<String>? allowedDomains;
  final List<String>? excludedDomains;
  final bool? enableImageUnderstanding;

  const XAIWebSearchToolOptions({
    this.allowedDomains,
    this.excludedDomains,
    this.enableImageUnderstanding,
  });

  Map<String, dynamic> toJson() => {
        if (allowedDomains != null && allowedDomains!.isNotEmpty)
          'allowedDomains': allowedDomains,
        if (excludedDomains != null && excludedDomains!.isNotEmpty)
          'excludedDomains': excludedDomains,
        if (enableImageUnderstanding != null)
          'enableImageUnderstanding': enableImageUnderstanding,
      };
}
