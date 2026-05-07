part of 'google_chat_response.dart';

List<Map<String, dynamic>>? _extractParts(Map<String, dynamic> rawResponse) {
  final candidate = _firstCandidate(rawResponse);
  if (candidate == null) return null;

  final content = _asMap(candidate['content']);
  if (content == null) return null;

  final parts = content['parts'];
  if (parts is! List || parts.isEmpty) return null;

  final normalizedParts = <Map<String, dynamic>>[];
  for (final part in parts) {
    final partMap = _asMap(part);
    if (partMap != null) {
      normalizedParts.add(partMap);
    }
  }

  return normalizedParts.isEmpty ? null : normalizedParts;
}

Map<String, dynamic>? _firstCandidate(Map<String, dynamic> rawResponse) {
  final candidates = rawResponse['candidates'];
  if (candidates is! List || candidates.isEmpty) return null;

  return _asMap(candidates.first);
}

bool _isThought(Map<String, dynamic> part) {
  return part['thought'] as bool? ?? false;
}

String? _extractText(Map<String, dynamic> part) {
  final text = part['text'];
  if (text is String && text.isNotEmpty) {
    return text;
  }
  return null;
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}
