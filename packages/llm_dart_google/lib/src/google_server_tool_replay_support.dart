import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_replay_json.dart';
import 'google_shared.dart';

final class GoogleServerToolReplayPart {
  final String toolCallId;
  final String toolName;
  final Map<String, Object?> part;

  GoogleServerToolReplayPart({
    required this.toolCallId,
    required this.toolName,
    required Map<String, Object?> part,
  }) : part = Map.unmodifiable(part);
}

ProviderMetadata? mergeGoogleServerToolMetadata(
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

ProviderMetadata? mergeGoogleServerToolReplayMetadata(
  ProviderMetadata? replayMetadata,
  ProviderMetadata? providerMetadata,
) {
  return ProviderMetadata.mergeNullable(replayMetadata, providerMetadata);
}

Map<String, Object?> normalizeGoogleServerToolObject(
  Map<String, Object?> value, {
  required String path,
}) {
  return normalizeGoogleReplayJsonObject(value, path: path);
}

GoogleServerToolReplayPart readGoogleServerToolPart(
  Map<String, Object?> value, {
  required String path,
}) {
  final normalized = normalizeGoogleServerToolObject(value, path: path);
  return GoogleServerToolReplayPart(
    toolCallId: requireGoogleReplayNonEmptyString(
      normalized['id'],
      path: '$path.id',
    ),
    toolName: requireGoogleReplayNonEmptyString(
      normalized['toolType'],
      path: '$path.toolType',
    ),
    part: normalized,
  );
}

GoogleServerToolReplayPart readGoogleServerToolReplayPart(
  Map<String, Object?> json, {
  required String schema,
  required String payloadKey,
}) {
  final normalized = normalizeGoogleServerToolObject(json, path: 'replay');
  final replayRole = requireGoogleReplayNonEmptyString(
    normalized['replayRole'],
    path: 'replay.replayRole',
  );
  if (replayRole != 'assistant') {
    throw FormatException(
      'Expected replay.replayRole to equal "assistant", got $replayRole.',
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
  final payloadPath = 'replay.$payloadKey';
  final payload = normalizeGoogleServerToolObject(
    requireGoogleReplayObject(
      normalized[payloadKey],
      path: payloadPath,
    ),
    path: payloadPath,
  );
  validateGoogleServerToolShape(
    part: payload,
    expectedId: toolCallId,
    expectedToolName: toolName,
    path: payloadPath,
  );

  return GoogleServerToolReplayPart(
    toolCallId: toolCallId,
    toolName: toolName,
    part: payload,
  );
}

Map<String, Object?> googleServerToolReplayJson({
  required String schema,
  required String toolCallId,
  required String toolName,
  required String payloadKey,
  required Map<String, Object?> payload,
}) {
  return {
    'schema': schema,
    'replayRole': 'assistant',
    'toolCallId': toolCallId,
    'toolName': toolName,
    payloadKey: Map<String, Object?>.from(payload),
  };
}

CustomContentPart googleServerToolReplayContentPart({
  required String kind,
  required Map<String, Object?> data,
  ProviderMetadata? replayMetadata,
  ProviderMetadata? providerMetadata,
}) {
  return CustomContentPart(
    kind: kind,
    data: data,
    providerMetadata: mergeGoogleServerToolReplayMetadata(
      replayMetadata,
      providerMetadata,
    ),
  );
}

CustomPromptPart googleServerToolReplayPromptPart({
  required String kind,
  required Map<String, Object?> data,
  ProviderMetadata? replayMetadata,
  ProviderMetadata? providerMetadata,
}) {
  return CustomPromptPart(
    kind: kind,
    data: data,
    providerOptions: ProviderReplayPromptPartOptions.fromMetadata(
      mergeGoogleServerToolReplayMetadata(replayMetadata, providerMetadata),
    ),
  );
}

CustomEvent googleServerToolReplayEvent({
  required String kind,
  required Map<String, Object?> data,
  ProviderMetadata? replayMetadata,
  ProviderMetadata? providerMetadata,
}) {
  return CustomEvent(
    kind: kind,
    data: data,
    providerMetadata: mergeGoogleServerToolReplayMetadata(
      replayMetadata,
      providerMetadata,
    ),
  );
}

T? tryParseGoogleServerToolReplay<T>(T Function() parse) {
  try {
    return parse();
  } on FormatException {
    return null;
  } on UnsupportedError {
    return null;
  }
}

void validateGoogleServerToolShape({
  required Map<String, Object?> part,
  required String expectedId,
  required String expectedToolName,
  required String path,
}) {
  final actualId = requireGoogleReplayNonEmptyString(
    part['id'],
    path: '$path.id',
  );
  if (actualId != expectedId) {
    throw FormatException('Expected $path.id to equal $expectedId.');
  }

  final actualToolName = requireGoogleReplayNonEmptyString(
    part['toolType'],
    path: '$path.toolType',
  );
  if (actualToolName != expectedToolName) {
    throw FormatException(
      'Expected $path.toolType to equal $expectedToolName.',
    );
  }
}
