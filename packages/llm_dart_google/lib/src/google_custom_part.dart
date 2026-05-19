import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_function_response_replay.dart';
import 'google_server_tool_replay.dart';

part 'google_custom_part_models.dart';
part 'google_custom_part_parser.dart';

/// Provider-owned typed wrapper for Google custom replay payloads.
///
/// This gives higher layers one parsing entrypoint for provider-owned custom
/// parts emitted by `llm_dart_google` without depending on UI/runtime types.
sealed class GoogleCustomPart {
  const GoogleCustomPart();

  String get kind;
  String get toolCallId;
  String get toolName;
  String get replayRole;
  ProviderMetadata? get providerMetadata;

  bool get isAssistantReplay => replayRole == 'assistant';

  bool get isToolReplay => replayRole == 'tool';

  Map<String, Object?> toJson();

  static GoogleCustomPart? tryParsePromptPart(PromptPart part) {
    return _parseGoogleCustomPromptPart(part);
  }

  static GoogleCustomPart? tryParseContentPart(ContentPart part) {
    return _parseGoogleCustomContentPart(part);
  }

  static GoogleCustomPart? tryParseEvent(LanguageModelStreamEvent event) {
    return _parseGoogleCustomEvent(event);
  }

  static List<GoogleCustomPart> parsePromptParts(Iterable<PromptPart> parts) {
    return parseTypedParts(parts, tryParsePromptPart);
  }

  static List<GoogleCustomPart> parseContentParts(Iterable<ContentPart> parts) {
    return parseTypedParts(parts, tryParseContentPart);
  }

  static List<GoogleCustomPart> parseEvents(
    Iterable<LanguageModelStreamEvent> events,
  ) {
    return parseTypedParts(events, tryParseEvent);
  }
}
