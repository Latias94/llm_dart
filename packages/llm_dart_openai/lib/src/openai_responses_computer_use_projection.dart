import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_support.dart';

const openAIResponsesComputerUseToolName = 'computer_use';

final class OpenAIResponsesComputerUseProjection {
  final String toolCallId;
  final String status;
  final ProviderMetadata? providerMetadata;

  const OpenAIResponsesComputerUseProjection({
    required this.toolCallId,
    required this.status,
    required this.providerMetadata,
  });

  ToolCallContent toToolCall() {
    return ToolCallContent(
      toolCallId: toolCallId,
      toolName: openAIResponsesComputerUseToolName,
      input: '',
      providerExecuted: true,
    );
  }

  ToolResultContent toToolResult() {
    return ToolResultContent(
      toolCallId: toolCallId,
      toolName: openAIResponsesComputerUseToolName,
      output: {
        'type': 'computer_use_tool_result',
        'status': status,
      },
    );
  }
}

OpenAIResponsesComputerUseProjection? projectOpenAIResponsesComputerUseCall(
  Map<String, Object?> item, {
  String? responseId,
  String? serviceTier,
  int? outputIndex,
}) {
  final toolCallId = _asString(item['id']);
  if (toolCallId == null) {
    return null;
  }

  return OpenAIResponsesComputerUseProjection(
    toolCallId: toolCallId,
    status: _asString(item['status']) ?? 'completed',
    providerMetadata: openAIResponsesProviderMetadata({
      'responseId': responseId,
      'itemId': toolCallId,
      'itemType': _asString(item['type']),
      'status': _asString(item['status']),
      'phase': _asString(item['phase']),
      'outputIndex': outputIndex,
      'serviceTier': serviceTier,
    }),
  );
}

String? _asString(Object? value) => value is String ? value : null;
