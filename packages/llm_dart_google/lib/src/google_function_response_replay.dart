import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_function_response_replay_custom_part.dart';
import 'google_function_response_replay_payload.dart';
import 'google_function_response_replay_support.dart';
import 'google_provider_metadata_support.dart';
import 'google_replay_json.dart';
import 'google_shared.dart';

final class GoogleFunctionResponseReplay {
  static const kind = 'google.result.function_response';
  static const schema = 'google.function_response.v1';

  final String toolCallId;
  final String toolName;
  final Map<String, Object?> functionResponse;
  final List<GeneratedFile> files;
  final ProviderMetadata? providerMetadata;

  GoogleFunctionResponseReplay({
    required String toolCallId,
    required String toolName,
    Object? response,
    List<GeneratedFile> files = const [],
    String? functionCallId,
    Map<String, Object?> extraFunctionResponseFields = const {},
    ProviderMetadata? providerMetadata,
  }) : this._(
          toolCallId: requireGoogleReplayNonEmptyValue(
            toolCallId,
            name: 'toolCallId',
          ),
          toolName: requireGoogleReplayNonEmptyValue(
            toolName,
            name: 'toolName',
          ),
          functionResponse: buildGoogleFunctionResponse(
            toolName: toolName,
            response: response,
            files: files,
            functionCallId: functionCallId,
            extraFunctionResponseFields: extraFunctionResponseFields,
          ),
          files: List<GeneratedFile>.unmodifiable(
            files.map(normalizeGoogleFunctionResponseFile),
          ),
          providerMetadata: mergeProviderMetadata(
            providerMetadata,
            googleFunctionCallIdMetadata(functionCallId),
          ),
        );

  factory GoogleFunctionResponseReplay.fromToolOutput({
    required String toolCallId,
    required String toolName,
    required ToolOutput toolOutput,
    String? functionCallId,
    Map<String, Object?> extraFunctionResponseFields = const {},
    ProviderMetadata? providerMetadata,
  }) {
    final encoded = encodeGoogleToolOutputForFunctionResponse(
      toolName: toolName,
      toolOutput: toolOutput,
    );

    return GoogleFunctionResponseReplay(
      toolCallId: toolCallId,
      toolName: toolName,
      response: encoded.response,
      files: encoded.files,
      functionCallId: functionCallId,
      extraFunctionResponseFields: extraFunctionResponseFields,
      providerMetadata: mergeProviderMetadata(
        providerMetadata,
        toolOutput.providerMetadata,
      ),
    );
  }

  factory GoogleFunctionResponseReplay.fromJson(
    Map<String, Object?> json, {
    ProviderMetadata? providerMetadata,
  }) {
    final replay = readGoogleFunctionResponseReplayPayload(
      json,
      schema: schema,
    );

    return GoogleFunctionResponseReplay._(
      toolCallId: replay.toolCallId,
      toolName: replay.toolName,
      functionResponse: replay.functionResponse,
      files: replay.files,
      providerMetadata: mergeProviderMetadata(
        providerMetadata,
        googleFunctionCallIdMetadata(replay.functionCallId),
      ),
    );
  }

  GoogleFunctionResponseReplay._({
    required this.toolCallId,
    required this.toolName,
    required Map<String, Object?> functionResponse,
    required List<GeneratedFile> files,
    required this.providerMetadata,
  })  : functionResponse = Map.unmodifiable(functionResponse),
        files = List<GeneratedFile>.unmodifiable(files);

  String? get functionCallId {
    return optionalGoogleReplayNonEmptyString(
      functionResponse['id'],
      path: 'functionResponse.id',
    );
  }

  Object? get response => functionResponse['response'];

  bool get hasFiles => files.isNotEmpty;

  Map<String, Object?> toJson() {
    return {
      'schema': schema,
      'replayRole': 'tool',
      'toolCallId': toolCallId,
      'toolName': toolName,
      if (functionCallId != null) 'functionCallId': functionCallId,
      'functionResponse': toFunctionResponseJson(),
    };
  }

  Map<String, Object?> toFunctionResponseJson() {
    return Map<String, Object?>.from(functionResponse);
  }

  CustomContentPart toCustomContentPart({
    ProviderMetadata? providerMetadata,
  }) {
    return googleFunctionResponseReplayContentPart(
      kind: kind,
      data: toJson(),
      replayMetadata: this.providerMetadata,
      providerMetadata: providerMetadata,
    );
  }

  CustomPromptPart toCustomPromptPart({
    ProviderMetadata? providerMetadata,
  }) {
    return googleFunctionResponseReplayPromptPart(
      kind: kind,
      data: toJson(),
      replayMetadata: this.providerMetadata,
      providerMetadata: providerMetadata,
    );
  }

  CustomEvent toCustomEvent({
    ProviderMetadata? providerMetadata,
  }) {
    return googleFunctionResponseReplayEvent(
      kind: kind,
      data: toJson(),
      replayMetadata: this.providerMetadata,
      providerMetadata: providerMetadata,
    );
  }

  static GoogleFunctionResponseReplay? tryParseData(
    Object? data, {
    ProviderMetadata? providerMetadata,
  }) {
    return tryParseGoogleFunctionResponseReplay(
      () => parseData(
        data,
        providerMetadata: providerMetadata,
      ),
    );
  }

  static GoogleFunctionResponseReplay parseData(
    Object? data, {
    ProviderMetadata? providerMetadata,
  }) {
    return GoogleFunctionResponseReplay.fromJson(
      requireGoogleReplayObject(
        data,
        path: 'replay',
      ),
      providerMetadata: providerMetadata,
    );
  }

  static GoogleFunctionResponseReplay? tryParseContentPart(ContentPart part) {
    if (part is! CustomContentPart || part.kind != kind) {
      return null;
    }

    return tryParseData(
      part.data,
      providerMetadata: part.providerMetadata,
    );
  }

  static GoogleFunctionResponseReplay? tryParsePromptPart(PromptPart part) {
    if (part is! CustomPromptPart || part.kind != kind) {
      return null;
    }

    return tryParseData(
      part.data,
      providerMetadata: providerReplayMetadataFromOptions(part.providerOptions),
    );
  }

  static GoogleFunctionResponseReplay? tryParseEvent(
      LanguageModelStreamEvent event) {
    if (event is! CustomEvent || event.kind != kind) {
      return null;
    }

    return tryParseData(
      event.data,
      providerMetadata: event.providerMetadata,
    );
  }
}
