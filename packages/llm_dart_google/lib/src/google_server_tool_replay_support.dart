import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_replay_json.dart';
import 'google_shared.dart';

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

Map<String, Object?> normalizeGoogleServerToolObject(
  Map<String, Object?> value, {
  required String path,
}) {
  return normalizeGoogleReplayJsonObject(value, path: path);
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
