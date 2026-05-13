import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_shared.dart';

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
    final normalizedToolCall = _normalizeGoogleServerToolObject(
      toolCall,
      path: 'toolCall',
    );
    final toolCallId = _requiredNonEmptyString(
      normalizedToolCall['id'],
      path: 'toolCall.id',
    );
    final toolName = _requiredNonEmptyString(
      normalizedToolCall['toolType'],
      path: 'toolCall.toolType',
    );

    return GoogleToolCallReplay._(
      toolCallId: toolCallId,
      toolName: toolName,
      toolCall: normalizedToolCall,
      providerMetadata: _mergeGoogleServerToolMetadata(
        providerMetadata,
        toolCallId: toolCallId,
        toolName: toolName,
        partType: 'toolCall',
      ),
    );
  }

  factory GoogleToolCallReplay.fromJson(
    Map<String, Object?> json, {
    ProviderMetadata? providerMetadata,
  }) {
    final normalized = _normalizeGoogleServerToolObject(
      json,
      path: 'replay',
    );
    final replayRole = _requiredNonEmptyString(
      normalized['replayRole'],
      path: 'replay.replayRole',
    );
    if (replayRole != 'assistant') {
      throw FormatException(
        'Expected replay.replayRole to equal "assistant", got $replayRole.',
      );
    }

    final schemaValue = _requiredNonEmptyString(
      normalized['schema'],
      path: 'replay.schema',
    );
    if (schemaValue != schema) {
      throw FormatException(
        'Expected replay.schema to equal $schema, got $schemaValue.',
      );
    }

    final toolCallId = _requiredNonEmptyString(
      normalized['toolCallId'],
      path: 'replay.toolCallId',
    );
    final toolName = _requiredNonEmptyString(
      normalized['toolName'],
      path: 'replay.toolName',
    );
    final toolCall = _normalizeGoogleServerToolObject(
      _requiredObject(
        normalized['toolCall'],
        path: 'replay.toolCall',
      ),
      path: 'replay.toolCall',
    );
    _validateGoogleServerToolShape(
      part: toolCall,
      expectedId: toolCallId,
      expectedToolName: toolName,
      path: 'replay.toolCall',
    );

    return GoogleToolCallReplay._(
      toolCallId: toolCallId,
      toolName: toolName,
      toolCall: toolCall,
      providerMetadata: _mergeGoogleServerToolMetadata(
        providerMetadata,
        toolCallId: toolCallId,
        toolName: toolName,
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
    return {
      'schema': schema,
      'replayRole': 'assistant',
      'toolCallId': toolCallId,
      'toolName': toolName,
      'toolCall': toToolCallJson(),
    };
  }

  Map<String, Object?> toToolCallJson() {
    return Map<String, Object?>.from(toolCall);
  }

  CustomContentPart toCustomContentPart({
    ProviderMetadata? providerMetadata,
  }) {
    return CustomContentPart(
      kind: kind,
      data: toJson(),
      providerMetadata: ProviderMetadata.mergeNullable(
        this.providerMetadata,
        providerMetadata,
      ),
    );
  }

  CustomPromptPart toCustomPromptPart({
    ProviderMetadata? providerMetadata,
  }) {
    return CustomPromptPart(
      kind: kind,
      data: toJson(),
      providerOptions: ProviderReplayPromptPartOptions.fromMetadata(
        ProviderMetadata.mergeNullable(this.providerMetadata, providerMetadata),
      ),
    );
  }

  CustomEvent toCustomEvent({
    ProviderMetadata? providerMetadata,
  }) {
    return CustomEvent(
      kind: kind,
      data: toJson(),
      providerMetadata: ProviderMetadata.mergeNullable(
        this.providerMetadata,
        providerMetadata,
      ),
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

  static GoogleToolCallReplay? tryParseEvent(TextStreamEvent event) {
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
      _requiredObject(
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
    try {
      return parseData(
        data,
        providerMetadata: providerMetadata,
      );
    } on FormatException {
      return null;
    } on UnsupportedError {
      return null;
    }
  }
}

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
    final normalizedToolResponse = _normalizeGoogleServerToolObject(
      toolResponse,
      path: 'toolResponse',
    );
    final toolCallId = _requiredNonEmptyString(
      normalizedToolResponse['id'],
      path: 'toolResponse.id',
    );
    final toolName = _requiredNonEmptyString(
      normalizedToolResponse['toolType'],
      path: 'toolResponse.toolType',
    );

    return GoogleToolResponseReplay._(
      toolCallId: toolCallId,
      toolName: toolName,
      toolResponse: normalizedToolResponse,
      providerMetadata: _mergeGoogleServerToolMetadata(
        providerMetadata,
        toolCallId: toolCallId,
        toolName: toolName,
        partType: 'toolResponse',
      ),
    );
  }

  factory GoogleToolResponseReplay.fromJson(
    Map<String, Object?> json, {
    ProviderMetadata? providerMetadata,
  }) {
    final normalized = _normalizeGoogleServerToolObject(
      json,
      path: 'replay',
    );
    final replayRole = _requiredNonEmptyString(
      normalized['replayRole'],
      path: 'replay.replayRole',
    );
    if (replayRole != 'assistant') {
      throw FormatException(
        'Expected replay.replayRole to equal "assistant", got $replayRole.',
      );
    }

    final schemaValue = _requiredNonEmptyString(
      normalized['schema'],
      path: 'replay.schema',
    );
    if (schemaValue != schema) {
      throw FormatException(
        'Expected replay.schema to equal $schema, got $schemaValue.',
      );
    }

    final toolCallId = _requiredNonEmptyString(
      normalized['toolCallId'],
      path: 'replay.toolCallId',
    );
    final toolName = _requiredNonEmptyString(
      normalized['toolName'],
      path: 'replay.toolName',
    );
    final toolResponse = _normalizeGoogleServerToolObject(
      _requiredObject(
        normalized['toolResponse'],
        path: 'replay.toolResponse',
      ),
      path: 'replay.toolResponse',
    );
    _validateGoogleServerToolShape(
      part: toolResponse,
      expectedId: toolCallId,
      expectedToolName: toolName,
      path: 'replay.toolResponse',
    );

    return GoogleToolResponseReplay._(
      toolCallId: toolCallId,
      toolName: toolName,
      toolResponse: toolResponse,
      providerMetadata: _mergeGoogleServerToolMetadata(
        providerMetadata,
        toolCallId: toolCallId,
        toolName: toolName,
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
    return {
      'schema': schema,
      'replayRole': 'assistant',
      'toolCallId': toolCallId,
      'toolName': toolName,
      'toolResponse': toToolResponseJson(),
    };
  }

  Map<String, Object?> toToolResponseJson() {
    return Map<String, Object?>.from(toolResponse);
  }

  CustomContentPart toCustomContentPart({
    ProviderMetadata? providerMetadata,
  }) {
    return CustomContentPart(
      kind: kind,
      data: toJson(),
      providerMetadata: ProviderMetadata.mergeNullable(
        this.providerMetadata,
        providerMetadata,
      ),
    );
  }

  CustomPromptPart toCustomPromptPart({
    ProviderMetadata? providerMetadata,
  }) {
    return CustomPromptPart(
      kind: kind,
      data: toJson(),
      providerOptions: ProviderReplayPromptPartOptions.fromMetadata(
        ProviderMetadata.mergeNullable(this.providerMetadata, providerMetadata),
      ),
    );
  }

  CustomEvent toCustomEvent({
    ProviderMetadata? providerMetadata,
  }) {
    return CustomEvent(
      kind: kind,
      data: toJson(),
      providerMetadata: ProviderMetadata.mergeNullable(
        this.providerMetadata,
        providerMetadata,
      ),
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

  static GoogleToolResponseReplay? tryParseEvent(TextStreamEvent event) {
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
      _requiredObject(
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
    try {
      return parseData(
        data,
        providerMetadata: providerMetadata,
      );
    } on FormatException {
      return null;
    } on UnsupportedError {
      return null;
    }
  }
}

ProviderMetadata? _mergeGoogleServerToolMetadata(
  ProviderMetadata? metadata, {
  required String toolCallId,
  required String toolName,
  required String partType,
}) {
  return ProviderMetadata.mergeNullable(
    metadata,
    googleProviderMetadata({
      'serverToolPart': partType,
      'toolCallId': toolCallId,
      'toolType': toolName,
    }),
  );
}

Map<String, Object?> _normalizeGoogleServerToolObject(
  Map<String, Object?> value, {
  required String path,
}) {
  final normalized = normalizeJsonValue(value);
  if (normalized is Map<String, Object?>) {
    return normalized;
  }

  if (normalized is Map) {
    return Map<String, Object?>.from(normalized);
  }

  throw FormatException('Expected $path to be a JSON object.');
}

void _validateGoogleServerToolShape({
  required Map<String, Object?> part,
  required String expectedId,
  required String expectedToolName,
  required String path,
}) {
  final actualId = _requiredNonEmptyString(
    part['id'],
    path: '$path.id',
  );
  if (actualId != expectedId) {
    throw FormatException('Expected $path.id to equal $expectedId.');
  }

  final actualToolName = _requiredNonEmptyString(
    part['toolType'],
    path: '$path.toolType',
  );
  if (actualToolName != expectedToolName) {
    throw FormatException(
        'Expected $path.toolType to equal $expectedToolName.');
  }
}

Map<String, Object?> _requiredObject(
  Object? value, {
  required String path,
}) {
  final object = asMap(value);
  if (object == null) {
    throw FormatException('Expected $path to be an object.');
  }

  return object;
}

String _requiredNonEmptyString(
  Object? value, {
  required String path,
}) {
  final stringValue = asString(value);
  if (stringValue == null || stringValue.isEmpty) {
    throw FormatException('Expected $path to be a non-empty string.');
  }

  return stringValue;
}
