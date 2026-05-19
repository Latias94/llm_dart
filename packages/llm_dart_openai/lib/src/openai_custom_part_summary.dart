import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_custom_part.dart';
import 'openai_custom_part_summary_builder.dart';

final class OpenAICustomPartSummaryField {
  final String label;
  final String value;

  const OpenAICustomPartSummaryField({
    required this.label,
    required this.value,
  });
}

final class OpenAICustomPartSummary {
  final OpenAICustomPart part;
  final String title;
  final String subtitle;
  final String? previewText;
  final List<OpenAICustomPartSummaryField> fields;

  const OpenAICustomPartSummary({
    required this.part,
    required this.title,
    required this.subtitle,
    required this.previewText,
    required this.fields,
  });

  String get kind => part.kind;

  factory OpenAICustomPartSummary.fromPart(OpenAICustomPart part) {
    return buildOpenAICustomPartSummary(part);
  }

  static OpenAICustomPartSummary? tryParsePromptPart(PromptPart part) {
    final parsed = OpenAICustomPart.tryParsePromptPart(part);
    return parsed == null ? null : OpenAICustomPartSummary.fromPart(parsed);
  }

  static OpenAICustomPartSummary? tryParseContentPart(ContentPart part) {
    final parsed = OpenAICustomPart.tryParseContentPart(part);
    return parsed == null ? null : OpenAICustomPartSummary.fromPart(parsed);
  }

  static OpenAICustomPartSummary? tryParseEvent(
      LanguageModelStreamEvent event) {
    final parsed = OpenAICustomPart.tryParseEvent(event);
    return parsed == null ? null : OpenAICustomPartSummary.fromPart(parsed);
  }

  static List<OpenAICustomPartSummary> parsePromptParts(
    Iterable<PromptPart> parts,
  ) {
    return parseTypedParts(parts, tryParsePromptPart);
  }

  static List<OpenAICustomPartSummary> parseContentParts(
    Iterable<ContentPart> parts,
  ) {
    return parseTypedParts(parts, tryParseContentPart);
  }

  static List<OpenAICustomPartSummary> parseEvents(
    Iterable<LanguageModelStreamEvent> events,
  ) {
    return parseTypedParts(events, tryParseEvent);
  }
}
