import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_metadata.dart';

const openAIResponsesLocalShellToolName = 'local_shell';
const openAIResponsesShellToolName = 'shell';
const openAIResponsesApplyPatchToolName = 'apply_patch';

ProviderMetadata? openAIResponsesNativeShellMetadata(
  Map<String, Object?> item, {
  required String? responseId,
  required String? serviceTier,
  required int? outputIndex,
  Map<String, Object?> extra = const {},
}) {
  return openAIResponsesProviderMetadata({
    'responseId': responseId,
    'itemId': openAIResponsesNativeShellAsString(item['id']),
    'itemType': openAIResponsesNativeShellAsString(item['type']),
    'status': openAIResponsesNativeShellAsString(item['status']),
    'phase': openAIResponsesNativeShellAsString(item['phase']),
    'outputIndex': outputIndex,
    'serviceTier': serviceTier,
    ...extra,
  });
}

Map<String, Object?>? openAIResponsesNativeShellAsMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  return null;
}

List<Object?> openAIResponsesNativeShellAsList(Object? value) {
  if (value is List<Object?>) {
    return value;
  }

  if (value is List) {
    return List<Object?>.from(value);
  }

  return const [];
}

String? openAIResponsesNativeShellAsString(Object? value) {
  return value is String ? value : null;
}
