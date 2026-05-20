import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_custom_part.dart';
import 'google_custom_part_summary.dart';
import 'google_custom_part_summary_projection.dart';

GoogleCustomPartSummary buildGoogleCustomPartSummary(
  GoogleCustomPart part,
) {
  final title = googleCustomPartDisplayToolName(part.toolName);
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
  final query = googleCustomPartPreviewFromValue(part.toolCall['query']);
  final command = googleCustomPartPreviewFromValue(part.toolCall['command']);
  final code = googleCustomPartPreviewFromValue(part.toolCall['code']);
  final thoughtSignature = googleCustomPartMetadataString(
    part.providerMetadata,
    'thoughtSignature',
  );

  return GoogleCustomPartSummary(
    part: part,
    title: title,
    subtitle: 'Server Tool Call',
    previewText: googleCustomPartPreviewText(query ?? command ?? code),
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
  final linkProjections = googleCustomPartResponseLinks(part.toolResponse);
  final itemCount = googleCustomPartResponseItemCount(part.toolResponse);
  final previewText = linkProjections.isNotEmpty
      ? (linkProjections.first.title ?? linkProjections.first.uri.toString())
      : googleCustomPartPreviewText(
          googleCustomPartStatusText(part.toolResponse),
        );
  final links = linkProjections.map(
    (link) => GoogleCustomPartSummaryLink(
      uri: link.uri,
      title: link.title,
    ),
  );

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
  final previewText = googleCustomPartPreviewText(
    googleCustomPartPreviewFromValue(part.response),
  );
  final status = googleCustomPartStatusText(part.response);

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
