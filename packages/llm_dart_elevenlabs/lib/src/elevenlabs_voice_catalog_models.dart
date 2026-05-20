import 'elevenlabs_value.dart';

final class ElevenLabsVoice {
  final String id;
  final String name;
  final String? category;
  final String? description;
  final String? previewUrl;
  final Map<String, String> labels;
  final List<String> availableForTiers;

  const ElevenLabsVoice({
    required this.id,
    required this.name,
    this.category,
    this.description,
    this.previewUrl,
    this.labels = const {},
    this.availableForTiers = const [],
  });

  factory ElevenLabsVoice.fromJson(Map<String, Object?> json) {
    return ElevenLabsVoice(
      id: elevenLabsRequiredNonEmptyString(
        json['voice_id'],
        path: 'voice.voice_id',
      ),
      name: elevenLabsRequiredNonEmptyString(json['name'], path: 'voice.name'),
      category:
          elevenLabsOptionalString(json['category'], path: 'voice.category'),
      description: elevenLabsOptionalString(
        json['description'],
        path: 'voice.description',
      ),
      previewUrl: elevenLabsOptionalString(
        json['preview_url'],
        path: 'voice.preview_url',
      ),
      labels: elevenLabsOptionalStringMap(json['labels'], path: 'voice.labels'),
      availableForTiers: elevenLabsOptionalStringList(
        json['available_for_tiers'],
        path: 'voice.available_for_tiers',
      ),
    );
  }

  String? get gender => labels['gender'];

  String? get accent => labels['accent'];

  Map<String, Object?> toJson() {
    return {
      'voice_id': id,
      'name': name,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (previewUrl != null) 'preview_url': previewUrl,
      if (labels.isNotEmpty) 'labels': labels,
      if (availableForTiers.isNotEmpty)
        'available_for_tiers': availableForTiers,
    };
  }
}

List<ElevenLabsVoice> decodeElevenLabsVoiceList(Map<String, Object?> json) {
  return elevenLabsRequiredList(json['voices'], path: 'voices')
      .asMap()
      .entries
      .map((entry) {
    return ElevenLabsVoice.fromJson(
      elevenLabsRequiredMap(
        entry.value,
        path: 'voices[${entry.key}]',
      ),
    );
  }).toList(growable: false);
}
