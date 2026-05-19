import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_metadata.dart';
import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';

ProviderMetadata? openAIResponsesApplyPatchDiffProviderMetadata({
  required Map<String, Object?> chunk,
  required OpenAIResponsesStreamState state,
  required int outputIndex,
}) {
  return openAIResponsesProviderMetadata({
    'responseId': state.responseId,
    'itemId': openAIResponsesAsString(chunk['item_id']),
    'itemType': 'apply_patch_call',
    'outputIndex': outputIndex,
    'serviceTier': state.serviceTier,
  });
}

String? openAIResponsesApplyPatchInputPrefix(
  String toolCallId,
  Map<String, Object?> item,
) {
  final operation = openAIResponsesAsMap(item['operation']);
  final type = openAIResponsesAsString(operation?['type']);
  final path = openAIResponsesAsString(operation?['path']);
  if (type == null || path == null) {
    return null;
  }

  return '{"callId":${jsonEncode(toolCallId)},'
      '"operation":{"type":${jsonEncode(type)},'
      '"path":${jsonEncode(path)},"diff":"';
}

String? openAIResponsesApplyPatchOperationType(Map<String, Object?> item) {
  final operation = openAIResponsesAsMap(item['operation']);
  return openAIResponsesAsString(operation?['type']);
}

String? openAIResponsesApplyPatchOperationDiff(Map<String, Object?> item) {
  final operation = openAIResponsesAsMap(item['operation']);
  return openAIResponsesAsString(operation?['diff']);
}

String openAIResponsesApplyPatchEscapeJsonStringContent(String value) {
  final encoded = jsonEncode(value);
  return encoded.substring(1, encoded.length - 1);
}
