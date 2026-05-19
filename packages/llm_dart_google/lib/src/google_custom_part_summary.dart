import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_custom_part.dart';
import 'google_custom_part_summary_builder.dart';

final class GoogleCustomPartSummaryField {
  final String label;
  final String value;

  const GoogleCustomPartSummaryField({
    required this.label,
    required this.value,
  });
}

final class GoogleCustomPartSummaryLink {
  final Uri uri;
  final String? title;

  const GoogleCustomPartSummaryLink({
    required this.uri,
    this.title,
  });
}

/// Provider-owned render summary for Google custom replay payloads.
///
/// This helper keeps Google-specific inspection and lightweight rendering logic
/// in `llm_dart_google` instead of pushing raw JSON parsing into Flutter UIs or
/// widening the shared custom-part model.
final class GoogleCustomPartSummary {
  final GoogleCustomPart part;
  final String title;
  final String subtitle;
  final String? previewText;
  final List<GoogleCustomPartSummaryField> fields;
  final List<GoogleCustomPartSummaryLink> links;
  final List<GeneratedFile> files;

  const GoogleCustomPartSummary({
    required this.part,
    required this.title,
    required this.subtitle,
    required this.previewText,
    required this.fields,
    required this.links,
    required this.files,
  });

  String get kind => part.kind;

  String get toolCallId => part.toolCallId;

  String get toolName => part.toolName;

  bool get hasLinks => links.isNotEmpty;

  bool get hasFiles => files.isNotEmpty;

  bool get hasPreviewText => previewText != null && previewText!.isNotEmpty;

  factory GoogleCustomPartSummary.fromPart(GoogleCustomPart part) {
    return buildGoogleCustomPartSummary(part);
  }

  static GoogleCustomPartSummary? tryParsePromptPart(PromptPart part) {
    final parsed = GoogleCustomPart.tryParsePromptPart(part);
    return parsed == null ? null : GoogleCustomPartSummary.fromPart(parsed);
  }

  static GoogleCustomPartSummary? tryParseContentPart(ContentPart part) {
    final parsed = GoogleCustomPart.tryParseContentPart(part);
    return parsed == null ? null : GoogleCustomPartSummary.fromPart(parsed);
  }

  static GoogleCustomPartSummary? tryParseEvent(
      LanguageModelStreamEvent event) {
    final parsed = GoogleCustomPart.tryParseEvent(event);
    return parsed == null ? null : GoogleCustomPartSummary.fromPart(parsed);
  }

  static List<GoogleCustomPartSummary> parsePromptParts(
    Iterable<PromptPart> parts,
  ) {
    return parseTypedParts(parts, tryParsePromptPart);
  }

  static List<GoogleCustomPartSummary> parseContentParts(
    Iterable<ContentPart> parts,
  ) {
    return parseTypedParts(parts, tryParseContentPart);
  }

  static List<GoogleCustomPartSummary> parseEvents(
    Iterable<LanguageModelStreamEvent> events,
  ) {
    return parseTypedParts(events, tryParseEvent);
  }
}
