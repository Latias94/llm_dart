import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_output_content_projection.dart';
import 'openai_responses_stream_util.dart';
import 'openai_responses_tool_search_projection.dart';
import 'openai_responses_tool_content_projection.dart';

final class OpenAIResponsesResultContentProjection {
  final List<ContentPart> content;
  final List<Object?> logprobs;
  final bool hasToolCalls;

  const OpenAIResponsesResultContentProjection({
    required this.content,
    required this.logprobs,
    required this.hasToolCalls,
  });
}

OpenAIResponsesResultContentProjection projectOpenAIResponsesResultContent(
  Map<String, Object?> response,
) {
  final context = _OpenAIResponsesResultItemContext();

  for (final item in _openAIResponsesOutputItems(response)) {
    context.content.addAll(
      _projectOpenAIResponsesResultItem(item, context),
    );
  }

  return OpenAIResponsesResultContentProjection(
    content: context.content,
    logprobs: context.logprobs,
    hasToolCalls: context.hasToolCalls,
  );
}

Iterable<ContentPart> _projectOpenAIResponsesResultItem(
  Map<String, Object?> item,
  _OpenAIResponsesResultItemContext context,
) sync* {
  switch (openAIResponsesAsString(item['type'])) {
    case 'message':
      collectOpenAIResponsesMessageOutputLogprobs(
        item,
        into: context.logprobs,
      );
      yield* decodeOpenAIResponsesMessageOutput(item);

    case 'reasoning':
      yield* decodeOpenAIResponsesReasoningOutput(item);

    case 'function_call':
      context.hasToolCalls = true;
      final toolCall = decodeOpenAIResponsesFunctionCallOutput(item);
      if (toolCall != null) {
        yield toolCall;
      }

    case 'custom_tool_call':
      context.hasToolCalls = true;
      final toolCall = decodeOpenAIResponsesCustomToolCallOutput(item);
      if (toolCall != null) {
        yield toolCall;
        context.customToolNamesByCallId[toolCall.toolCall.toolCallId] =
            toolCall.toolCall.toolName;
      }

    case 'custom_tool_call_output':
      context.hasToolCalls = true;
      final toolCallId = openAIResponsesAsString(item['call_id']);
      final toolResult = decodeOpenAIResponsesCustomToolCallOutputItem(
        item,
        fallbackToolName: toolCallId == null
            ? null
            : context.customToolNamesByCallId[toolCallId],
      );
      if (toolResult != null) {
        yield toolResult;
      }

    case 'mcp_approval_request':
      context.hasToolCalls = true;
      yield* decodeOpenAIResponsesMcpApprovalRequestOutput(item);

    case 'mcp_call':
      context.hasToolCalls = true;
      yield* decodeOpenAIResponsesMcpCallOutput(item);

    case 'code_interpreter_call':
      context.hasToolCalls = true;
      yield* decodeOpenAIResponsesCodeInterpreterCallOutput(item);

    case 'image_generation_call':
      context.hasToolCalls = true;
      yield* decodeOpenAIResponsesImageGenerationCallOutput(item);

    case 'file_search_call':
      context.hasToolCalls = true;
      yield* decodeOpenAIResponsesFileSearchCallOutput(item);

    case 'web_search_call':
      context.hasToolCalls = true;
      yield* decodeOpenAIResponsesWebSearchCallOutput(item);

    case 'computer_call':
      context.hasToolCalls = true;
      yield* decodeOpenAIResponsesComputerUseCallOutput(item);

    case 'tool_search_call':
      context.hasToolCalls = true;
      final toolCall = decodeOpenAIResponsesToolSearchCallOutput(item);
      if (toolCall != null) {
        yield toolCall;
        if (toolCall.toolCall.providerExecuted) {
          context.hostedToolSearchCallIds.add(toolCall.toolCall.toolCallId);
        }
      }

    case 'tool_search_output':
      context.hasToolCalls = true;
      final toolResult = decodeOpenAIResponsesToolSearchOutput(
        item,
        fallbackToolCallId: openAIResponsesAsString(item['call_id']) == null
            ? openAIResponsesTakeHostedToolSearchCallId(
                context.hostedToolSearchCallIds,
              )
            : null,
      );
      if (toolResult != null) {
        yield toolResult;
      }

    case 'local_shell_call':
      context.hasToolCalls = true;
      final toolCall = decodeOpenAIResponsesLocalShellCallOutput(item);
      if (toolCall != null) {
        yield toolCall;
      }

    case 'local_shell_call_output':
      context.hasToolCalls = true;
      final toolResult = decodeOpenAIResponsesLocalShellCallOutputItem(item);
      if (toolResult != null) {
        yield toolResult;
      }

    case 'shell_call':
      context.hasToolCalls = true;
      final toolCall = decodeOpenAIResponsesShellCallOutput(item);
      if (toolCall != null) {
        yield toolCall;
      }

    case 'shell_call_output':
      context.hasToolCalls = true;
      final toolResult = decodeOpenAIResponsesShellCallOutputItem(item);
      if (toolResult != null) {
        yield toolResult;
      }

    case 'apply_patch_call':
      context.hasToolCalls = true;
      final toolCall = decodeOpenAIResponsesApplyPatchCallOutput(item);
      if (toolCall != null) {
        yield toolCall;
      }

    case 'apply_patch_call_output':
      context.hasToolCalls = true;
      final toolResult = decodeOpenAIResponsesApplyPatchCallOutputItem(item);
      if (toolResult != null) {
        yield toolResult;
      }

    default:
      final customPart = decodeOpenAIResponsesCustomOutput(item);
      if (customPart != null) {
        yield customPart;
      }
  }
}

List<Map<String, Object?>> _openAIResponsesOutputItems(
  Map<String, Object?> response,
) {
  final output = openAIResponsesAsList(response['output']);
  final items = <Map<String, Object?>>[];

  for (final rawItem in output) {
    final item = openAIResponsesAsMap(rawItem);
    if (item != null) {
      items.add(item);
    }
  }

  return items;
}

final class _OpenAIResponsesResultItemContext {
  final List<ContentPart> content = [];
  final List<Object?> logprobs = [];
  final List<String> hostedToolSearchCallIds = [];
  final Map<String, String> customToolNamesByCallId = {};
  bool hasToolCalls = false;
}
