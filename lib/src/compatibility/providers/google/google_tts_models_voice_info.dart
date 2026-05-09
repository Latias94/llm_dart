/// Google voice information.
class GoogleVoiceInfo {
  /// Voice name.
  final String name;

  /// Voice description.
  final String description;

  /// Voice category (for example, `Bright` or `Upbeat`).
  final String? category;

  /// Whether this voice supports multi-speaker scenarios.
  final bool supportsMultiSpeaker;

  const GoogleVoiceInfo({
    required this.name,
    required this.description,
    this.category,
    this.supportsMultiSpeaker = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        if (category != null) 'category': category,
        'supports_multi_speaker': supportsMultiSpeaker,
      };

  factory GoogleVoiceInfo.fromJson(Map<String, dynamic> json) =>
      GoogleVoiceInfo(
        name: json['name'] as String,
        description: json['description'] as String,
        category: json['category'] as String?,
        supportsMultiSpeaker: json['supports_multi_speaker'] as bool? ?? true,
      );
}
