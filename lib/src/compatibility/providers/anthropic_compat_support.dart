import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as modern_anthropic;
import 'package:llm_dart_provider/llm_dart_provider.dart' as core;

import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../anthropic_legacy_extensions.dart';

/// Provider-local support for Anthropic compatibility request planning and
/// role-aware prompt conversion.
///
/// This keeps the adapter focused on bridging `LegacyChatCapabilityAdapter`
/// while localizing Anthropic-specific cache, tool replay, and prompt shaping
/// rules in one provider-owned place.
final class AnthropicCompatAdapterSupport {
  static const _requestPlanner = _AnthropicCompatRequestPlanner();
  static const _messageConverter = _AnthropicCompatMessageConverter();

  const AnthropicCompatAdapterSupport();

  AnthropicCompatRequestPlan buildRequestPlan({
    required List<ChatMessage> messages,
    required List<Tool>? tools,
    required List<Tool>? configTools,
    required core.ProviderInvocationOptions? providerOptions,
  }) {
    return _requestPlanner.buildRequestPlan(
      messages: messages,
      tools: tools,
      configTools: configTools,
      providerOptions: providerOptions,
    );
  }

  List<core.PromptMessage> convertMessages({
    required List<ChatMessage> messages,
    required String? systemPrompt,
    required List<core.PromptMessage> Function(ChatMessage message)
        convertTrackedMessage,
  }) {
    return _messageConverter.convertMessages(
      messages: messages,
      systemPrompt: systemPrompt,
      convertTrackedMessage: convertTrackedMessage,
    );
  }
}

final class AnthropicCompatRequestPlan {
  final List<Tool> effectiveTools;
  final modern_anthropic.AnthropicGenerateTextOptions providerOptions;

  const AnthropicCompatRequestPlan({
    required this.effectiveTools,
    required this.providerOptions,
  });
}

final class _AnthropicCompatMessageConverter {
  static const _roleConverter = _AnthropicCompatMessageRoleConverter();

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
          _roleConverter.convertTrackedLegacyMessage(
            message,
            toolDescriptors: toolDescriptors,
            convertTrackedMessage: convertTrackedMessage,
          ),
        );
        continue;
      }

      prompt.addAll(
        _roleConverter.convertAnthropicLegacyMessage(
          message,
          messageIndex: index,
          toolDescriptors: toolDescriptors,
        ),
      );
    }

    return prompt;
  }
}

final class _AnthropicCompatMessageRoleConverter {
  static const _promptParts = _AnthropicCompatPromptPartConverter();
  static const _toolResults = _AnthropicCompatToolResultConverter();

  const _AnthropicCompatMessageRoleConverter();

  List<core.PromptMessage> convertAnthropicLegacyMessage(
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

  List<core.PromptMessage> convertTrackedLegacyMessage(
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
          for (final block in blocks) _promptParts.convertPromptPart(block),
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
        _promptParts.convertAssistantPromptPart(
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
          _toolResults.convertToolResultMessage(
            block,
            toolDescriptors: toolDescriptors,
          ),
        );
        continue;
      }

      userParts.add(_promptParts.convertPromptPart(block));
    }

    flushUserParts();
    return prompt;
  }
}

final class _AnthropicCompatPromptPartConverter {
  const _AnthropicCompatPromptPartConverter();

  core.PromptPart convertAssistantPromptPart(
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

    return convertPromptPart(block);
  }

  core.PromptPart convertPromptPart(AnthropicLegacyPromptBlock block) {
    final providerOptions = _cacheProviderOptions(block.cacheControl);

    return switch (block) {
      AnthropicLegacyTextBlock(:final text) => core.TextPromptPart(
          text,
          providerOptions: providerOptions,
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
          providerOptions: providerOptions,
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
          providerOptions: providerOptions,
        ),
      AnthropicLegacyToolUseBlock() ||
      AnthropicLegacyToolResultBlock() =>
        throw UnsupportedError(
          'Anthropic tool replay blocks require role-aware conversion.',
        ),
    };
  }

  core.ProviderPromptPartOptions? _cacheProviderOptions(
    AnthropicLegacyCacheControl? cacheControl,
  ) {
    if (cacheControl == null) {
      return null;
    }

    return modern_anthropic.AnthropicPromptPartOptions(
      cacheControl: modern_anthropic.AnthropicCacheControl(
        type: cacheControl.type,
        ttl: cacheControl.ttl,
      ),
    );
  }
}

final class _AnthropicCompatRequestPlanner {
  const _AnthropicCompatRequestPlanner();

  AnthropicCompatRequestPlan buildRequestPlan({
    required List<ChatMessage> messages,
    required List<Tool>? tools,
    required List<Tool>? configTools,
    required core.ProviderInvocationOptions? providerOptions,
  }) {
    final analysis = analyzeAnthropicLegacyMessageExtensions(messages);
    final effectiveTools = <Tool>[
      ...analysis.messageTools,
      ...?(tools ?? configTools),
    ];

    if (effectiveTools.isNotEmpty && analysis.hasAmbiguousToolCacheControl) {
      throw UnsupportedError(
        'Anthropic compatibility cannot preserve multiple legacy tool cache policies in one bridged request.',
      );
    }

    final baseOptions = _resolveProviderOptions(providerOptions);
    final mergedToolCacheControl = _mergeToolCacheControl(
      baseOptions.toolsCacheControl,
      analysis.toolCacheControl,
    );

    return AnthropicCompatRequestPlan(
      effectiveTools: effectiveTools,
      providerOptions: baseOptions.copyWith(
        toolsCacheControl: mergedToolCacheControl,
      ),
    );
  }

  modern_anthropic.AnthropicGenerateTextOptions _resolveProviderOptions(
    core.ProviderInvocationOptions? options,
  ) {
    return core.resolveProviderInvocationOptions<
            modern_anthropic.AnthropicGenerateTextOptions>(
          options,
          parameterName: 'providerOptions',
          expectedTypeName: 'AnthropicGenerateTextOptions',
          usageContext: 'Anthropic compatibility requests',
        ) ??
        const modern_anthropic.AnthropicGenerateTextOptions();
  }

  modern_anthropic.AnthropicCacheControl? _mergeToolCacheControl(
    modern_anthropic.AnthropicCacheControl? base,
    AnthropicLegacyCacheControl? legacy,
  ) {
    if (legacy == null) {
      return base;
    }

    if (base != null && (base.type != legacy.type || base.ttl != legacy.ttl)) {
      throw UnsupportedError(
        'Anthropic compatibility cannot merge conflicting tool cache policies.',
      );
    }

    return modern_anthropic.AnthropicCacheControl(
      type: legacy.type,
      ttl: legacy.ttl,
    );
  }
}

final class _AnthropicCompatToolResultConverter {
  const _AnthropicCompatToolResultConverter();

  core.ToolPromptMessage convertToolResultMessage(
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
