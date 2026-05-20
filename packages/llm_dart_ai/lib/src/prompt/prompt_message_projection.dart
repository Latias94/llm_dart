import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'model_message.dart';

final class ModelMessagePromptProjector {
  const ModelMessagePromptProjector();

  Iterable<PromptMessage> project(ModelMessage message) {
    return switch (message) {
      SystemModelMessage() => [_projectSystemMessage(message)],
      UserModelMessage() => [_projectUserMessage(message)],
      AssistantModelMessage() => [_projectAssistantMessage(message)],
      ToolModelMessage() => _projectToolMessage(message),
    };
  }

  SystemPromptMessage _projectSystemMessage(SystemModelMessage message) {
    return SystemPromptMessage(
      parts: [
        TextPromptPart(
          message.content,
          providerOptions: message.providerOptions,
        ),
      ],
    );
  }

  UserPromptMessage _projectUserMessage(UserModelMessage message) {
    return UserPromptMessage(
      parts: [
        for (final part in message.parts)
          _projectUserPart(
            part,
            messageProviderOptions: message.providerOptions,
          ),
      ],
    );
  }

  AssistantPromptMessage _projectAssistantMessage(
    AssistantModelMessage message,
  ) {
    return AssistantPromptMessage(
      parts: [
        for (final part in message.parts)
          _projectAssistantPart(
            part,
            messageProviderOptions: message.providerOptions,
          ),
      ],
    );
  }

  Iterable<ToolPromptMessage> _projectToolMessage(ToolModelMessage message) {
    return [
      for (final part in message.parts)
        ToolPromptMessage(
          toolName: _toolPartName(part),
          parts: [
            _projectToolPart(
              part,
              messageProviderOptions: message.providerOptions,
            ),
          ],
        ),
    ];
  }

  PromptPart _projectUserPart(
    ModelPart part, {
    required ProviderPromptPartOptions? messageProviderOptions,
  }) {
    final providerOptions = _providerOptions(
      part,
      messageProviderOptions,
    );

    return switch (part) {
      TextModelPart(:final text) => TextPromptPart(
          text,
          providerOptions: providerOptions,
        ),
      FileModelPart(:final mediaType, :final filename, :final data) =>
        FilePromptPart(
          mediaType: mediaType,
          filename: filename,
          data: data,
          providerOptions: providerOptions,
        ),
      ImageModelPart(:final mediaType, :final data) => ImagePromptPart(
          mediaType: mediaType,
          data: data,
          providerOptions: providerOptions,
        ),
      _ => throw UnsupportedError(
          'User model messages only support text, file, and image parts. '
          'Received ${part.runtimeType}.',
        ),
    };
  }

  PromptPart _projectAssistantPart(
    ModelPart part, {
    required ProviderPromptPartOptions? messageProviderOptions,
  }) {
    final providerOptions = _providerOptions(
      part,
      messageProviderOptions,
    );

    return switch (part) {
      TextModelPart(:final text) => TextPromptPart(
          text,
          providerOptions: providerOptions,
        ),
      FileModelPart(:final mediaType, :final filename, :final data) =>
        FilePromptPart(
          mediaType: mediaType,
          filename: filename,
          data: data,
          providerOptions: providerOptions,
        ),
      ReasoningModelPart(:final text) => ReasoningPromptPart(
          text,
          providerOptions: providerOptions,
        ),
      ReasoningFileModelPart(
        :final mediaType,
        :final filename,
        :final data,
      ) =>
        ReasoningFilePromptPart(
          mediaType: mediaType,
          filename: filename,
          data: data,
          providerOptions: providerOptions,
        ),
      CustomModelPart(:final kind, :final data) => CustomPromptPart(
          kind: kind,
          data: data,
          providerOptions: providerOptions,
        ),
      ToolCallModelPart(
        :final toolCallId,
        :final toolName,
        :final input,
        :final providerExecuted,
        :final isDynamic,
        :final title,
      ) =>
        ToolCallPromptPart(
          toolCallId: toolCallId,
          toolName: toolName,
          input: input,
          providerExecuted: providerExecuted,
          isDynamic: isDynamic,
          title: title,
          providerOptions: providerOptions,
        ),
      ToolApprovalRequestModelPart(:final approvalId, :final toolCallId) =>
        ToolApprovalRequestPromptPart(
          approvalId: approvalId,
          toolCallId: toolCallId,
          providerOptions: providerOptions,
        ),
      ToolResultModelPart(
        :final toolCallId,
        :final toolName,
        :final toolOutput,
      ) =>
        ToolResultPromptPart(
          toolCallId: toolCallId,
          toolName: toolName,
          toolOutput: toolOutput,
          providerOptions: providerOptions,
        ),
      _ => throw UnsupportedError(
          'Assistant model messages do not support ${part.runtimeType} parts.',
        ),
    };
  }

  PromptPart _projectToolPart(
    ModelPart part, {
    required ProviderPromptPartOptions? messageProviderOptions,
  }) {
    final providerOptions = _providerOptions(
      part,
      messageProviderOptions,
    );

    return switch (part) {
      ToolResultModelPart(
        :final toolCallId,
        :final toolName,
        :final toolOutput,
      ) =>
        ToolResultPromptPart(
          toolCallId: toolCallId,
          toolName: toolName,
          toolOutput: toolOutput,
          providerOptions: providerOptions,
        ),
      ToolApprovalResponseModelPart(
        :final approvalId,
        :final toolCallId,
        :final approved,
        :final reason,
      ) =>
        ToolApprovalResponsePromptPart(
          approvalId: approvalId,
          toolCallId: toolCallId,
          approved: approved,
          reason: reason,
          providerOptions: providerOptions,
        ),
      _ => throw UnsupportedError(
          'Tool model messages only support tool result and approval response '
          'parts. Received ${part.runtimeType}.',
        ),
    };
  }

  String _toolPartName(ModelPart part) {
    return switch (part) {
      ToolResultModelPart(:final toolName) => toolName,
      ToolApprovalResponseModelPart(:final toolName) => toolName,
      _ => throw UnsupportedError(
          'Tool model messages only support tool result and approval response '
          'parts. Received ${part.runtimeType}.',
        ),
    };
  }

  ProviderPromptPartOptions? _providerOptions(
    ModelPart part,
    ProviderPromptPartOptions? messageProviderOptions,
  ) {
    return part.providerOptions ?? messageProviderOptions;
  }
}
