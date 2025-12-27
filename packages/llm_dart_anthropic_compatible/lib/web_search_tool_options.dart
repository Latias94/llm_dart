/// Anthropic provider-native web search tool options.
///
/// This mirrors the shape expected by Anthropic "server tools" like
/// `web_search_20250305`.
///
/// Notes:
/// - This is intentionally **provider-specific** (Vercel-style). It does not
///   try to unify web search across providers.
/// - Unknown keys should not be sent to the provider.
library;

/// Anthropic user location for web search.
///
/// This follows the Anthropic tool option `user_location` shape.
class AnthropicUserLocation {
  final String? type;
  final String? city;
  final String? region;
  final String? country;
  final String? timezone;

  const AnthropicUserLocation({
    this.type = 'approximate',
    this.city,
    this.region,
    this.country,
    this.timezone,
  });

  Map<String, dynamic> toJson() => {
        if (type != null) 'type': type,
        if (city != null) 'city': city,
        if (region != null) 'region': region,
        if (country != null) 'country': country,
        if (timezone != null) 'timezone': timezone,
      };

  factory AnthropicUserLocation.fromJson(Map<String, dynamic> json) {
    return AnthropicUserLocation(
      type: json['type'] as String? ??
          json['locationType'] as String? ??
          'approximate',
      city: json['city'] as String?,
      region: json['region'] as String?,
      country: json['country'] as String?,
      timezone: json['timezone'] as String?,
    );
  }
}

/// Options for Anthropic `web_search_*` server tools.
class AnthropicWebSearchToolOptions {
  /// Maximum number of tool uses per request (`max_uses`).
  final int? maxUses;

  /// Allowed domains whitelist (`allowed_domains`).
  final List<String>? allowedDomains;

  /// Blocked domains blacklist (`blocked_domains`).
  final List<String>? blockedDomains;

  /// User location hint for localized results (`user_location`).
  final AnthropicUserLocation? userLocation;

  const AnthropicWebSearchToolOptions({
    this.maxUses,
    this.allowedDomains,
    this.blockedDomains,
    this.userLocation,
  });

  Map<String, dynamic> toJson() => {
        if (maxUses != null) 'max_uses': maxUses,
        if (allowedDomains != null) 'allowed_domains': allowedDomains,
        if (blockedDomains != null) 'blocked_domains': blockedDomains,
        if (userLocation != null) 'user_location': userLocation!.toJson(),
      };

  factory AnthropicWebSearchToolOptions.fromJson(Map<String, dynamic> json) {
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

    AnthropicUserLocation? parseUserLocation(dynamic value) {
      if (value is AnthropicUserLocation) return value;
      if (value is Map<String, dynamic>) {
        return AnthropicUserLocation.fromJson(value);
      }
      if (value is Map) {
        return AnthropicUserLocation.fromJson(Map<String, dynamic>.from(value));
      }
      return null;
    }

    return AnthropicWebSearchToolOptions(
      maxUses: parseInt(json['max_uses'] ?? json['maxUses']),
      allowedDomains:
          parseStringList(json['allowed_domains'] ?? json['allowedDomains']),
      blockedDomains:
          parseStringList(json['blocked_domains'] ?? json['blockedDomains']),
      userLocation: parseUserLocation(
        json['user_location'] ?? json['userLocation'] ?? json['location'],
      ),
    );
  }
}
