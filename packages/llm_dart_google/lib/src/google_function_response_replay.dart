import 'package:llm_dart_provider/llm_dart_provider.dart';

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
    final normalized = normalizeGoogleReplayJsonObject(
      json,
      path: 'replay',
    );
    final replayRole = requireGoogleReplayNonEmptyString(
      normalized['replayRole'],
      path: 'replay.replayRole',
    );
    if (replayRole != 'tool') {
      throw FormatException(
        'Expected replay.replayRole to equal "tool", got $replayRole.',
      );
    }

    final schemaValue = requireGoogleReplayNonEmptyString(
      normalized['schema'],
      path: 'replay.schema',
    );
    if (schemaValue != schema) {
      throw FormatException(
        'Expected replay.schema to equal $schema, got $schemaValue.',
      );
    }

    final toolCallId = requireGoogleReplayNonEmptyString(
      normalized['toolCallId'],
      path: 'replay.toolCallId',
    );
    final toolName = requireGoogleReplayNonEmptyString(
      normalized['toolName'],
      path: 'replay.toolName',
    );
    final topLevelFunctionCallId = optionalGoogleReplayNonEmptyString(
      normalized['functionCallId'],
      path: 'replay.functionCallId',
    );

    final functionResponse = requireGoogleReplayObject(
      normalized['functionResponse'],
      path: 'replay.functionResponse',
    );
    final functionResponseName = requireGoogleReplayNonEmptyString(
      functionResponse['name'],
      path: 'replay.functionResponse.name',
    );
    if (functionResponseName != toolName) {
      throw FormatException(
        'Expected replay.functionResponse.name to equal replay.toolName.',
      );
    }
    if (!functionResponse.containsKey('response')) {
      throw FormatException(
        'Expected replay.functionResponse.response to be present.',
      );
    }

    final nestedFunctionCallId = optionalGoogleReplayNonEmptyString(
      functionResponse['id'],
      path: 'replay.functionResponse.id',
    );
    if (topLevelFunctionCallId != null &&
        nestedFunctionCallId != null &&
        topLevelFunctionCallId != nestedFunctionCallId) {
      throw FormatException(
        'Expected replay.functionCallId to match replay.functionResponse.id.',
      );
    }

    final resolvedFunctionCallId =
        topLevelFunctionCallId ?? nestedFunctionCallId;
    final normalizedFunctionResponse = Map<String, Object?>.from(
      normalizeGoogleReplayJsonObject(
        functionResponse,
        path: 'replay.functionResponse',
      ),
    );
    normalizedFunctionResponse['response'] =
        normalizeJsonValue(normalizedFunctionResponse['response']);
    if (resolvedFunctionCallId != null &&
        !normalizedFunctionResponse.containsKey('id')) {
      normalizedFunctionResponse['id'] = resolvedFunctionCallId;
    }

    final files = parseGoogleFunctionResponseFiles(
      normalizedFunctionResponse['parts'],
      path: 'replay.functionResponse.parts',
    );

    return GoogleFunctionResponseReplay._(
      toolCallId: toolCallId,
      toolName: toolName,
      functionResponse: normalizedFunctionResponse,
      files: files,
      providerMetadata: mergeProviderMetadata(
        providerMetadata,
        googleFunctionCallIdMetadata(resolvedFunctionCallId),
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
    return CustomContentPart(
      kind: kind,
      data: toJson(),
      providerMetadata: _resolvedProviderMetadata(providerMetadata),
    );
  }

  CustomPromptPart toCustomPromptPart({
    ProviderMetadata? providerMetadata,
  }) {
    return CustomPromptPart(
      kind: kind,
      data: toJson(),
      providerOptions: ProviderReplayPromptPartOptions.fromMetadata(
        _resolvedProviderMetadata(providerMetadata),
      ),
    );
  }

  CustomEvent toCustomEvent({
    ProviderMetadata? providerMetadata,
  }) {
    return CustomEvent(
      kind: kind,
      data: toJson(),
      providerMetadata: _resolvedProviderMetadata(providerMetadata),
    );
  }

  static GoogleFunctionResponseReplay? tryParseData(
    Object? data, {
    ProviderMetadata? providerMetadata,
  }) {
    try {
      return parseData(
        data,
        providerMetadata: providerMetadata,
      );
    } on FormatException {
      return null;
    } on UnsupportedError {
      return null;
    } on ArgumentError {
      return null;
    }
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

  ProviderMetadata? _resolvedProviderMetadata(
    ProviderMetadata? providerMetadata,
  ) {
    return mergeProviderMetadata(this.providerMetadata, providerMetadata);
  }
}
