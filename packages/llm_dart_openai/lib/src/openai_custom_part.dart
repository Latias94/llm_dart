import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

part 'openai_custom_part_models.dart';
part 'openai_custom_part_parser.dart';
part 'openai_custom_part_value_support.dart';

sealed class OpenAICustomPart {
  const OpenAICustomPart();

  String get kind;
  Map<String, Object?> get payload;
  ProviderMetadata? get providerMetadata;

  static OpenAICustomPart? tryParsePromptPart(PromptPart part) {
    return switch (part) {
      CustomPromptPart(:final kind, :final data, :final providerOptions) =>
        _parseCustomPayload(
          kind: kind,
          data: data,
          providerMetadata: providerReplayMetadataFromOptions(providerOptions),
        ),
      _ => null,
    };
  }

  static OpenAICustomPart? tryParseContentPart(ContentPart part) {
    return switch (part) {
      CustomContentPart(:final kind, :final data, :final providerMetadata) =>
        _parseCustomPayload(
          kind: kind,
          data: data,
          providerMetadata: providerMetadata,
        ),
      _ => null,
    };
  }

  static OpenAICustomPart? tryParseEvent(LanguageModelStreamEvent event) {
    return switch (event) {
      CustomEvent(:final kind, :final data, :final providerMetadata) =>
        _parseCustomPayload(
          kind: kind,
          data: data,
          providerMetadata: providerMetadata,
        ),
      _ => null,
    };
  }

  static List<OpenAICustomPart> parsePromptParts(Iterable<PromptPart> parts) {
    return parseTypedParts(parts, tryParsePromptPart);
  }

  static List<OpenAICustomPart> parseContentParts(Iterable<ContentPart> parts) {
    return parseTypedParts(parts, tryParseContentPart);
  }

  static List<OpenAICustomPart> parseEvents(
      Iterable<LanguageModelStreamEvent> events) {
    return parseTypedParts(events, tryParseEvent);
  }
}
