import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_shared.dart';

final class GoogleCustomPartSummaryLinkProjection {
  final Uri uri;
  final String? title;

  const GoogleCustomPartSummaryLinkProjection({
    required this.uri,
    this.title,
  });
}

String googleCustomPartDisplayToolName(String toolName) {
  final normalized = toolName
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .trim();

  if (normalized.isEmpty) {
    return toolName;
  }

  return normalized
      .split(RegExp(r'\s+'))
      .map(
        (segment) => segment.isEmpty
            ? segment
            : '${segment[0].toUpperCase()}${segment.substring(1)}',
      )
      .join(' ');
}

String? googleCustomPartPreviewText(String? value, {int maxLength = 160}) {
  if (value == null || value.isEmpty) {
    return null;
  }

  if (value.length <= maxLength) {
    return value;
  }

  return '${value.substring(0, maxLength - 1)}…';
}

String? googleCustomPartMetadataString(
  ProviderMetadata? providerMetadata,
  String key,
) {
  final google = providerMetadata?.values['google'];
  final googleMap = google is Map ? Map<String, Object?>.from(google) : null;
  return asString(googleMap?[key]);
}

List<GoogleCustomPartSummaryLinkProjection> googleCustomPartResponseLinks(
  Map<String, Object?> payload,
) {
  final result = asMap(payload['result']);
  final items = asList(result?['items']);
  final links = <GoogleCustomPartSummaryLinkProjection>[];

  for (final item in items) {
    final itemMap = asMap(item);
    final uriString = asString(itemMap?['uri']) ?? asString(itemMap?['url']);
    if (uriString == null) {
      continue;
    }

    final uri = Uri.tryParse(uriString);
    if (uri == null || !uri.hasScheme) {
      continue;
    }

    links.add(
      GoogleCustomPartSummaryLinkProjection(
        uri: uri,
        title: asString(itemMap?['title']),
      ),
    );
  }

  return links;
}

int? googleCustomPartResponseItemCount(Map<String, Object?> payload) {
  final result = asMap(payload['result']);
  final items = asList(result?['items']);
  return items.isEmpty ? null : items.length;
}

String? googleCustomPartStatusText(Object? value) {
  if (value is Map<String, Object?>) {
    return asString(value['status']) ?? asString(value['message']);
  }

  if (value is Map) {
    return googleCustomPartStatusText(Map<String, Object?>.from(value));
  }

  return null;
}

String? googleCustomPartPreviewFromValue(Object? value) {
  switch (value) {
    case null:
      return null;
    case String() when value.isNotEmpty:
      return value;
    case num() || bool():
      return '$value';
    case Map():
      final normalized = Map<String, Object?>.from(value);
      return asString(normalized['status']) ??
          asString(normalized['message']) ??
          asString(normalized['text']);
    default:
      return null;
  }
}
