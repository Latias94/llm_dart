import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

Prompt promptFromChatMessages(List<ChatMessage> messages) {
  return Prompt(
    messages:
        messages.map(promptMessageFromChatMessage).toList(growable: false),
  );
}

PromptMessage promptMessageFromChatMessage(ChatMessage message) {
  final providerOptions = message.providerOptions;
  final parts = <PromptPart>[];

  PromptRole promptRoleForMessage() {
    if (message.messageType is ToolResultMessage) return PromptRole.tool;
    return switch (message.role) {
      ChatRole.system => PromptRole.system,
      ChatRole.user => PromptRole.user,
      ChatRole.assistant => PromptRole.assistant,
      ChatRole.tool => PromptRole.tool,
    };
  }

  void addTextIfPresent([String? text]) {
    final effective = text ?? '';
    if (effective.trim().isEmpty) return;
    parts.add(TextPart(effective));
  }

  // Protocol-internal: preserve Anthropic-compatible content blocks that must
  // be persisted across requests for tool loop continuity.
  final anthropic = message.getProtocolPayload('anthropic');
  if (anthropic is Map) {
    final contentBlocks = anthropic['contentBlocks'];
    if (contentBlocks is List) {
      for (final raw in contentBlocks) {
        if (raw is! Map) continue;
        final type = raw['type'];
        if (type is! String) continue;

        final cacheControl = raw['cache_control'];
        final blockProviderOptions = cacheControl is Map<String, dynamic>
            ? {
                'anthropic': {'cacheControl': cacheControl},
              }
            : const <String, Map<String, dynamic>>{};

        switch (type) {
          case 'text':
            final text = raw['text']?.toString() ?? '';
            if (text.trim().isEmpty) continue;
            parts.add(TextPart(text, providerOptions: blockProviderOptions));
            break;

          case 'tool_use':
            if (message.role != ChatRole.assistant) {
              throw const InvalidRequestError(
                'Anthropic tool_use blocks must be emitted from an assistant message.',
              );
            }
            final id = raw['id']?.toString() ?? '';
            final name = raw['name']?.toString() ?? '';
            final input = raw['input'];
            parts.add(
              ToolCallPart(
                toolCallId: id,
                toolName: name,
                input: input ?? const <String, dynamic>{},
                providerOptions: blockProviderOptions,
              ),
            );
            break;

          case 'tool_result':
            if (message.role != ChatRole.user &&
                message.role != ChatRole.tool) {
              throw const InvalidRequestError(
                'Anthropic tool_result blocks must be emitted from a user message.',
              );
            }
            final toolUseId = raw['tool_use_id']?.toString() ?? '';
            final content = raw['content']?.toString() ?? '';
            final isError = raw['is_error'];
            final toolResultProviderOptions = <String, Map<String, dynamic>>{
              ...blockProviderOptions,
              if (isError == true) 'anthropic': {'isError': true},
            };
            parts.add(
              ToolResultPart(
                toolUseId,
                '',
                ToolResultTextOutput(
                  content,
                  providerOptions: toolResultProviderOptions,
                ),
                overrideRole: PromptRole.tool,
                providerOptions: toolResultProviderOptions,
              ),
            );
            break;

          case 'thinking':
          case 'redacted_thinking':
            // Not part of the stable prompt surface; skip.
            break;

          case 'image':
            if (message.role == ChatRole.system) {
              throw const InvalidRequestError(
                'System messages cannot contain images.',
              );
            }
            final source = raw['source'];
            if (source is Map && source['type'] == 'base64') {
              final mediaType = source['media_type']?.toString() ?? '';
              final data = source['data']?.toString() ?? '';
              if (mediaType.isNotEmpty && data.isNotEmpty) {
                parts.add(
                  ImagePart(
                    mime: _imageMimeFromMediaType(mediaType),
                    data: base64Decode(data),
                    providerOptions: blockProviderOptions,
                  ),
                );
              }
            }
            break;

          case 'document':
            if (message.role == ChatRole.system) {
              throw const InvalidRequestError(
                'System messages cannot contain files.',
              );
            }
            final source = raw['source'];
            if (source is Map && source['type'] == 'base64') {
              final mediaType = source['media_type']?.toString() ?? '';
              final data = source['data']?.toString() ?? '';
              if (mediaType.isNotEmpty && data.isNotEmpty) {
                parts.add(
                  FilePart(
                    mime: FileMime(mediaType),
                    data: base64Decode(data),
                    providerOptions: blockProviderOptions,
                  ),
                );
              }
            }
            break;
        }
      }
    }
  }

  switch (message.messageType) {
    case TextMessage():
      if (parts.isEmpty) {
        addTextIfPresent(message.content);
      }

    case ImageMessage(mime: final mime, data: final data):
      if (message.role == ChatRole.system) {
        throw const InvalidRequestError(
          'System messages cannot contain images.',
        );
      }
      if (parts.isEmpty) {
        addTextIfPresent(message.content);
        parts.add(ImagePart(mime: mime, data: data));
      }

    case ImageUrlMessage(url: final url):
      if (message.role == ChatRole.system) {
        throw const InvalidRequestError(
          'System messages cannot contain image URLs.',
        );
      }
      if (parts.isEmpty) {
        addTextIfPresent(message.content);
        parts.add(ImageUrlPart(url: url));
      }

    case FileMessage(mime: final mime, data: final data):
      if (message.role == ChatRole.system) {
        throw const InvalidRequestError(
          'System messages cannot contain files.',
        );
      }
      if (parts.isEmpty) {
        addTextIfPresent(message.content);
        parts.add(FilePart(mime: mime, data: data));
      }

    case ToolUseMessage(toolCalls: final toolCalls):
      if (message.role != ChatRole.assistant) {
        throw const InvalidRequestError(
          'ToolUseMessage must be emitted from an assistant message.',
        );
      }
      if (parts.isEmpty) {
        addTextIfPresent(message.content);
        for (final toolCall in toolCalls) {
          parts.add(ToolCallPart.fromToolCall(toolCall));
        }
      }

    case ToolResultMessage(results: final results):
      if (message.role != ChatRole.user && message.role != ChatRole.tool) {
        throw const InvalidRequestError(
          'ToolResultMessage must be emitted from a tool message.',
        );
      }
      if (parts.isEmpty) {
        for (final toolResult in results) {
          parts.add(ToolResultPart.fromToolCall(toolResult));
        }
      }
  }

  if (parts.isEmpty) {
    throw InvalidRequestError(
      'Cannot convert empty ChatMessage (${message.role.name}) to PromptMessage.',
    );
  }

  return PromptMessage(
    role: promptRoleForMessage(),
    parts: List<PromptPart>.unmodifiable(parts),
    name: message.name,
    providerOptions: providerOptions,
    protocolPayloads: message.protocolPayloads,
  );
}

ImageMime _imageMimeFromMediaType(String mediaType) {
  switch (mediaType) {
    case 'image/jpeg':
      return ImageMime.jpeg;
    case 'image/png':
      return ImageMime.png;
    case 'image/gif':
      return ImageMime.gif;
    case 'image/webp':
      return ImageMime.webp;
    default:
      return ImageMime.jpeg;
  }
}
