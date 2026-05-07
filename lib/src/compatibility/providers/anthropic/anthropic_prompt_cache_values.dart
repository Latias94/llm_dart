part of 'anthropic_prompt_cache_models.dart';

/// Anthropic cache control
class AnthropicCacheControl {
  final String type;
  final String? ttl;

  const AnthropicCacheControl.ephemeral({this.ttl}) : type = 'ephemeral';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'type': type};
    if (ttl != null) {
      json['ttl'] = ttl;
    }
    return json;
  }
}

/// Cache TTL options for Anthropic
enum AnthropicCacheTtl {
  fiveMinutes(300, '5m'),
  oneHour(3600, '1h');

  const AnthropicCacheTtl(this.seconds, this.value);
  final int seconds;
  final String value;

  /// Create from string value
  static AnthropicCacheTtl? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case '5m':
        return AnthropicCacheTtl.fiveMinutes;
      case '1h':
        return AnthropicCacheTtl.oneHour;
      default:
        return null;
    }
  }
}
