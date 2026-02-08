library;

/// Options for the xAI Responses API `x_search` provider tool.
///
/// Mirrors Vercel AI SDK args shape for `xai.x_search`.
class XAIXSearchToolOptions {
  final List<String>? allowedXHandles;
  final List<String>? excludedXHandles;
  final String? fromDate;
  final String? toDate;
  final bool? enableImageUnderstanding;
  final bool? enableVideoUnderstanding;

  const XAIXSearchToolOptions({
    this.allowedXHandles,
    this.excludedXHandles,
    this.fromDate,
    this.toDate,
    this.enableImageUnderstanding,
    this.enableVideoUnderstanding,
  });

  Map<String, dynamic> toJson() => {
        if (allowedXHandles != null && allowedXHandles!.isNotEmpty)
          'allowedXHandles': allowedXHandles,
        if (excludedXHandles != null && excludedXHandles!.isNotEmpty)
          'excludedXHandles': excludedXHandles,
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate != null) 'toDate': toDate,
        if (enableImageUnderstanding != null)
          'enableImageUnderstanding': enableImageUnderstanding,
        if (enableVideoUnderstanding != null)
          'enableVideoUnderstanding': enableVideoUnderstanding,
      };
}
