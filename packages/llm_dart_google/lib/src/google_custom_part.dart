import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'google_function_response_replay.dart';
import 'google_server_tool_replay.dart';

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
    if (GoogleToolCallReplay.tryParsePromptPart(part) case final replay?) {
      return GoogleToolCallCustomPart(replay);
    }

    if (GoogleToolResponseReplay.tryParsePromptPart(part) case final replay?) {
      return GoogleToolResponseCustomPart(replay);
    }

    if (GoogleFunctionResponseReplay.tryParsePromptPart(part)
        case final replay?) {
      return GoogleFunctionResponseCustomPart(replay);
    }

    return null;
  }

  static GoogleCustomPart? tryParseContentPart(ContentPart part) {
    if (GoogleToolCallReplay.tryParseContentPart(part) case final replay?) {
      return GoogleToolCallCustomPart(replay);
    }

    if (GoogleToolResponseReplay.tryParseContentPart(part) case final replay?) {
      return GoogleToolResponseCustomPart(replay);
    }

    if (GoogleFunctionResponseReplay.tryParseContentPart(part)
        case final replay?) {
      return GoogleFunctionResponseCustomPart(replay);
    }

    return null;
  }

  static GoogleCustomPart? tryParseEvent(TextStreamEvent event) {
    if (GoogleToolCallReplay.tryParseEvent(event) case final replay?) {
      return GoogleToolCallCustomPart(replay);
    }

    if (GoogleToolResponseReplay.tryParseEvent(event) case final replay?) {
      return GoogleToolResponseCustomPart(replay);
    }

    if (GoogleFunctionResponseReplay.tryParseEvent(event) case final replay?) {
      return GoogleFunctionResponseCustomPart(replay);
    }

    return null;
  }

  static List<GoogleCustomPart> parsePromptParts(Iterable<PromptPart> parts) {
    return parseTypedParts(parts, tryParsePromptPart);
  }

  static List<GoogleCustomPart> parseContentParts(Iterable<ContentPart> parts) {
    return parseTypedParts(parts, tryParseContentPart);
  }

  static List<GoogleCustomPart> parseEvents(Iterable<TextStreamEvent> events) {
    return parseTypedParts(events, tryParseEvent);
  }
}

final class GoogleToolCallCustomPart extends GoogleCustomPart {
  final GoogleToolCallReplay replay;

  const GoogleToolCallCustomPart(this.replay);

  @override
  String get kind => GoogleToolCallReplay.kind;

  @override
  String get toolCallId => replay.toolCallId;

  @override
  String get toolName => replay.toolName;

  @override
  String get replayRole => 'assistant';

  @override
  ProviderMetadata? get providerMetadata => replay.providerMetadata;

  Map<String, Object?> get toolCall => replay.toolCall;

  @override
  Map<String, Object?> toJson() => replay.toJson();

  CustomContentPart toCustomContentPart({
    ProviderMetadata? providerMetadata,
  }) {
    return replay.toCustomContentPart(providerMetadata: providerMetadata);
  }

  CustomPromptPart toCustomPromptPart({
    ProviderMetadata? providerMetadata,
  }) {
    return replay.toCustomPromptPart(providerMetadata: providerMetadata);
  }

  CustomEvent toCustomEvent({
    ProviderMetadata? providerMetadata,
  }) {
    return replay.toCustomEvent(providerMetadata: providerMetadata);
  }
}

final class GoogleToolResponseCustomPart extends GoogleCustomPart {
  final GoogleToolResponseReplay replay;

  const GoogleToolResponseCustomPart(this.replay);

  @override
  String get kind => GoogleToolResponseReplay.kind;

  @override
  String get toolCallId => replay.toolCallId;

  @override
  String get toolName => replay.toolName;

  @override
  String get replayRole => 'assistant';

  @override
  ProviderMetadata? get providerMetadata => replay.providerMetadata;

  Map<String, Object?> get toolResponse => replay.toolResponse;

  @override
  Map<String, Object?> toJson() => replay.toJson();

  CustomContentPart toCustomContentPart({
    ProviderMetadata? providerMetadata,
  }) {
    return replay.toCustomContentPart(providerMetadata: providerMetadata);
  }

  CustomPromptPart toCustomPromptPart({
    ProviderMetadata? providerMetadata,
  }) {
    return replay.toCustomPromptPart(providerMetadata: providerMetadata);
  }

  CustomEvent toCustomEvent({
    ProviderMetadata? providerMetadata,
  }) {
    return replay.toCustomEvent(providerMetadata: providerMetadata);
  }
}

final class GoogleFunctionResponseCustomPart extends GoogleCustomPart {
  final GoogleFunctionResponseReplay replay;

  const GoogleFunctionResponseCustomPart(this.replay);

  @override
  String get kind => GoogleFunctionResponseReplay.kind;

  @override
  String get toolCallId => replay.toolCallId;

  @override
  String get toolName => replay.toolName;

  @override
  String get replayRole => 'tool';

  @override
  ProviderMetadata? get providerMetadata => replay.providerMetadata;

  String? get functionCallId => replay.functionCallId;

  Object? get response => replay.response;

  List<GeneratedFile> get files => replay.files;

  @override
  Map<String, Object?> toJson() => replay.toJson();

  CustomContentPart toCustomContentPart({
    ProviderMetadata? providerMetadata,
  }) {
    return replay.toCustomContentPart(providerMetadata: providerMetadata);
  }

  CustomPromptPart toCustomPromptPart({
    ProviderMetadata? providerMetadata,
  }) {
    return replay.toCustomPromptPart(providerMetadata: providerMetadata);
  }

  CustomEvent toCustomEvent({
    ProviderMetadata? providerMetadata,
  }) {
    return replay.toCustomEvent(providerMetadata: providerMetadata);
  }
}
