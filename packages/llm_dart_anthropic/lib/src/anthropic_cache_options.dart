final class AnthropicCacheControl {
  final String type;
  final String? ttl;

  const AnthropicCacheControl({
    required this.type,
    this.ttl,
  });

  const AnthropicCacheControl.ephemeral({
    this.ttl,
  }) : type = 'ephemeral';

  Map<String, Object?> toJson() {
    return {
      'type': type,
      if (ttl != null) 'ttl': ttl,
    };
  }
}
