class SearchSource {
  final String sourceType;
  final List<String>? excludedWebsites;

  const SearchSource({required this.sourceType, this.excludedWebsites});

  Map<String, dynamic> toJson() => {
        'type': sourceType,
        if (excludedWebsites != null) 'excluded_websites': excludedWebsites,
      };
}

class SearchParameters {
  final String? mode;
  final List<SearchSource>? sources;
  final int? maxSearchResults;
  final String? fromDate;
  final String? toDate;

  const SearchParameters({
    this.mode,
    this.sources,
    this.maxSearchResults,
    this.fromDate,
    this.toDate,
  });

  factory SearchParameters.webSearch({
    String mode = 'auto',
    int? maxResults,
    List<String>? excludedWebsites,
  }) {
    return SearchParameters(
      mode: mode,
      sources: [
        SearchSource(
          sourceType: 'web',
          excludedWebsites: excludedWebsites,
        ),
      ],
      maxSearchResults: maxResults,
    );
  }

  factory SearchParameters.newsSearch({
    String mode = 'auto',
    int? maxResults,
    String? fromDate,
    String? toDate,
    List<String>? excludedWebsites,
  }) {
    return SearchParameters(
      mode: mode,
      sources: [
        SearchSource(
          sourceType: 'news',
          excludedWebsites: excludedWebsites,
        ),
      ],
      maxSearchResults: maxResults,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  factory SearchParameters.combined({
    String mode = 'auto',
    int? maxResults,
    String? fromDate,
    String? toDate,
    List<String>? excludedWebsites,
  }) {
    return SearchParameters(
      mode: mode,
      sources: [
        SearchSource(
          sourceType: 'web',
          excludedWebsites: excludedWebsites,
        ),
        SearchSource(
          sourceType: 'news',
          excludedWebsites: excludedWebsites,
        ),
      ],
      maxSearchResults: maxResults,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Map<String, dynamic> toJson() => {
        if (mode != null) 'mode': mode,
        if (maxSearchResults != null) 'max_search_results': maxSearchResults,
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
        if (sources != null)
          'sources': sources!.map((s) => s.toJson()).toList(),
      };

  // The conversion logic from WebSearchConfig to SearchParameters lives in
  // XAIConfig. We deliberately avoid depending on WebSearchConfig here to keep
  // this subpackage decoupled from additional exports in the core package.
}
