import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_custom_part.dart';
import 'google_custom_part_summary.dart';
import 'google_shared.dart';

GoogleCustomPartSummary buildGoogleCustomPartSummary(
  GoogleCustomPart part,
) {
  final title = _displayToolName(part.toolName);
  final baseFields = <GoogleCustomPartSummaryField>[
    GoogleCustomPartSummaryField(label: 'Tool', value: part.toolName),
    GoogleCustomPartSummaryField(
      label: 'Tool Call ID',
      value: part.toolCallId,
    ),
  ];

  return switch (part) {
    GoogleToolCallCustomPart() => _buildToolCallSummary(
        part,
        title: title,
        baseFields: baseFields,
      ),
    GoogleToolResponseCustomPart() => _buildToolResponseSummary(
        part,
        title: title,
        baseFields: baseFields,
      ),
    GoogleFunctionResponseCustomPart() => _buildFunctionResponseSummary(
        part,
        title: title,
        baseFields: baseFields,
      ),
    _ => throw UnsupportedError('Unsupported Google custom part: ${part.kind}'),
  };
}

GoogleCustomPartSummary _buildToolCallSummary(
  GoogleToolCallCustomPart part, {
  required String title,
  required List<GoogleCustomPartSummaryField> baseFields,
}) {
  final query = asString(part.toolCall['query']);
  final command = asString(part.toolCall['command']);
  final code = asString(part.toolCall['code']);
  final thoughtSignature = _googleMetadataString(
    part.providerMetadata,
    'thoughtSignature',
  );

  return GoogleCustomPartSummary(
    part: part,
    title: title,
    subtitle: 'Server Tool Call',
    previewText: _truncatePreview(query ?? command ?? code),
    fields: List<GoogleCustomPartSummaryField>.unmodifiable([
      ...baseFields,
      if (query != null)
        GoogleCustomPartSummaryField(label: 'Query', value: query),
      if (command != null)
        GoogleCustomPartSummaryField(label: 'Command', value: command),
      if (code != null)
        GoogleCustomPartSummaryField(label: 'Code', value: code),
      if (thoughtSignature != null)
        GoogleCustomPartSummaryField(
          label: 'Thought Signature',
          value: thoughtSignature,
        ),
    ]),
    links: const [],
    files: const [],
  );
}

GoogleCustomPartSummary _buildToolResponseSummary(
  GoogleToolResponseCustomPart part, {
  required String title,
  required List<GoogleCustomPartSummaryField> baseFields,
}) {
  final links = _extractLinks(part.toolResponse);
  final itemCount = _extractResultItemCount(part.toolResponse);
  final previewText = links.isNotEmpty
      ? (links.first.title ?? links.first.uri.toString())
      : _truncatePreview(_extractStatusText(part.toolResponse));

  return GoogleCustomPartSummary(
    part: part,
    title: title,
    subtitle: 'Server Tool Response',
    previewText: previewText,
    fields: List<GoogleCustomPartSummaryField>.unmodifiable([
      ...baseFields,
      if (itemCount != null)
        GoogleCustomPartSummaryField(
          label: 'Result Count',
          value: '$itemCount',
        ),
    ]),
    links: List<GoogleCustomPartSummaryLink>.unmodifiable(links),
    files: const [],
  );
}

GoogleCustomPartSummary _buildFunctionResponseSummary(
  GoogleFunctionResponseCustomPart part, {
  required String title,
  required List<GoogleCustomPartSummaryField> baseFields,
}) {
  final previewText = _truncatePreview(_extractPreviewFromValue(part.response));
  final status = _extractStatusText(part.response);

  return GoogleCustomPartSummary(
    part: part,
    title: title,
    subtitle: 'Function Response',
    previewText: previewText,
    fields: List<GoogleCustomPartSummaryField>.unmodifiable([
      ...baseFields,
      if (part.functionCallId != null)
        GoogleCustomPartSummaryField(
          label: 'Function Call ID',
          value: part.functionCallId!,
        ),
      if (status != null)
        GoogleCustomPartSummaryField(label: 'Status', value: status),
      if (part.files.isNotEmpty)
        GoogleCustomPartSummaryField(
          label: 'Files',
          value: '${part.files.length}',
        ),
    ]),
    links: const [],
    files: List<GeneratedFile>.unmodifiable(part.files),
  );
}

List<GoogleCustomPartSummaryLink> _extractLinks(Map<String, Object?> payload) {
  final result = asMap(payload['result']);
  final items = asList(result?['items']);
  final links = <GoogleCustomPartSummaryLink>[];

  for (final item in items) {
    final itemMap = asMap(item);
    final uriString = asString(itemMap?['uri']) ?? asString(itemMap?['url']);
    if (uriString == null) {
      continue;
    }

    final uri = Uri.tryParse(uriString);
    if (uri == null) {
      continue;
    }

    links.add(
      GoogleCustomPartSummaryLink(
        uri: uri,
        title: asString(itemMap?['title']),
      ),
    );
  }

  return links;
}

int? _extractResultItemCount(Map<String, Object?> payload) {
  final result = asMap(payload['result']);
  final items = asList(result?['items']);
  return items.isEmpty ? null : items.length;
}

String? _extractStatusText(Object? value) {
  if (value is Map<String, Object?>) {
    return asString(value['status']) ?? asString(value['message']);
  }

  if (value is Map) {
    return _extractStatusText(Map<String, Object?>.from(value));
  }

  return null;
}

String? _extractPreviewFromValue(Object? value) {
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

String? _googleMetadataString(
  ProviderMetadata? providerMetadata,
  String key,
) {
  final google = providerMetadata?.values['google'];
  final googleMap = google is Map ? Map<String, Object?>.from(google) : null;
  return asString(googleMap?[key]);
}

String _displayToolName(String toolName) {
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

String? _truncatePreview(String? value, {int maxLength = 160}) {
  if (value == null || value.isEmpty) {
    return null;
  }

  if (value.length <= maxLength) {
    return value;
  }

  return '${value.substring(0, maxLength - 1)}…';
}
