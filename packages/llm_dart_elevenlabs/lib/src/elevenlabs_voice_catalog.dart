import 'dart:convert';

import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'elevenlabs_shared.dart';

final class ElevenLabsVoiceCatalogSettings {
  final Map<String, String> headers;

  const ElevenLabsVoiceCatalogSettings({
    this.headers = const {},
  });
}

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
      id: _requiredNonEmptyString(json['voice_id'], path: 'voice.voice_id'),
      name: _requiredNonEmptyString(json['name'], path: 'voice.name'),
      category: _optionalString(json['category'], path: 'voice.category'),
      description: _optionalString(
        json['description'],
        path: 'voice.description',
      ),
      previewUrl:
          _optionalString(json['preview_url'], path: 'voice.preview_url'),
      labels: _optionalStringMap(json['labels'], path: 'voice.labels'),
      availableForTiers: _optionalStringList(
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

final class ElevenLabsVoiceCatalogClient {
  final String apiKey;
  final String baseUrl;
  final TransportClient transport;
  final ElevenLabsVoiceCatalogSettings settings;

  ElevenLabsVoiceCatalogClient({
    required this.apiKey,
    required this.transport,
    String? baseUrl,
    this.settings = const ElevenLabsVoiceCatalogSettings(),
  }) : baseUrl = normalizeElevenLabsBaseUrl(baseUrl);

  Uri get voicesUri => Uri.parse('$baseUrl/voices');

  Future<List<ElevenLabsVoice>> listVoices({
    Duration? timeout,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final response = await transport.send(
      TransportRequest(
        uri: voicesUri,
        method: TransportMethod.get,
        headers: {
          'xi-api-key': apiKey,
          'accept': 'application/json',
          ...settings.headers,
          if (headers != null) ...headers,
        },
        timeout: timeout,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    final json = _decodeJsonObject(response.body);
    return _requiredList(json['voices'], path: 'voices')
        .asMap()
        .entries
        .map((entry) {
      return ElevenLabsVoice.fromJson(
        _requiredMap(
          entry.value,
          path: 'voices[${entry.key}]',
        ),
      );
    }).toList(growable: false);
  }
}

Map<String, Object?> _decodeJsonObject(Object? body) {
  if (body is Map<String, Object?>) {
    return body;
  }

  if (body is Map) {
    return Map<String, Object?>.from(body);
  }

  if (body is String) {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      return Map<String, Object?>.from(decoded);
    }
  }

  throw StateError(
    'Expected an ElevenLabs voice catalog JSON object but received ${body.runtimeType}.',
  );
}

Map<String, Object?> _requiredMap(
  Object? value, {
  required String path,
}) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  throw FormatException('Expected a JSON object at $path.');
}

List<Object?> _requiredList(
  Object? value, {
  required String path,
}) {
  if (value is List<Object?>) {
    return value;
  }

  if (value is List) {
    return List<Object?>.from(value);
  }

  throw FormatException('Expected a list at $path.');
}

String _requiredNonEmptyString(
  Object? value, {
  required String path,
}) {
  final normalized = _optionalString(value, path: path);
  if (normalized == null || normalized.isEmpty) {
    throw FormatException('Expected a non-empty string at $path.');
  }

  return normalized;
}

String? _optionalString(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  if (value is String) {
    return value;
  }

  throw FormatException('Expected a string at $path.');
}

Map<String, String> _optionalStringMap(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return const {};
  }

  if (value is! Map) {
    throw FormatException('Expected a string map at $path.');
  }

  return Map<String, String>.unmodifiable(
    value.map((key, mapValue) {
      if (key is! String || mapValue is! String) {
        throw FormatException('Expected string entries at $path.');
      }

      return MapEntry(key, mapValue);
    }),
  );
}

List<String> _optionalStringList(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return const [];
  }

  if (value is! List) {
    throw FormatException('Expected a string list at $path.');
  }

  return List<String>.generate(
    value.length,
    (index) => _requiredNonEmptyString(
      value[index],
      path: '$path[$index]',
    ),
    growable: false,
  );
}
