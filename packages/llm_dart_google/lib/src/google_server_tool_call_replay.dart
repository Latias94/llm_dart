import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_replay_json.dart';
import 'google_server_tool_replay_support.dart';

final class GoogleToolCallReplay {
  static const kind = 'google.result.tool_call';
  static const schema = 'google.tool_call.v1';

  final String toolCallId;
  final String toolName;
  final Map<String, Object?> toolCall;
  final ProviderMetadata? providerMetadata;

  factory GoogleToolCallReplay.fromToolCall(
    Map<String, Object?> toolCall, {
    ProviderMetadata? providerMetadata,
  }) {
    final part = readGoogleServerToolPart(toolCall, path: 'toolCall');

    return GoogleToolCallReplay._(
      toolCallId: part.toolCallId,
      toolName: part.toolName,
      toolCall: part.part,
      providerMetadata: mergeGoogleServerToolMetadata(
        providerMetadata,
        toolCallId: part.toolCallId,
        toolName: part.toolName,
        partType: 'toolCall',
      ),
    );
  }

  factory GoogleToolCallReplay.fromJson(
    Map<String, Object?> json, {
    ProviderMetadata? providerMetadata,
  }) {
    final replay = readGoogleServerToolReplayPart(
      json,
      schema: schema,
      payloadKey: 'toolCall',
    );

    return GoogleToolCallReplay._(
      toolCallId: replay.toolCallId,
      toolName: replay.toolName,
      toolCall: replay.part,
      providerMetadata: mergeGoogleServerToolMetadata(
        providerMetadata,
        toolCallId: replay.toolCallId,
        toolName: replay.toolName,
        partType: 'toolCall',
      ),
    );
  }

  GoogleToolCallReplay._({
    required this.toolCallId,
    required this.toolName,
    required Map<String, Object?> toolCall,
    required this.providerMetadata,
  }) : toolCall = Map.unmodifiable(toolCall);

  Map<String, Object?> toJson() {
    return googleServerToolReplayJson(
      schema: schema,
      toolCallId: toolCallId,
      toolName: toolName,
      payloadKey: 'toolCall',
      payload: toToolCallJson(),
    );
  }

  Map<String, Object?> toToolCallJson() {
    return Map<String, Object?>.from(toolCall);
  }

  CustomContentPart toCustomContentPart({
    ProviderMetadata? providerMetadata,
  }) {
    return googleServerToolReplayContentPart(
      kind: kind,
      data: toJson(),
      replayMetadata: this.providerMetadata,
      providerMetadata: providerMetadata,
    );
  }

  CustomPromptPart toCustomPromptPart({
    ProviderMetadata? providerMetadata,
  }) {
    return googleServerToolReplayPromptPart(
      kind: kind,
      data: toJson(),
      replayMetadata: this.providerMetadata,
      providerMetadata: providerMetadata,
    );
  }

  CustomEvent toCustomEvent({
    ProviderMetadata? providerMetadata,
  }) {
    return googleServerToolReplayEvent(
      kind: kind,
      data: toJson(),
      replayMetadata: this.providerMetadata,
      providerMetadata: providerMetadata,
    );
  }

  static GoogleToolCallReplay? tryParsePromptPart(PromptPart part) {
    if (part is! CustomPromptPart || part.kind != kind) {
      return null;
    }

    return tryParseData(
      part.data,
      providerMetadata: providerReplayMetadataFromOptions(part.providerOptions),
    );
  }

  static GoogleToolCallReplay? tryParseContentPart(ContentPart part) {
    if (part is! CustomContentPart || part.kind != kind) {
      return null;
    }

    return tryParseData(
      part.data,
      providerMetadata: part.providerMetadata,
    );
  }

  static GoogleToolCallReplay? tryParseEvent(LanguageModelStreamEvent event) {
    if (event is! CustomEvent || event.kind != kind) {
      return null;
    }

    return tryParseData(
      event.data,
      providerMetadata: event.providerMetadata,
    );
  }

  static GoogleToolCallReplay parseData(
    Object? data, {
    ProviderMetadata? providerMetadata,
  }) {
    return GoogleToolCallReplay.fromJson(
      requireGoogleReplayObject(
        data,
        path: 'replay',
      ),
      providerMetadata: providerMetadata,
    );
  }

  static GoogleToolCallReplay? tryParseData(
    Object? data, {
    ProviderMetadata? providerMetadata,
  }) {
    return tryParseGoogleServerToolReplay(
      () => parseData(
        data,
        providerMetadata: providerMetadata,
      ),
    );
  }
}
