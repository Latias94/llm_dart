import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_request_encoding_util.dart';
import 'openai_responses_custom_tool_replay_projection.dart';
import 'openai_responses_native_tool_context.dart';
import 'openai_responses_prompt_limitations.dart';
import 'openai_responses_replay_policy.dart';
import 'openai_responses_shell_replay_projection.dart';
import 'openai_responses_tool_search_replay_projection.dart';

final class OpenAIResponsesAssistantToolReplayProjection {
  const OpenAIResponsesAssistantToolReplayProjection();

  void encodeToolCall(
    ToolCallPromptPart part,
    List<Object?> items, {
    required OpenAIResponsesReplayPolicy replayPolicy,
    OpenAIResponsesNativeToolContext nativeToolContext =
        OpenAIResponsesNativeToolContext.empty,
  }) {
    final metadata = openAIPromptPartProviderMetadata(part)?.namespace(
      'openai',
    );
    final itemId = openAIRequestAsString(metadata?['itemId']);

    if (replayPolicy.shouldSkipStoredItem(itemId)) {
      return;
    }

    if (replayPolicy.shouldReferenceStoredItem(itemId)) {
      items.add(replayPolicy.itemReference(itemId!));
      return;
    }

    final toolSearchCall = projectOpenAIResponsesToolSearchReplayCall(
      part,
      metadata: metadata,
    );
    if (toolSearchCall != null) {
      items.add(toolSearchCall.toInputItem());
      return;
    }

    final customToolCall = projectOpenAIResponsesCustomToolReplayCall(
      part,
      isCustomToolName: nativeToolContext.isCustomToolName,
    );
    if (customToolCall != null) {
      items.add(customToolCall.inputItem);
      return;
    }

    if (nativeToolContext.hasLocalShell) {
      final localShellCall = projectOpenAIResponsesLocalShellReplayCall(part);
      if (localShellCall != null) {
        items.add(localShellCall.inputItem);
        return;
      }
    }

    if (nativeToolContext.hasShell) {
      final shellCall = projectOpenAIResponsesShellReplayCall(part);
      if (shellCall != null) {
        items.add(shellCall.inputItem);
        return;
      }
    }

    if (nativeToolContext.hasApplyPatch) {
      final applyPatchCall = projectOpenAIResponsesApplyPatchReplayCall(part);
      if (applyPatchCall != null) {
        items.add(applyPatchCall.inputItem);
        return;
      }
    }

    if (part.providerExecuted) {
      return;
    }

    items.add({
      'type': 'function_call',
      'call_id': part.toolCallId,
      if (itemId != null) 'id': itemId,
      'name': part.toolName,
      'arguments': encodeOpenAIJsonString(part.input),
    });
  }

  void encodeToolResult(
    ToolResultPromptPart part,
    List<Object?> items,
    List<ModelWarning> warnings, {
    required OpenAIResponsesReplayPolicy replayPolicy,
    OpenAIResponsesNativeToolContext nativeToolContext =
        OpenAIResponsesNativeToolContext.empty,
  }) {
    if (replayPolicy.hasConversation) {
      return;
    }

    final metadata = openAIPromptPartProviderMetadata(part)?.namespace(
      'openai',
    );
    final itemId =
        openAIRequestAsString(metadata?['itemId']) ?? part.toolCallId;

    if (nativeToolContext.hasLocalShell) {
      final localShellOutput =
          projectOpenAIResponsesLocalShellReplayOutput(part);
      if (localShellOutput != null) {
        items.add(localShellOutput.inputItem);
        return;
      }
    }

    if (nativeToolContext.hasShell) {
      final shellOutput = projectOpenAIResponsesShellReplayOutput(part);
      if (shellOutput != null) {
        items.add(shellOutput.inputItem);
        return;
      }
    }

    if (nativeToolContext.hasApplyPatch) {
      final applyPatchOutput =
          projectOpenAIResponsesApplyPatchReplayOutput(part);
      if (applyPatchOutput != null) {
        items.add(applyPatchOutput.inputItem);
        return;
      }
    }

    if (replayPolicy.store) {
      items.add(replayPolicy.itemReference(itemId));
      return;
    }

    final toolSearchOutput = projectOpenAIResponsesToolSearchReplayOutput(
      part,
      metadata: metadata,
    );
    if (toolSearchOutput != null) {
      items.add(toolSearchOutput.toInputItem());
      return;
    }

    final customToolOutput = projectOpenAIResponsesCustomToolReplayOutput(
      part,
      isCustomToolName: nativeToolContext.isCustomToolName,
    );
    if (customToolOutput != null) {
      items.add(customToolOutput.inputItem);
      return;
    }

    warnings.add(openAIResponsesToolResultStoreFalseWarning(part.toolName));
  }
}
