import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_custom_tool_replay_projection.dart';
import 'openai_responses_native_tool_context.dart';
import 'openai_responses_prompt_limitations.dart';
import 'openai_responses_replay_policy.dart';
import 'openai_responses_request_tool_codec.dart';
import 'openai_responses_shell_replay_projection.dart';
import 'openai_responses_tool_search_replay_projection.dart';

final class OpenAIResponsesToolPromptProjection {
  final OpenAIResponsesRequestToolCodec toolCodec;

  const OpenAIResponsesToolPromptProjection({
    this.toolCodec = const OpenAIResponsesRequestToolCodec(),
  });

  List<Object?> encode(
    ToolPromptMessage message, {
    required OpenAIResponsesReplayPolicy replayPolicy,
    OpenAIResponsesNativeToolContext nativeToolContext =
        OpenAIResponsesNativeToolContext.empty,
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
        throw unsupportedOpenAIResponsesPromptPart(
          role: 'tool',
          part: part,
        );
      }

      final customToolOutput = projectOpenAIResponsesCustomToolReplayOutput(
        part,
        isCustomToolName: nativeToolContext.isCustomToolName,
        toolOutputProjection: toolCodec.toolOutputProjection,
      );
      if (customToolOutput != null) {
        items.add(customToolOutput.inputItem);
        continue;
      }

      if (!part.isError) {
        final toolSearchOutput = projectOpenAIResponsesToolSearchReplayOutput(
          part,
          metadata: null,
        );
        if (toolSearchOutput != null) {
          items.add(toolSearchOutput.toInputItem());
          continue;
        }
      }

      if (nativeToolContext.hasLocalShell) {
        final localShellOutput =
            projectOpenAIResponsesLocalShellReplayOutput(part);
        if (localShellOutput != null) {
          items.add(localShellOutput.inputItem);
          continue;
        }
      }

      if (nativeToolContext.hasShell) {
        final shellOutput = projectOpenAIResponsesShellReplayOutput(part);
        if (shellOutput != null) {
          items.add(shellOutput.inputItem);
          continue;
        }
      }

      if (nativeToolContext.hasApplyPatch) {
        final applyPatchOutput =
            projectOpenAIResponsesApplyPatchReplayOutput(part);
        if (applyPatchOutput != null) {
          items.add(applyPatchOutput.inputItem);
          continue;
        }
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
