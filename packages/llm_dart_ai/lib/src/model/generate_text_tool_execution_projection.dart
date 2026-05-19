import 'package:llm_dart_provider/llm_dart_provider.dart' hide ToolResultEvent;

import '../stream/text_stream_event.dart';
import 'generate_text_runner_prompt_replay.dart';
import 'generate_text_step_result.dart';
import 'generate_text_tool_execution_contract.dart';

final class GenerateTextToolExecution {
  final ToolCallContent toolCall;
  final GenerateTextToolExecutionResult result;
  final ProviderMetadata? providerMetadata;

  const GenerateTextToolExecution({
    required this.toolCall,
    required this.result,
    this.providerMetadata,
  });

  ToolPromptMessage toPromptMessage() {
    return ToolPromptMessage(
      toolName: toolCall.toolName,
      parts: [
        ToolResultPromptPart(
          toolCallId: toolCall.toolCallId,
          toolName: toolCall.toolName,
          toolOutput: result.toolOutput,
          providerOptions: replayProviderOptions(providerMetadata),
        ),
      ],
    );
  }

  ToolResultEvent toTextStreamEvent() {
    return ToolResultEvent(
      toolResult: ToolResultContent(
        toolCallId: toolCall.toolCallId,
        toolName: toolCall.toolName,
        toolOutput: result.toolOutput,
        isDynamic: toolCall.isDynamic,
      ),
      providerMetadata: providerMetadata,
    );
  }
}

GenerateTextStepResult addToolExecutionsToStep(
  GenerateTextStepResult step,
  List<GenerateTextToolExecution> executions,
) {
  if (executions.isEmpty) {
    return step;
  }

  return GenerateTextStepResult(
    stepNumber: step.stepNumber,
    providerId: step.providerId,
    modelId: step.modelId,
    request: step.request,
    result: GenerateTextResult(
      content: [
        ...step.content,
        for (final execution in executions)
          ToolResultContentPart(
            ToolResultContent(
              toolCallId: execution.toolCall.toolCallId,
              toolName: execution.toolCall.toolName,
              toolOutput: execution.result.toolOutput,
              isDynamic: execution.toolCall.isDynamic,
            ),
            providerMetadata: execution.providerMetadata,
          ),
      ],
      finishReason: step.finishReason,
      rawFinishReason: step.rawFinishReason,
      responseMetadata: step.responseMetadata,
      usage: step.usage,
      providerMetadata: step.providerMetadata,
      warnings: step.warnings,
    ),
  );
}
