import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_function_response_replay_support.dart';
import 'google_replay_json.dart';

final class GoogleFunctionResponseReplayPayload {
  final String toolCallId;
  final String toolName;
  final String? functionCallId;
  final Map<String, Object?> functionResponse;
  final List<GeneratedFile> files;

  GoogleFunctionResponseReplayPayload({
    required this.toolCallId,
    required this.toolName,
    required this.functionCallId,
    required Map<String, Object?> functionResponse,
    required List<GeneratedFile> files,
  })  : functionResponse = Map.unmodifiable(functionResponse),
        files = List<GeneratedFile>.unmodifiable(files);
}

GoogleFunctionResponseReplayPayload readGoogleFunctionResponseReplayPayload(
  Map<String, Object?> json, {
  required String schema,
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

  final resolvedFunctionCallId = topLevelFunctionCallId ?? nestedFunctionCallId;
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

  return GoogleFunctionResponseReplayPayload(
    toolCallId: toolCallId,
    toolName: toolName,
    functionCallId: resolvedFunctionCallId,
    functionResponse: normalizedFunctionResponse,
    files: files,
  );
}
