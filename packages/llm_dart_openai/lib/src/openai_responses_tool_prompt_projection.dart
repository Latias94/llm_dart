import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_replay_policy.dart';
import 'openai_responses_request_tool_codec.dart';

final class OpenAIResponsesToolPromptProjection {
  final OpenAIResponsesRequestToolCodec toolCodec;

  const OpenAIResponsesToolPromptProjection({
    this.toolCodec = const OpenAIResponsesRequestToolCodec(),
  });

  List<Object?> encode(
    ToolPromptMessage message, {
    required OpenAIResponsesReplayPolicy replayPolicy,
  }) {
    final items = <Object?>[];

    for (final part in message.parts) {
      if (part is ToolApprovalResponsePromptPart) {
        if (replayPolicy.store) {
          items.add(replayPolicy.itemReference(part.approvalId));
        }
        items.add({
          'type': 'mcp_approval_response',
          'approval_request_id': part.approvalId,
          'approve': part.approved,
        });
        continue;
      }

      if (part is! ToolResultPromptPart) {
        throw UnsupportedError(
          'Tool prompt part ${part.runtimeType} is not supported by the migrated Responses codec yet.',
        );
      }

      items.add({
        'type': 'function_call_output',
        'call_id': part.toolCallId,
        'output': toolCodec.encodeToolOutput(part.toolOutput),
      });
    }

    return items;
  }
}
