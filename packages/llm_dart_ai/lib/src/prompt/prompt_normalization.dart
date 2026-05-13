import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'model_message.dart';
import 'prompt_validation.dart';

List<PromptMessage> normalizeModelMessages(List<ModelMessage> messages) {
  final prompt = <PromptMessage>[];

  for (final message in messages) {
    switch (message) {
      case SystemModelMessage():
        prompt.add(_normalizeSystemMessage(message));
      case UserModelMessage():
        prompt.add(_normalizeUserMessage(message));
      case AssistantModelMessage():
        prompt.add(_normalizeAssistantMessage(message));
      case ToolModelMessage():
        prompt.addAll(_normalizeToolMessage(message));
    }
  }

  final normalized = List<PromptMessage>.unmodifiable(prompt);
  validateProviderPrompt(
    normalized,
    context: 'normalizeModelMessages.messages',
  );
  return normalized;
}

List<PromptMessage> resolveProviderPrompt({
  List<PromptMessage>? prompt,
  List<ModelMessage>? messages,
}) {
  if (prompt != null && messages != null) {
    throw ArgumentError(
      'Provide either provider-facing prompt or user-facing messages, not both.',
    );
  }

  if (messages != null) {
    return normalizeModelMessages(messages);
  }

  if (prompt != null) {
    return List<PromptMessage>.unmodifiable(prompt);
  }

  throw ArgumentError(
    'Provide either provider-facing prompt or user-facing messages.',
  );
}

SystemPromptMessage _normalizeSystemMessage(SystemModelMessage message) {
  return SystemPromptMessage(
    parts: [
      TextPromptPart(
        message.content,
        providerOptions: message.providerOptions,
      ),
    ],
  );
}

UserPromptMessage _normalizeUserMessage(UserModelMessage message) {
  return UserPromptMessage(
    parts: [
      for (final part in message.parts)
        _normalizeUserPart(
          part,
          messageProviderOptions: message.providerOptions,
        ),
    ],
  );
}

AssistantPromptMessage _normalizeAssistantMessage(
  AssistantModelMessage message,
) {
  return AssistantPromptMessage(
    parts: [
      for (final part in message.parts)
        _normalizeAssistantPart(
          part,
          messageProviderOptions: message.providerOptions,
        ),
    ],
  );
}

List<ToolPromptMessage> _normalizeToolMessage(ToolModelMessage message) {
  return [
    for (final part in message.parts)
      ToolPromptMessage(
        toolName: _toolPartName(part),
        parts: [
          _normalizeToolPart(
            part,
            messageProviderOptions: message.providerOptions,
          ),
        ],
      ),
  ];
}

PromptPart _normalizeUserPart(
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

PromptPart _normalizeAssistantPart(
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

PromptPart _normalizeToolPart(
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
