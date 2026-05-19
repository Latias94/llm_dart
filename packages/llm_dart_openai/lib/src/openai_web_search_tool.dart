import 'openai_builtin_tool.dart';

enum OpenAIWebSearchApi {
  preview('web_search_preview'),
  current('web_search');

  const OpenAIWebSearchApi(this.value);

  final String value;
}

enum OpenAIWebSearchContextSize {
  low('low'),
  medium('medium'),
  high('high');

  const OpenAIWebSearchContextSize(this.value);

  final String value;
}

final class OpenAIWebSearchFilters {
  final List<String>? allowedDomains;

  const OpenAIWebSearchFilters({
    this.allowedDomains,
  });

  Map<String, Object?> toJson() {
    return {
      if (allowedDomains != null)
        'allowed_domains': List<String>.unmodifiable(allowedDomains!),
    };
  }
}

final class OpenAIWebSearchUserLocation {
  final String? country;
  final String? city;
  final String? region;
  final String? timezone;

  const OpenAIWebSearchUserLocation({
    this.country,
    this.city,
    this.region,
    this.timezone,
  });

  Map<String, Object?> toJson() {
    return {
      'type': 'approximate',
      if (country != null) 'country': country,
      if (city != null) 'city': city,
      if (region != null) 'region': region,
      if (timezone != null) 'timezone': timezone,
    };
  }
}

final class OpenAIWebSearchTool implements OpenAIBuiltInTool {
  final OpenAIWebSearchApi api;
  final OpenAIWebSearchContextSize? searchContextSize;
  final OpenAIWebSearchUserLocation? userLocation;
  final OpenAIWebSearchFilters? filters;
  final bool? externalWebAccess;

  const OpenAIWebSearchTool({
    this.api = OpenAIWebSearchApi.preview,
    this.searchContextSize,
    this.userLocation,
    this.filters,
    this.externalWebAccess,
  })  : assert(
          api == OpenAIWebSearchApi.current || filters == null,
          'OpenAI web_search_preview does not support filters.',
        ),
        assert(
          api == OpenAIWebSearchApi.current || externalWebAccess == null,
          'OpenAI web_search_preview does not support externalWebAccess.',
        );

  const OpenAIWebSearchTool.preview({
    this.searchContextSize,
    this.userLocation,
  })  : api = OpenAIWebSearchApi.preview,
        filters = null,
        externalWebAccess = null;

  const OpenAIWebSearchTool.current({
    this.searchContextSize,
    this.userLocation,
    this.filters,
    this.externalWebAccess,
  }) : api = OpenAIWebSearchApi.current;

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.webSearch;

  @override
  Map<String, Object?> toJson() {
    _validateApiOptions();

    return {
      'type': api.value,
      if (searchContextSize != null)
        'search_context_size': searchContextSize!.value,
      if (userLocation != null) 'user_location': userLocation!.toJson(),
      if (filters != null) 'filters': filters!.toJson(),
      if (externalWebAccess != null) 'external_web_access': externalWebAccess,
    };
  }

  void _validateApiOptions() {
    if (api == OpenAIWebSearchApi.current) {
      return;
    }
    if (filters != null) {
      throw UnsupportedError(
        'OpenAI web_search_preview does not support filters. '
        'Use OpenAIWebSearchTool.current instead.',
      );
    }
    if (externalWebAccess != null) {
      throw UnsupportedError(
        'OpenAI web_search_preview does not support externalWebAccess. '
        'Use OpenAIWebSearchTool.current instead.',
      );
    }
  }
}
