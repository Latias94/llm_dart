import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as modern_anthropic;
import 'package:llm_dart_core/llm_dart_core.dart' as core;

import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../anthropic_legacy_extensions.dart';
import '../legacy_chat_adapter.dart';

final class AnthropicLegacyChatCapabilityAdapter
    extends LegacyChatCapabilityAdapter {
  const AnthropicLegacyChatCapabilityAdapter({
    required super.model,
    required super.config,
    super.providerOptions,
  });

  @override
  core.GenerateTextRequest buildRequest(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    core.ProviderInvocationOptions? providerOptionsOverride,
  }) {
    final analysis = analyzeAnthropicLegacyMessageExtensions(messages);
    final effectiveTools = <Tool>[
      ...analysis.messageTools,
      ...?(tools ?? config.tools),
    ];

    if (effectiveTools.isNotEmpty && analysis.hasAmbiguousToolCacheControl) {
      throw UnsupportedError(
        'Anthropic compatibility cannot preserve multiple legacy tool cache policies in one bridged request.',
      );
    }

    final baseOptions = resolveAnthropicCompatProviderOptions(
      providerOptionsOverride ?? providerOptions,
    );
    final legacyToolCacheControl = analysis.toolCacheControl;
    final mergedToolCacheControl = mergeAnthropicCompatToolCacheControl(
      baseOptions.toolsCacheControl,
      legacyToolCacheControl,
    );

    return super.buildRequest(
      messages,
      effectiveTools,
      providerOptionsOverride: baseOptions.copyWith(
        toolsCacheControl: mergedToolCacheControl,
      ),
    );
  }

  @override
  List<core.PromptMessage> convertMessages(List<ChatMessage> messages) {
    final prompt = <core.PromptMessage>[];
    final toolDescriptors = <String, _AnthropicCompatToolDescriptor>{};
    final hasSystemMessage =
        messages.any((message) => message.role == ChatRole.system);

    if (!hasSystemMessage &&
        config.systemPrompt != null &&
        config.systemPrompt!.isNotEmpty) {
      prompt.add(core.SystemPromptMessage.text(config.systemPrompt!));
    }

    for (var index = 0; index < messages.length; index++) {
      final message = messages[index];
      if (!message.extensions.containsKey('anthropic')) {
        prompt.addAll(
          _convertTrackedLegacyMessage(
            message,
            toolDescriptors: toolDescriptors,
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
      ChatRole.system => _convertAnthropicLegacySystemMessage(blocks),
      ChatRole.assistant => _convertAnthropicLegacyAssistantMessage(
          blocks,
          toolDescriptors: toolDescriptors,
        ),
      ChatRole.user => _convertAnthropicLegacyUserMessage(
          blocks,
          toolDescriptors: toolDescriptors,
        ),
    };
  }

  List<core.PromptMessage> _convertTrackedLegacyMessage(
    ChatMessage message, {
    required Map<String, _AnthropicCompatToolDescriptor> toolDescriptors,
  }) {
    final converted = super.convertMessage(message);

    if (message.messageType case ToolUseMessage(:final toolCalls)) {
      for (final toolCall in toolCalls) {
        toolDescriptors[toolCall.id] = _AnthropicCompatToolDescriptor(
          toolName: toolCall.function.name,
          providerExecuted: false,
          isDynamic: false,
        );
      }
    }

    return converted;
  }

  List<core.PromptMessage> _convertAnthropicLegacySystemMessage(
    List<AnthropicLegacyPromptBlock> blocks,
  ) {
    if (blocks.isEmpty) {
      return const [];
    }

    return [
      core.SystemPromptMessage(
        parts: [
          for (final block in blocks) convertAnthropicCompatPromptPart(block),
        ],
      ),
    ];
  }

  List<core.PromptMessage> _convertAnthropicLegacyAssistantMessage(
    List<AnthropicLegacyPromptBlock> blocks, {
    required Map<String, _AnthropicCompatToolDescriptor> toolDescriptors,
  }) {
    if (blocks.isEmpty) {
      return const [];
    }

    final parts = <core.PromptPart>[
      for (final block in blocks)
        _convertAnthropicLegacyAssistantPromptPart(
          block,
          toolDescriptors: toolDescriptors,
        ),
    ];

    return [
      core.AssistantPromptMessage(parts: parts),
    ];
  }

  List<core.PromptMessage> _convertAnthropicLegacyUserMessage(
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
          _convertAnthropicLegacyToolResultMessage(
            block,
            toolDescriptors: toolDescriptors,
          ),
        );
        continue;
      }

      userParts.add(convertAnthropicCompatPromptPart(block));
    }

    flushUserParts();
    return prompt;
  }

  core.PromptPart _convertAnthropicLegacyAssistantPromptPart(
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
        providerExecuted: block.providerExecuted,
        isDynamic: block.isDynamic,
        title: block.title,
      );
      return toolPart;
    }

    return convertAnthropicCompatPromptPart(block);
  }

  core.ToolPromptMessage _convertAnthropicLegacyToolResultMessage(
    AnthropicLegacyToolResultBlock block, {
    required Map<String, _AnthropicCompatToolDescriptor> toolDescriptors,
  }) {
    final descriptor = toolDescriptors[block.toolCallId];
    final toolName =
        descriptor?.toolName ?? fallbackAnthropicCompatToolResultName(block);

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
}

core.PromptPart convertAnthropicCompatPromptPart(
  AnthropicLegacyPromptBlock block,
) {
  final metadata = anthropicCompatCacheMetadata(block.cacheControl);

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
        uri: uri,
        bytes: bytes,
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
        uri: uri,
        bytes: bytes,
        providerMetadata: metadata,
      ),
    AnthropicLegacyToolUseBlock() ||
    AnthropicLegacyToolResultBlock() =>
      throw UnsupportedError(
        'Anthropic tool replay blocks require role-aware conversion.',
      ),
  };
}

modern_anthropic.AnthropicGenerateTextOptions
    resolveAnthropicCompatProviderOptions(
  core.ProviderInvocationOptions? options,
) {
  if (options == null) {
    return const modern_anthropic.AnthropicGenerateTextOptions();
  }

  if (options is modern_anthropic.AnthropicGenerateTextOptions) {
    return options;
  }

  throw ArgumentError.value(
    options,
    'providerOptions',
    'Expected AnthropicGenerateTextOptions for Anthropic compatibility requests.',
  );
}

modern_anthropic.AnthropicCacheControl? mergeAnthropicCompatToolCacheControl(
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

core.ProviderMetadata? anthropicCompatCacheMetadata(
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

String fallbackAnthropicCompatToolResultName(
  AnthropicLegacyToolResultBlock block,
) {
  return switch (block.blockType) {
    'mcp_tool_result' => 'mcp.unknown',
    'web_search_tool_result' => 'web_search',
    'web_fetch_tool_result' => 'web_fetch',
    'tool_search_tool_result' => 'tool_search',
    _ => 'tool',
  };
}

final class _AnthropicCompatToolDescriptor {
  final String toolName;
  final bool providerExecuted;
  final bool isDynamic;
  final String? title;

  const _AnthropicCompatToolDescriptor({
    required this.toolName,
    required this.providerExecuted,
    required this.isDynamic,
    this.title,
  });
}
