sealed class AnthropicNativeTool {
  const AnthropicNativeTool();

  String get name;

  Map<String, Object?> toJson();
}

final class AnthropicApproximateLocation {
  final String? city;
  final String? region;
  final String? country;
  final String? timezone;

  const AnthropicApproximateLocation({
    this.city,
    this.region,
    this.country,
    this.timezone,
  });

  Map<String, Object?> toJson() {
    return {
      'type': 'approximate',
      if (city != null) 'city': city,
      if (region != null) 'region': region,
      if (country != null) 'country': country,
      if (timezone != null) 'timezone': timezone,
    };
  }
}

final class AnthropicWebSearchTool20250305 extends AnthropicNativeTool {
  final int? maxUses;
  final List<String> allowedDomains;
  final List<String> blockedDomains;
  final AnthropicApproximateLocation? userLocation;

  const AnthropicWebSearchTool20250305({
    this.maxUses,
    this.allowedDomains = const [],
    this.blockedDomains = const [],
    this.userLocation,
  });

  @override
  String get name => 'web_search';

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'web_search_20250305',
      'name': 'web_search',
      if (maxUses != null) 'max_uses': maxUses,
      if (allowedDomains.isNotEmpty) 'allowed_domains': allowedDomains,
      if (blockedDomains.isNotEmpty) 'blocked_domains': blockedDomains,
      if (userLocation != null) 'user_location': userLocation!.toJson(),
    };
  }
}

final class AnthropicCodeExecutionTool20260120 extends AnthropicNativeTool {
  const AnthropicCodeExecutionTool20260120();

  @override
  String get name => 'code_execution';

  @override
  Map<String, Object?> toJson() {
    return const {
      'type': 'code_execution_20260120',
      'name': 'code_execution',
    };
  }
}

final class AnthropicToolSearchRegexTool20251119 extends AnthropicNativeTool {
  const AnthropicToolSearchRegexTool20251119();

  @override
  String get name => 'tool_search_tool_regex';

  @override
  Map<String, Object?> toJson() {
    return const {
      'type': 'tool_search_tool_regex_20251119',
      'name': 'tool_search_tool_regex',
    };
  }
}

final class AnthropicToolSearchBm25Tool20251119 extends AnthropicNativeTool {
  const AnthropicToolSearchBm25Tool20251119();

  @override
  String get name => 'tool_search_tool_bm25';

  @override
  Map<String, Object?> toJson() {
    return const {
      'type': 'tool_search_tool_bm25_20251119',
      'name': 'tool_search_tool_bm25',
    };
  }
}

abstract final class AnthropicTools {
  static AnthropicWebSearchTool20250305 webSearch20250305({
    int? maxUses,
    List<String> allowedDomains = const [],
    List<String> blockedDomains = const [],
    AnthropicApproximateLocation? userLocation,
  }) {
    return AnthropicWebSearchTool20250305(
      maxUses: maxUses,
      allowedDomains: allowedDomains,
      blockedDomains: blockedDomains,
      userLocation: userLocation,
    );
  }

  static AnthropicCodeExecutionTool20260120 codeExecution20260120() {
    return const AnthropicCodeExecutionTool20260120();
  }

  static AnthropicToolSearchRegexTool20251119 toolSearchRegex20251119() {
    return const AnthropicToolSearchRegexTool20251119();
  }

  static AnthropicToolSearchBm25Tool20251119 toolSearchBm2520251119() {
    return const AnthropicToolSearchBm25Tool20251119();
  }
}
