import 'package:llm_dart_provider/llm_dart_provider.dart';

const openAIResponsesImageGenerationToolName = 'image_generation';

final class OpenAIResponsesImageGenerationProjection {
  final String toolCallId;
  final String? result;
  final ProviderMetadata? providerMetadata;

  const OpenAIResponsesImageGenerationProjection({
    required this.toolCallId,
    required this.result,
    required this.providerMetadata,
  });

  ToolCallContent toToolCall() {
    return ToolCallContent(
      toolCallId: toolCallId,
      toolName: openAIResponsesImageGenerationToolName,
      input: const <String, Object?>{},
      providerExecuted: true,
    );
  }

  ToolResultContent toToolResult({
    bool preliminary = false,
  }) {
    return ToolResultContent(
      toolCallId: toolCallId,
      toolName: openAIResponsesImageGenerationToolName,
      output: {
        'result': result,
      },
      preliminary: preliminary,
    );
  }
}

OpenAIResponsesImageGenerationProjection?
    projectOpenAIResponsesImageGenerationCall(
  Map<String, Object?> item, {
  String? responseId,
  String? serviceTier,
  int? outputIndex,
}) {
  final toolCallId = _asString(item['id']);
  if (toolCallId == null) {
    return null;
  }

  return OpenAIResponsesImageGenerationProjection(
    toolCallId: toolCallId,
    result: _asString(item['result']),
    providerMetadata: openAIResponsesImageGenerationMetadata(
      item,
      responseId: responseId,
      serviceTier: serviceTier,
      outputIndex: outputIndex,
      partialImageIndex: null,
    ),
  );
}

OpenAIResponsesImageGenerationProjection
    projectOpenAIResponsesImageGenerationPartialImage({
  required Map<String, Object?> chunk,
  required String? responseId,
  required String? serviceTier,
}) {
  final toolCallId = _asString(chunk['item_id']) ?? 'image_generation';
  return OpenAIResponsesImageGenerationProjection(
    toolCallId: toolCallId,
    result: _asString(chunk['partial_image_b64']),
    providerMetadata: _providerMetadata({
      'responseId': responseId,
      'itemId': toolCallId,
      'itemType': 'image_generation_call.partial_image',
      'outputIndex': _asInt(chunk['output_index']),
      'partialImageIndex': _asInt(chunk['partial_image_index']),
      'serviceTier': serviceTier,
      'size': _asString(chunk['size']),
      'quality': _asString(chunk['quality']),
      'background': _asString(chunk['background']),
      'outputFormat': _asString(chunk['output_format']),
    }),
  );
}

ProviderMetadata? openAIResponsesImageGenerationMetadata(
  Map<String, Object?> item, {
  required String? responseId,
  required String? serviceTier,
  required int? outputIndex,
  required int? partialImageIndex,
}) {
  return _providerMetadata({
    'responseId': responseId,
    'itemId': _asString(item['id']),
    'itemType': _asString(item['type']),
    'status': _asString(item['status']),
    'phase': _asString(item['phase']),
    'outputIndex': outputIndex,
    'partialImageIndex': partialImageIndex,
    'serviceTier': serviceTier,
  });
}

ProviderMetadata? _providerMetadata(Map<String, Object?> values) {
  final openaiValues = <String, Object?>{};
  for (final entry in values.entries) {
    if (entry.value != null) {
      openaiValues[entry.key] = entry.value;
    }
  }

  if (openaiValues.isEmpty) {
    return null;
  }

  return ProviderMetadata.forNamespace('openai', openaiValues);
}

String? _asString(Object? value) {
  return value is String ? value : null;
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return null;
}
