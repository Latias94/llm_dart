import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'prompt_tool_state_validation.dart';
import 'prompt_validation_error.dart';

void validateProviderPrompt(
  List<PromptMessage> prompt, {
  String context = 'prompt',
}) {
  final validator = _ProviderPromptValidator(context);
  validator.validate(prompt);
}

final class _ProviderPromptValidator {
  final String context;
  late final PromptToolStateValidator _toolState =
      PromptToolStateValidator(context);
  var _hasNonSystemMessage = false;

  _ProviderPromptValidator(this.context);

  void validate(List<PromptMessage> prompt) {
    for (var messageIndex = 0; messageIndex < prompt.length; messageIndex++) {
      final message = prompt[messageIndex];
      switch (message) {
        case SystemPromptMessage():
          _validateSystemMessage(messageIndex);
        case UserPromptMessage():
          _validateUserMessage(messageIndex);
        case AssistantPromptMessage(:final parts):
          _validateAssistantMessage(messageIndex, parts);
        case ToolPromptMessage(:final toolName, :final parts):
          _validateToolMessage(messageIndex, toolName, parts);
      }
    }

    _toolState.requireNoPendingAtEnd();
  }

  void _validateSystemMessage(int messageIndex) {
    if (_hasNonSystemMessage) {
      throwPromptValidationError(
        context: context,
        messageIndex: messageIndex,
        partIndex: null,
        message:
            'system messages must appear before user, assistant, or tool messages.',
      );
    }
  }

  void _validateUserMessage(int messageIndex) {
    _hasNonSystemMessage = true;
    _toolState.requireNoPendingBeforeNextConversationMessage(
      messageIndex,
      'user message',
    );
  }

  void _validateAssistantMessage(
    int messageIndex,
    List<PromptPart> parts,
  ) {
    _hasNonSystemMessage = true;
    _toolState.requireNoPendingBeforeNextConversationMessage(
      messageIndex,
      'assistant message',
    );

    for (var partIndex = 0; partIndex < parts.length; partIndex++) {
      final part = parts[partIndex];
      switch (part) {
        case ToolCallPromptPart():
          _toolState.recordToolCall(
            part,
            messageIndex: messageIndex,
            partIndex: partIndex,
          );
        case ToolApprovalRequestPromptPart():
          _toolState.recordApprovalRequest(
            part,
            messageIndex: messageIndex,
            partIndex: partIndex,
          );
        case ToolResultPromptPart():
          _toolState.validateAssistantToolResult(
            part,
            messageIndex: messageIndex,
            partIndex: partIndex,
          );
        case ToolApprovalResponsePromptPart():
          throwPromptValidationError(
            context: context,
            messageIndex: messageIndex,
            partIndex: partIndex,
            message:
                'tool approval responses must be placed in a tool message.',
          );
        case TextPromptPart() ||
              FilePromptPart() ||
              ImagePromptPart() ||
              ReasoningPromptPart() ||
              ReasoningFilePromptPart() ||
              CustomPromptPart():
          break;
      }
    }
  }

  void _validateToolMessage(
    int messageIndex,
    String toolName,
    List<PromptPart> parts,
  ) {
    _hasNonSystemMessage = true;

    for (var partIndex = 0; partIndex < parts.length; partIndex++) {
      final part = parts[partIndex];
      switch (part) {
        case ToolResultPromptPart():
          _toolState.consumeToolResult(
            part,
            messageToolName: toolName,
            messageIndex: messageIndex,
            partIndex: partIndex,
          );
        case ToolApprovalResponsePromptPart():
          _toolState.consumeApprovalResponse(
            part,
            messageIndex: messageIndex,
            partIndex: partIndex,
          );
        case CustomPromptPart():
          break;
        case TextPromptPart() ||
              FilePromptPart() ||
              ImagePromptPart() ||
              ReasoningPromptPart() ||
              ReasoningFilePromptPart() ||
              ToolCallPromptPart() ||
              ToolApprovalRequestPromptPart():
          throwPromptValidationError(
            context: context,
            messageIndex: messageIndex,
            partIndex: partIndex,
            message:
                'tool messages only support tool results, approval responses, '
                'or provider-native custom replay parts.',
          );
      }
    }
  }
}
