import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_options.dart';

enum XAISearchMode {
  off('off'),
  auto('auto'),
  on('on');

  const XAISearchMode(this.wireValue);

  final String wireValue;
}

sealed class XAISearchSource {
  const XAISearchSource();

  Map<String, Object?> toJson();
}

final class XAIWebSearchSource extends XAISearchSource {
  final String? countryCode;
  final List<String> allowedWebsites;
  final List<String> excludedWebsites;
  final bool? safeSearch;

  const XAIWebSearchSource({
    this.countryCode,
    this.allowedWebsites = const [],
    this.excludedWebsites = const [],
    this.safeSearch,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'web',
      if (countryCode != null) 'country': countryCode,
      if (allowedWebsites.isNotEmpty) 'allowed_websites': allowedWebsites,
      if (excludedWebsites.isNotEmpty) 'excluded_websites': excludedWebsites,
      if (safeSearch != null) 'safe_search': safeSearch,
    };
  }
}

final class XAINewsSearchSource extends XAISearchSource {
  final String? countryCode;
  final List<String> excludedWebsites;
  final bool? safeSearch;

  const XAINewsSearchSource({
    this.countryCode,
    this.excludedWebsites = const [],
    this.safeSearch,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'news',
      if (countryCode != null) 'country': countryCode,
      if (excludedWebsites.isNotEmpty) 'excluded_websites': excludedWebsites,
      if (safeSearch != null) 'safe_search': safeSearch,
    };
  }
}

final class XAIXSearchSource extends XAISearchSource {
  final List<String> includedHandles;
  final List<String> excludedHandles;
  final int? minFavoriteCount;
  final int? minViewCount;

  const XAIXSearchSource({
    this.includedHandles = const [],
    this.excludedHandles = const [],
    this.minFavoriteCount,
    this.minViewCount,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'x',
      if (includedHandles.isNotEmpty) 'included_x_handles': includedHandles,
      if (excludedHandles.isNotEmpty) 'excluded_x_handles': excludedHandles,
      if (minFavoriteCount != null) 'post_favorite_count': minFavoriteCount,
      if (minViewCount != null) 'post_view_count': minViewCount,
    };
  }
}

final class XAIRssSearchSource extends XAISearchSource {
  final List<Uri> feeds;

  const XAIRssSearchSource(this.feeds);

  @override
  Map<String, Object?> toJson() {
    if (feeds.isEmpty) {
      throw ArgumentError('XAIRssSearchSource.feeds must not be empty.');
    }

    if (feeds.length > 1) {
      throw ArgumentError(
        'XAIRssSearchSource currently supports at most one RSS feed.',
      );
    }

    return {
      'type': 'rss',
      'links': feeds.map((uri) => uri.toString()).toList(growable: false),
    };
  }
}

final class XAILiveSearchOptions {
  final XAISearchMode mode;
  final bool returnCitations;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int? maxSearchResults;
  final List<XAISearchSource> sources;

  const XAILiveSearchOptions({
    this.mode = XAISearchMode.auto,
    this.returnCitations = true,
    this.fromDate,
    this.toDate,
    this.maxSearchResults,
    this.sources = const [],
  });

  const XAILiveSearchOptions.autoWeb({
    this.returnCitations = true,
    this.maxSearchResults,
  })  : mode = XAISearchMode.auto,
        fromDate = null,
        toDate = null,
        sources = const [XAIWebSearchSource()];

  Map<String, Object?> toJson() {
    if (maxSearchResults != null &&
        (maxSearchResults! < 1 || maxSearchResults! > 50)) {
      throw ArgumentError(
        'XAILiveSearchOptions.maxSearchResults must be between 1 and 50.',
      );
    }

    if (fromDate != null && toDate != null && toDate!.isBefore(fromDate!)) {
      throw ArgumentError(
        'XAILiveSearchOptions.toDate must be on or after fromDate.',
      );
    }

    return {
      'mode': mode.wireValue,
      'return_citations': returnCitations,
      if (fromDate != null) 'from_date': _encodeDate(fromDate!),
      if (toDate != null) 'to_date': _encodeDate(toDate!),
      if (maxSearchResults != null) 'max_search_results': maxSearchResults,
      if (sources.isNotEmpty)
        'sources': sources.map((source) => source.toJson()).toList(),
    };
  }

  String _encodeDate(DateTime value) {
    final utc = value.toUtc();
    final year = utc.year.toString().padLeft(4, '0');
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

final class XAIGenerateTextOptions implements ProviderInvocationOptions {
  final OpenAIGenerateTextOptions common;
  final XAILiveSearchOptions? search;

  const XAIGenerateTextOptions({
    this.common = const OpenAIGenerateTextOptions(),
    this.search,
  });
}
