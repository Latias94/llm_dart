part of 'legacy_chat_adapter.dart';

List<core.PromptMessage> _convertLegacyMessages({
  required LLMConfig config,
  required List<ChatMessage> messages,
  required List<core.PromptMessage> Function(ChatMessage message)
      convertMessage,
}) {
  final prompt = <core.PromptMessage>[];
  final hasSystemMessage =
      messages.any((message) => message.role == ChatRole.system);

  if (!hasSystemMessage &&
      config.systemPrompt != null &&
      config.systemPrompt!.isNotEmpty) {
    prompt.add(core.SystemPromptMessage.text(config.systemPrompt!));
  }

  for (final message in messages) {
    prompt.addAll(convertMessage(message));
  }

  return prompt;
}

List<core.PromptMessage> _convertLegacyMessage(ChatMessage message) {
  final metadata = _messageMetadata(message);
  final textPart = _buildTextPart(message.content, metadata);

  switch (message.messageType) {
    case TextMessage():
      return [_buildTextPromptMessage(message.role, textPart)];
    case ImageMessage(:final mime, :final data):
      return [
        _buildMediaPromptMessage(
          role: message.role,
          textPart: textPart,
          part: core.ImagePromptPart(
            mediaType: mime.mimeType,
            data: core.FileBytesData(data),
            providerMetadata: metadata,
          ),
        ),
      ];
    case ImageUrlMessage(:final url):
      return [
        _buildMediaPromptMessage(
          role: message.role,
          textPart: textPart,
          part: core.ImagePromptPart(
            mediaType: 'image/*',
            data: core.FileUrlData(Uri.parse(url)),
            providerMetadata: metadata,
          ),
        ),
      ];
    case FileMessage(:final mime, :final data):
      return [
        _buildMediaPromptMessage(
          role: message.role,
          textPart: textPart,
          part: core.FilePromptPart(
            mediaType: mime.mimeType,
            data: core.FileBytesData(data),
            providerMetadata: metadata,
          ),
        ),
      ];
    case ToolUseMessage(:final toolCalls):
      final parts = <core.PromptPart>[
        if (textPart != null) textPart,
        for (final toolCall in toolCalls)
          core.ToolCallPromptPart(
            toolCallId: toolCall.id,
            toolName: toolCall.function.name,
            input: _decodeJsonValue(toolCall.function.arguments),
            providerMetadata: metadata,
          ),
      ];
      return [
        core.AssistantPromptMessage(parts: parts),
      ];
    case ToolResultMessage(:final results):
      return [
        for (final result in results)
          core.ToolPromptMessage(
            toolName: result.function.name,
            parts: [
              core.ToolResultPromptPart(
                toolCallId: result.id,
                toolName: result.function.name,
                output: _decodeToolResultOutput(
                  encodedOutput: result.function.arguments,
                  fallbackText: message.content,
                ),
                providerMetadata: metadata,
              ),
            ],
          ),
      ];
  }
}

core.PromptMessage _buildTextPromptMessage(
  ChatRole role,
  core.TextPromptPart? textPart,
) {
  final parts = [
    if (textPart != null) textPart,
  ];

  return switch (role) {
    ChatRole.system => core.SystemPromptMessage(parts: parts),
    ChatRole.user => core.UserPromptMessage(parts: parts),
    ChatRole.assistant => core.AssistantPromptMessage(parts: parts),
  };
}

core.PromptMessage _buildMediaPromptMessage({
  required ChatRole role,
  required core.TextPromptPart? textPart,
  required core.PromptPart part,
}) {
  final parts = <core.PromptPart>[
    if (textPart != null) textPart,
    part,
  ];

  return switch (role) {
    ChatRole.system => core.SystemPromptMessage(parts: parts),
    ChatRole.user => core.UserPromptMessage(parts: parts),
    ChatRole.assistant => core.AssistantPromptMessage(parts: parts),
  };
}

core.TextPromptPart? _buildTextPart(
  String content,
  core.ProviderMetadata? metadata,
) {
  if (content.isEmpty) {
    return null;
  }

  return core.TextPromptPart(
    content,
    providerMetadata: metadata,
  );
}

core.ProviderMetadata? _messageMetadata(ChatMessage message) {
  if (message.extensions.isEmpty) {
    return null;
  }

  return core.ProviderMetadata(_normalizeMap(message.extensions));
}
