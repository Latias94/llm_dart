/// Configuration for Google Gemini File Search tool.
///
/// This mirrors the arguments used by the official Gemini File Search
/// tool and Vercel AI SDK's `google.file_search` provider-defined tool.
class GoogleFileSearchConfig {
  /// Fully-qualified File Search store resource names.
  ///
  /// Example: `fileSearchStores/my-file-search-store-123`
  final List<String> fileSearchStoreNames;

  /// The number of file search retrieval chunks to retrieve.
  final int? topK;

  /// Metadata filter expression for restricting retrieved documents.
  ///
  /// See https://google.aip.dev/160 for the filter syntax.
  final String? metadataFilter;

  const GoogleFileSearchConfig({
    required this.fileSearchStoreNames,
    this.topK,
    this.metadataFilter,
  });
}
