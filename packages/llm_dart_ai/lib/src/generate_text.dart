import 'package:llm_dart_core/llm_dart_core.dart';

import 'call_options_dispatch.dart';
import 'prompt_input.dart';
import 'content_part_builders.dart';
import 'metadata_fallbacks.dart';
import 'response_messages.dart';
import 'tool_loop.dart';
import 'tool_set.dart';
import 'tool_types.dart';
import 'types.dart';
import 'openai_tool_control.dart';
import 'provider_tool_normalization.dart';

/// Generate text (Vercel-style prompt input).
///
/// Provide exactly one of:
/// - [prompt] (plain text prompt)
/// - [messages] (legacy chat message model)
/// - [promptIr] (Prompt IR)
///
/// You can also pass [system] alongside any of them.
Future<GenerateTextResult> generateText({
  required ChatCapability model,
  String? system,
  String? prompt,
  List<ChatMessage>? messages,
  Prompt? promptIr,
  ToolSet? toolSet,
  ToolChoice? toolChoice,
  bool? parallelToolCalls,
  List<ProviderTool>? providerTools,
  List<Tool>? tools,
  ToolCallRepair? repairToolCall,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  GenerateTextOnStepFinishCallback? onStepFinish,
  GenerateTextOnFinishCallback? onFinish,
  IncludeOptions include = const IncludeOptions(),
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
  IdGenerator? generateId,
}) async {
  final startedAt = DateTime.now().toUtc();
  final defaultModelId = model is ModelIdentityCapability
      ? (model as ModelIdentityCapability).modelId
      : null;
  final input = standardizePromptInput(
    system: system,
    prompt: prompt,
    messages: messages,
    promptIr: promptIr,
  );

  final effectiveCallOptions = applyOpenAIToolControlsToCallOptions(
    defaultCallOptions.mergedWith(callOptions),
    toolChoice: toolChoice,
    parallelToolCalls: parallelToolCalls,
  );

  UsageInfo? sumUsage(Iterable<UsageInfo?> usages) {
    UsageInfo? acc;
    for (final u in usages) {
      if (u == null) continue;
      acc = acc == null ? u : (acc + u);
    }
    return acc;
  }

  Future<void> runCallbacksBestEffort(
    List<ToolLoopStep> steps,
    GenerateTextResult result,
  ) async {
    final stepCallback = onStepFinish;
    if (stepCallback != null) {
      for (final step in steps) {
        try {
          await Future.sync(() => stepCallback(step));
        } catch (_) {}
      }
    }

    final finishCallback = onFinish;
    if (finishCallback != null) {
      final event = GenerateTextFinishEvent(
        result: result,
        steps: steps,
        totalUsage: result.totalUsage,
      );
      try {
        await Future.sync(() => finishCallback(event));
      } catch (_) {}
    }
  }

  if (toolSet != null) {
    final loop = await runToolLoopWithToolSet(
      model: model,
      system: system,
      prompt: prompt,
      messages: messages,
      promptIr: promptIr,
      toolSet: toolSet,
      providerTools: providerTools,
      repairToolCall: repairToolCall,
      needsApproval: needsApproval,
      maxSteps: maxSteps,
      continueOnToolError: continueOnToolError,
      include: include,
      defaultCallOptions: const LLMCallOptions(),
      callOptions: effectiveCallOptions,
      cancelToken: cancelToken,
      generateId: generateId,
    );

    final steps = loop.steps;
    final finalResult = loop.finalResult;
    final totalUsage = sumUsage(steps.map((s) => s.result.usage));

    final wrapped = GenerateTextResult(
      rawResponse: finalResult.rawResponse,
      content: finalResult.content,
      text: finalResult.text,
      thinking: finalResult.thinking,
      toolCalls: finalResult.toolCalls,
      toolResults: steps.isNotEmpty ? steps.last.toolResults : const [],
      usage: finalResult.usage,
      totalUsage: totalUsage ?? finalResult.usage,
      finishReason: finalResult.finishReason,
      warnings: finalResult.warnings,
      requestMetadata: finalResult.requestMetadata,
      responseMetadata: finalResult.responseMetadata,
      responseMessages: finalResult.responseMessages,
      responsePromptMessages: finalResult.responsePromptMessages,
      steps: steps,
      sources: finalResult.sources,
      files: finalResult.files,
    );

    await runCallbacksBestEffort(steps, wrapped);
    return wrapped;
  }

  final normalized = normalizeProviderToolsAndCollectWarnings(
    model: model,
    providerTools: providerTools,
  );

  final response = await chatWithToolsBestEffort(
    model: model,
    input: input,
    tools: tools,
    providerTools: normalized.providerTools,
    callOptions: effectiveCallOptions,
    cancelToken: cancelToken,
  );

  final toolCalls = response.toolCalls ?? const <ToolCall>[];
  final providerWarnings = response is ChatResponseWithWarnings
      ? response.warnings
      : const <LLMWarning>[];
  final warnings = normalized.warnings.isEmpty
      ? providerWarnings
      : (providerWarnings.isEmpty
          ? normalized.warnings
          : List<LLMWarning>.unmodifiable([
              ...normalized.warnings,
              ...providerWarnings,
            ]));
  final result = GenerateTextResult(
    rawResponse: response,
    content: buildContentPartsBestEffort(
      text: response.text,
      thinking: response.thinking,
      toolCalls: toolCalls,
      toolResults: const <ToolResult>[],
    ),
    text: response.text,
    thinking: response.thinking,
    toolCalls: response.toolCalls,
    usage: response.usage,
    totalUsage: response.usage,
    finishReason:
        response is ChatResponseWithFinishReason ? response.finishReason : null,
    warnings: warnings,
    requestMetadata: requestMetadataWithInclude(
      response is ChatResponseWithRequestMetadata
          ? response.requestMetadata
          : null,
      include,
    ),
    responseMetadata: responseMetadataWithInclude(
      responseMetadataWithDefaults(
        response is ChatResponseWithResponseMetadata
            ? response.responseMetadata
            : null,
        startedAt,
        defaultModelId: defaultModelId,
      ),
      include,
    ),
    responseMessages: buildResponseMessagesBestEffort(response),
    responsePromptMessages: buildResponsePromptMessagesBestEffort(response),
    steps: [
      ToolLoopStep(
        index: 0,
        result: GenerateTextResult(
          rawResponse: response,
          content: buildContentPartsBestEffort(
            text: response.text,
            thinking: response.thinking,
            toolCalls: toolCalls,
            toolResults: const <ToolResult>[],
          ),
          text: response.text,
          thinking: response.thinking,
          toolCalls: response.toolCalls,
          toolResults: const <ToolResult>[],
          usage: response.usage,
          finishReason: response is ChatResponseWithFinishReason
              ? response.finishReason
              : null,
          warnings: warnings,
          requestMetadata: requestMetadataWithInclude(
            response is ChatResponseWithRequestMetadata
                ? response.requestMetadata
                : null,
            include,
          ),
          responseMetadata: responseMetadataWithInclude(
            responseMetadataWithDefaults(
              response is ChatResponseWithResponseMetadata
                  ? response.responseMetadata
                  : null,
              startedAt,
              defaultModelId: defaultModelId,
            ),
            include,
          ),
          responseMessages: buildResponseMessagesBestEffort(response),
          responsePromptMessages:
              buildResponsePromptMessagesBestEffort(response),
        ),
        toolCalls: toolCalls,
        toolResults: const <ToolResult>[],
        responseMetadata: responseMetadataWithInclude(
          responseMetadataWithDefaults(
            response is ChatResponseWithResponseMetadata
                ? response.responseMetadata
                : null,
            startedAt,
            defaultModelId: defaultModelId,
          ),
          include,
        ),
        requestMetadata: requestMetadataWithInclude(
          response is ChatResponseWithRequestMetadata
              ? response.requestMetadata
              : null,
          include,
        ),
        responsePromptMessages: buildResponsePromptMessagesBestEffort(response),
      ),
    ],
  );

  await runCallbacksBestEffort(result.steps, result);
  return result;
}
