import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'generate_text_step_result.dart';

ProviderMetadata? toolCallProviderMetadata(
  GenerateTextStepResult step,
  String toolCallId,
) {
  for (final part in step.result.content.whereType<ToolCallContentPart>()) {
    if (part.toolCall.toolCallId == toolCallId) {
      return part.providerMetadata;
    }
  }

  return null;
}

ProviderReplayPromptPartOptions? replayProviderOptions(
  ProviderMetadata? metadata,
) {
  return ProviderReplayPromptPartOptions.fromMetadata(metadata);
}

List<PromptMessage> stepToPromptMessages(
  GenerateTextStepResult step, {
  required String runnerName,
}) {
  final prompt = <PromptMessage>[];
  final assistantParts = <PromptPart>[];

  void flushAssistantParts() {
    if (assistantParts.isEmpty) {
      return;
    }

    prompt.add(
      AssistantPromptMessage(
        parts: List<PromptPart>.from(assistantParts),
      ),
    );
    assistantParts.clear();
  }

  for (final part in step.content) {
    switch (part) {
      case TextContentPart(
            :final text,
            :final providerMetadata,
          )
          when text.isNotEmpty || providerMetadata != null:
        assistantParts.add(
          TextPromptPart(
            text,
            providerOptions: replayProviderOptions(providerMetadata),
          ),
        );
      case ReasoningContentPart(
            :final text,
            :final providerMetadata,
          )
          when text.isNotEmpty || providerMetadata != null:
        assistantParts.add(
          ReasoningPromptPart(
            text,
            providerOptions: replayProviderOptions(providerMetadata),
          ),
        );
      case FileContentPart(
          :final file,
          :final providerMetadata,
        ):
        assistantParts.add(
          FilePromptPart(
            mediaType: file.mediaType,
            filename: file.filename,
            data: file.data,
            providerOptions: replayProviderOptions(providerMetadata),
          ),
        );
      case ReasoningFileContentPart(
          :final file,
          :final providerMetadata,
        ):
        assistantParts.add(
          ReasoningFilePromptPart(
            mediaType: file.mediaType,
            filename: file.filename,
            data: file.data,
            providerOptions: replayProviderOptions(providerMetadata),
          ),
        );
      case CustomContentPart(
          :final kind,
          :final data,
          :final providerMetadata,
        ):
        assistantParts.add(
          CustomPromptPart(
            kind: kind,
            data: data,
            providerOptions: replayProviderOptions(providerMetadata),
          ),
        );
      case ToolCallContentPart(
          :final toolCall,
          :final providerMetadata,
        ):
        assistantParts.add(
          ToolCallPromptPart(
            toolCallId: toolCall.toolCallId,
            toolName: toolCall.toolName,
            input: toolCall.input,
            providerExecuted: toolCall.providerExecuted,
            isDynamic: toolCall.isDynamic,
            title: toolCall.title,
            providerOptions: replayProviderOptions(providerMetadata),
          ),
        );
      case ToolApprovalRequestContentPart(
          :final approvalRequest,
          :final providerMetadata,
        ):
        assistantParts.add(
          ToolApprovalRequestPromptPart(
            approvalId: approvalRequest.approvalId,
            toolCallId: approvalRequest.toolCallId,
            providerOptions: replayProviderOptions(providerMetadata),
          ),
        );
      case ToolResultContentPart(
          :final toolResult,
          :final providerMetadata,
        ):
        flushAssistantParts();
        prompt.add(
          ToolPromptMessage(
            toolName: toolResult.toolName,
            parts: [
              ToolResultPromptPart(
                toolCallId: toolResult.toolCallId,
                toolName: toolResult.toolName,
                toolOutput: toolResult.toolOutput,
                providerOptions: replayProviderOptions(providerMetadata),
              ),
            ],
          ),
        );
      case SourceContentPart():
        break;
      case _:
        throw UnsupportedError(
          '$runnerName prompt replay does not support '
          '${part.runtimeType} parts.',
        );
    }
  }

  flushAssistantParts();
  return prompt;
}
