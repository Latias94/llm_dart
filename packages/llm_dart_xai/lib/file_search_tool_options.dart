library;

/// Options for the xAI Responses API `file_search` provider tool.
///
/// Mirrors Vercel AI SDK args shape for `xai.file_search`.
class XAIFileSearchToolOptions {
  final List<String>? vectorStoreIds;
  final int? maxNumResults;

  const XAIFileSearchToolOptions({
    this.vectorStoreIds,
    this.maxNumResults,
  });

  Map<String, dynamic> toJson() => {
        if (vectorStoreIds != null && vectorStoreIds!.isNotEmpty)
          'vectorStoreIds': vectorStoreIds,
        if (maxNumResults != null) 'maxNumResults': maxNumResults,
      };
}
