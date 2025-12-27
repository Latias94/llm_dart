/// Anthropic provider-native web fetch tool options.
///
/// This mirrors the shape expected by Anthropic "server tools" like
/// `web_fetch_20250910`.
///
/// Notes:
/// - This is intentionally **provider-specific** (Vercel-style). It does not
///   try to unify web fetch across providers.
/// - Unknown keys should not be sent to the provider.
library;

class AnthropicWebFetchCitationsOptions {
  final bool enabled;

  const AnthropicWebFetchCitationsOptions({required this.enabled});

  Map<String, dynamic> toJson() => {'enabled': enabled};

  factory AnthropicWebFetchCitationsOptions.fromJson(
      Map<String, dynamic> json) {
    return AnthropicWebFetchCitationsOptions(
      enabled: json['enabled'] is bool ? json['enabled'] as bool : false,
    );
  }
}

/// Options for Anthropic `web_fetch_*` server tools.
class AnthropicWebFetchToolOptions {
  /// Maximum number of tool uses per request (`max_uses`).
  final int? maxUses;

  /// Allowed domains whitelist (`allowed_domains`).
  final List<String>? allowedDomains;

  /// Blocked domains blacklist (`blocked_domains`).
  final List<String>? blockedDomains;

  /// Optional citation configuration (`citations`).
  final AnthropicWebFetchCitationsOptions? citations;

  /// Limit the amount of fetched content included in the context (`max_content_tokens`).
  final int? maxContentTokens;

  const AnthropicWebFetchToolOptions({
    this.maxUses,
    this.allowedDomains,
    this.blockedDomains,
    this.citations,
    this.maxContentTokens,
  });

  Map<String, dynamic> toJson() => {
        if (maxUses != null) 'max_uses': maxUses,
        if (allowedDomains != null) 'allowed_domains': allowedDomains,
        if (blockedDomains != null) 'blocked_domains': blockedDomains,
        if (citations != null) 'citations': citations!.toJson(),
        if (maxContentTokens != null) 'max_content_tokens': maxContentTokens,
      };

  factory AnthropicWebFetchToolOptions.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }

    List<String>? parseStringList(dynamic value) {
      if (value is List<String>) return value;
      if (value is List) return value.whereType<String>().toList();
      return null;
    }

    AnthropicWebFetchCitationsOptions? parseCitations(dynamic value) {
      if (value is AnthropicWebFetchCitationsOptions) return value;
      if (value is Map<String, dynamic>) {
        return AnthropicWebFetchCitationsOptions.fromJson(value);
      }
      if (value is Map) {
        return AnthropicWebFetchCitationsOptions.fromJson(
          Map<String, dynamic>.from(value),
        );
      }
      return null;
    }

    return AnthropicWebFetchToolOptions(
      maxUses: parseInt(json['max_uses'] ?? json['maxUses']),
      allowedDomains:
          parseStringList(json['allowed_domains'] ?? json['allowedDomains']),
      blockedDomains:
          parseStringList(json['blocked_domains'] ?? json['blockedDomains']),
      citations: parseCitations(json['citations']),
      maxContentTokens:
          parseInt(json['max_content_tokens'] ?? json['maxContentTokens']),
    );
  }
}
