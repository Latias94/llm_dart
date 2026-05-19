import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_replay_json.dart';
import 'google_server_tool_replay_support.dart';

final class GoogleToolResponseReplay {
  static const kind = 'google.result.tool_response';
  static const schema = 'google.tool_response.v1';

  final String toolCallId;
  final String toolName;
  final Map<String, Object?> toolResponse;
  final ProviderMetadata? providerMetadata;

  factory GoogleToolResponseReplay.fromToolResponse(
    Map<String, Object?> toolResponse, {
    ProviderMetadata? providerMetadata,
  }) {
    final part = readGoogleServerToolPart(toolResponse, path: 'toolResponse');

    return GoogleToolResponseReplay._(
      toolCallId: part.toolCallId,
      toolName: part.toolName,
      toolResponse: part.part,
      providerMetadata: mergeGoogleServerToolMetadata(
        providerMetadata,
        toolCallId: part.toolCallId,
        toolName: part.toolName,
        partType: 'toolResponse',
      ),
    );
  }

  factory GoogleToolResponseReplay.fromJson(
    Map<String, Object?> json, {
    ProviderMetadata? providerMetadata,
  }) {
    final replay = readGoogleServerToolReplayPart(
      json,
      schema: schema,
      payloadKey: 'toolResponse',
    );

    return GoogleToolResponseReplay._(
      toolCallId: replay.toolCallId,
      toolName: replay.toolName,
      toolResponse: replay.part,
      providerMetadata: mergeGoogleServerToolMetadata(
        providerMetadata,
        toolCallId: replay.toolCallId,
        toolName: replay.toolName,
        partType: 'toolResponse',
      ),
    );
  }

  GoogleToolResponseReplay._({
    required this.toolCallId,
    required this.toolName,
    required Map<String, Object?> toolResponse,
    required this.providerMetadata,
  }) : toolResponse = Map.unmodifiable(toolResponse);

  Map<String, Object?> toJson() {
    return googleServerToolReplayJson(
      schema: schema,
      toolCallId: toolCallId,
      toolName: toolName,
      payloadKey: 'toolResponse',
      payload: toToolResponseJson(),
    );
  }

  Map<String, Object?> toToolResponseJson() {
    return Map<String, Object?>.from(toolResponse);
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

  static GoogleToolResponseReplay? tryParsePromptPart(PromptPart part) {
    if (part is! CustomPromptPart || part.kind != kind) {
      return null;
    }

    return tryParseData(
      part.data,
      providerMetadata: providerReplayMetadataFromOptions(part.providerOptions),
    );
  }

  static GoogleToolResponseReplay? tryParseContentPart(ContentPart part) {
    if (part is! CustomContentPart || part.kind != kind) {
      return null;
    }

    return tryParseData(
      part.data,
      providerMetadata: part.providerMetadata,
    );
  }

  static GoogleToolResponseReplay? tryParseEvent(
      LanguageModelStreamEvent event) {
    if (event is! CustomEvent || event.kind != kind) {
      return null;
    }

    return tryParseData(
      event.data,
      providerMetadata: event.providerMetadata,
    );
  }

  static GoogleToolResponseReplay parseData(
    Object? data, {
    ProviderMetadata? providerMetadata,
  }) {
    return GoogleToolResponseReplay.fromJson(
      requireGoogleReplayObject(
        data,
        path: 'replay',
      ),
      providerMetadata: providerMetadata,
    );
  }

  static GoogleToolResponseReplay? tryParseData(
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
