part of 'anthropic_compat_support.dart';

final class _AnthropicCompatMessageConverter {
  const _AnthropicCompatMessageConverter();

  List<core.PromptMessage> convertMessages({
    required List<ChatMessage> messages,
    required String? systemPrompt,
    required List<core.PromptMessage> Function(ChatMessage message)
        convertTrackedMessage,
  }) {
    final prompt = <core.PromptMessage>[];
    final toolDescriptors = <String, _AnthropicCompatToolDescriptor>{};
    final hasSystemMessage =
        messages.any((message) => message.role == ChatRole.system);

    if (!hasSystemMessage && systemPrompt != null && systemPrompt.isNotEmpty) {
      prompt.add(core.SystemPromptMessage.text(systemPrompt));
    }

    for (var index = 0; index < messages.length; index++) {
      final message = messages[index];
      if (!message.extensions.containsKey('anthropic')) {
        prompt.addAll(
          _convertTrackedLegacyMessage(
            message,
            toolDescriptors: toolDescriptors,
            convertTrackedMessage: convertTrackedMessage,
          ),
        );
        continue;
      }

      prompt.addAll(
        _convertAnthropicLegacyMessage(
          message,
          messageIndex: index,
          toolDescriptors: toolDescriptors,
        ),
      );
    }

    return prompt;
  }

  List<core.PromptMessage> _convertAnthropicLegacyMessage(
    ChatMessage message, {
    required int messageIndex,
    required Map<String, _AnthropicCompatToolDescriptor> toolDescriptors,
  }) {
    final analysis = analyzeAnthropicLegacyMessage(
      message,
      messageIndex: messageIndex,
    );

    final blocks = <AnthropicLegacyPromptBlock>[
      ...analysis.promptBlocks,
      if (message.content.isNotEmpty)
        AnthropicLegacyTextBlock(
          text: message.content,
          cacheControl: analysis.cacheControl,
        ),
    ];

    return switch (message.role) {
      ChatRole.system => _convertSystemMessage(blocks),
      ChatRole.assistant => _convertAssistantMessage(
          blocks,
          toolDescriptors: toolDescriptors,
        ),
      ChatRole.user => _convertUserMessage(
          blocks,
          toolDescriptors: toolDescriptors,
        ),
    };
  }

  List<core.PromptMessage> _convertTrackedLegacyMessage(
    ChatMessage message, {
    required Map<String, _AnthropicCompatToolDescriptor> toolDescriptors,
    required List<core.PromptMessage> Function(ChatMessage message)
        convertTrackedMessage,
  }) {
    final converted = convertTrackedMessage(message);

    if (message.messageType case ToolUseMessage(:final toolCalls)) {
      for (final toolCall in toolCalls) {
        toolDescriptors[toolCall.id] = _AnthropicCompatToolDescriptor(
          toolName: toolCall.function.name,
        );
      }
    }

    return converted;
  }

  List<core.PromptMessage> _convertSystemMessage(
    List<AnthropicLegacyPromptBlock> blocks,
  ) {
    if (blocks.isEmpty) {
      return const [];
    }

    return [
      core.SystemPromptMessage(
        parts: [
          for (final block in blocks) _convertPromptPart(block),
        ],
      ),
    ];
  }

  List<core.PromptMessage> _convertAssistantMessage(
    List<AnthropicLegacyPromptBlock> blocks, {
    required Map<String, _AnthropicCompatToolDescriptor> toolDescriptors,
  }) {
    if (blocks.isEmpty) {
      return const [];
    }

    final parts = <core.PromptPart>[
      for (final block in blocks)
        _convertAssistantPromptPart(
          block,
          toolDescriptors: toolDescriptors,
        ),
    ];

    return [
      core.AssistantPromptMessage(parts: parts),
    ];
  }

  List<core.PromptMessage> _convertUserMessage(
    List<AnthropicLegacyPromptBlock> blocks, {
    required Map<String, _AnthropicCompatToolDescriptor> toolDescriptors,
  }) {
    if (blocks.isEmpty) {
      return const [];
    }

    final prompt = <core.PromptMessage>[];
    final userParts = <core.PromptPart>[];

    void flushUserParts() {
      if (userParts.isEmpty) {
        return;
      }

      prompt.add(
        core.UserPromptMessage(
          parts: List<core.PromptPart>.from(userParts),
        ),
      );
      userParts.clear();
    }

    for (final block in blocks) {
      if (block is AnthropicLegacyToolResultBlock) {
        flushUserParts();
        prompt.add(
          _convertToolResultMessage(
            block,
            toolDescriptors: toolDescriptors,
          ),
        );
        continue;
      }

      userParts.add(_convertPromptPart(block));
    }

    flushUserParts();
    return prompt;
  }

  core.PromptPart _convertAssistantPromptPart(
    AnthropicLegacyPromptBlock block, {
    required Map<String, _AnthropicCompatToolDescriptor> toolDescriptors,
  }) {
    if (block is AnthropicLegacyToolUseBlock) {
      final toolPart = core.ToolCallPromptPart(
        toolCallId: block.toolCallId,
        toolName: block.toolName,
        input: block.input,
        providerExecuted: block.providerExecuted,
        isDynamic: block.isDynamic,
        title: block.title,
      );
      toolDescriptors[block.toolCallId] = _AnthropicCompatToolDescriptor(
        toolName: block.toolName,
      );
      return toolPart;
    }

    return _convertPromptPart(block);
  }

  core.ToolPromptMessage _convertToolResultMessage(
    AnthropicLegacyToolResultBlock block, {
    required Map<String, _AnthropicCompatToolDescriptor> toolDescriptors,
  }) {
    final descriptor = toolDescriptors[block.toolCallId];
    final toolName = descriptor?.toolName ?? _fallbackToolResultName(block);

    if (block.customKind != null && block.rawBlock != null) {
      return core.ToolPromptMessage(
        toolName: toolName,
        parts: [
          core.CustomPromptPart(
            kind: block.customKind!,
            data: {
              'replayRole': 'tool',
              'toolCallId': block.toolCallId,
              'toolName': toolName,
              'block': block.rawBlock,
            },
          ),
        ],
      );
    }

    return core.ToolPromptMessage(
      toolName: toolName,
      parts: [
        core.ToolResultPromptPart(
          toolCallId: block.toolCallId,
          toolName: toolName,
          output: block.output,
          isError: block.isError,
        ),
      ],
    );
  }

  core.PromptPart _convertPromptPart(AnthropicLegacyPromptBlock block) {
    final metadata = _cacheMetadata(block.cacheControl);

    return switch (block) {
      AnthropicLegacyTextBlock(:final text) => core.TextPromptPart(
          text,
          providerMetadata: metadata,
        ),
      AnthropicLegacyImageBlock(
        :final mediaType,
        :final uri,
        :final bytes,
      ) =>
        core.ImagePromptPart(
          mediaType: mediaType,
          data: bytes != null
              ? core.FileBytesData(bytes)
              : core.FileUrlData(
                  uri ??
                      (throw ArgumentError.value(
                        block,
                        'block',
                        'Anthropic image blocks require bytes or a URI.',
                      )),
                ),
          providerMetadata: metadata,
        ),
      AnthropicLegacyDocumentBlock(
        :final mediaType,
        :final title,
        :final uri,
        :final bytes,
      ) =>
        core.FilePromptPart(
          mediaType: mediaType,
          filename: title,
          data: bytes != null
              ? core.FileBytesData(bytes)
              : core.FileUrlData(
                  uri ??
                      (throw ArgumentError.value(
                        block,
                        'block',
                        'Anthropic document blocks require bytes or a URI.',
                      )),
                ),
          providerMetadata: metadata,
        ),
      AnthropicLegacyToolUseBlock() ||
      AnthropicLegacyToolResultBlock() =>
        throw UnsupportedError(
          'Anthropic tool replay blocks require role-aware conversion.',
        ),
    };
  }

  core.ProviderMetadata? _cacheMetadata(
    AnthropicLegacyCacheControl? cacheControl,
  ) {
    if (cacheControl == null) {
      return null;
    }

    return core.ProviderMetadata({
      'anthropic': {
        'cacheControl': cacheControl.toJson(),
      },
    });
  }

  String _fallbackToolResultName(AnthropicLegacyToolResultBlock block) {
    return switch (block.blockType) {
      'mcp_tool_result' => 'mcp.unknown',
      'web_search_tool_result' => 'web_search',
      'web_fetch_tool_result' => 'web_fetch',
      'tool_search_tool_result' => 'tool_search',
      _ => 'tool',
    };
  }
}

final class _AnthropicCompatToolDescriptor {
  final String toolName;

  const _AnthropicCompatToolDescriptor({
    required this.toolName,
  });
}
