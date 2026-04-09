import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as modern_anthropic;
import 'package:llm_dart_core/llm_dart_core.dart' as core;

import '../../../core/capability.dart';
import '../../../core/config.dart';
import '../../../core/web_search.dart';
import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../../../providers/anthropic/config.dart';
import '../../../providers/anthropic/mcp_models.dart';
import '../anthropic_legacy_extensions.dart';
import '../chat_route_compatibility.dart';
import '../compat_transport.dart';
import '../legacy_chat_adapter.dart';
import 'anthropic/provider_compat.dart';
import 'compat_provider_support.dart';

ChatCapability buildCompatAnthropicProvider(LLMConfig config) {
  final legacyConfig = AnthropicConfig.fromLLMConfig(config);
  final model = modern_anthropic.Anthropic(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    transport: createCompatTransport(config),
  ).chatModel(config.model);

  return CompatAnthropicProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: AnthropicLegacyChatCapabilityAdapter(
      model: model,
      config: config,
      providerOptions: modern_anthropic.AnthropicGenerateTextOptions(
        extendedThinking: config.getExtension<bool>('reasoning'),
        thinkingBudgetTokens: config.getExtension<int>('thinkingBudgetTokens'),
        interleavedThinking: config.getExtension<bool>('interleavedThinking'),
        serviceTier: config.serviceTier?.value,
        metadata: _buildAnthropicMetadata(config),
        container: config.getExtension<String>('container'),
        mcpServers: _mapAnthropicMcpServers(
          config.getExtension<List<AnthropicMCPServer>>('mcpServers'),
        ),
        tools: _buildAnthropicNativeTools(config),
      ),
    ),
  );
}

final class CompatAnthropicProvider extends AnthropicProvider {
  final LLMConfig _originalConfig;
  final LegacyChatCapabilityAdapter _adapter;

  CompatAnthropicProvider({
    required LLMConfig originalConfig,
    required AnthropicConfig legacyConfig,
    required LegacyChatCapabilityAdapter adapter,
  })  : _originalConfig = originalConfig,
        _adapter = adapter,
        super(legacyConfig);

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) {
    return executeCompatChat(
      originalConfig: _originalConfig,
      messages: messages,
      tools: tools,
      canUseBridge: canUseAnthropicChatBridge,
      bridge: () => _adapter.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
      fallback: () => super.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) {
    return executeCompatChatStream(
      originalConfig: _originalConfig,
      messages: messages,
      tools: tools,
      canUseBridge: canUseAnthropicChatBridge,
      bridge: () => _adapter.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
      fallback: () => super.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
    );
  }
}

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

    final baseOptions = _resolveAnthropicProviderOptions(
      providerOptionsOverride ?? providerOptions,
    );
    final legacyToolCacheControl = analysis.toolCacheControl;
    final mergedToolCacheControl = _mergeAnthropicToolCacheControl(
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
          for (final block in blocks) _convertAnthropicLegacyPromptPart(block),
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

      userParts.add(_convertAnthropicLegacyPromptPart(block));
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

    return _convertAnthropicLegacyPromptPart(block);
  }

  core.ToolPromptMessage _convertAnthropicLegacyToolResultMessage(
    AnthropicLegacyToolResultBlock block, {
    required Map<String, _AnthropicCompatToolDescriptor> toolDescriptors,
  }) {
    final descriptor = toolDescriptors[block.toolCallId];
    final toolName =
        descriptor?.toolName ?? _fallbackAnthropicToolResultName(block);

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

  core.PromptPart _convertAnthropicLegacyPromptPart(
    AnthropicLegacyPromptBlock block,
  ) {
    final metadata = _anthropicCacheMetadata(block.cacheControl);

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
            'Anthropic tool replay blocks require role-aware conversion.'),
    };
  }
}

Map<String, Object?>? _buildAnthropicMetadata(LLMConfig config) {
  final metadata = <String, Object?>{};
  if (config.user != null) {
    metadata['user_id'] = config.user;
  }

  final customMetadata = config.getExtension<Map<String, dynamic>>('metadata');
  if (customMetadata != null) {
    metadata.addAll(
      customMetadata.map(
        (key, value) => MapEntry(key, compatNormalizeJsonValue(value)),
      ),
    );
  }

  return metadata.isEmpty ? null : metadata;
}

List<modern_anthropic.AnthropicMcpServer>? _mapAnthropicMcpServers(
  List<AnthropicMCPServer>? servers,
) {
  if (servers == null || servers.isEmpty) {
    return null;
  }

  return servers
      .map(
        (server) => modern_anthropic.AnthropicMcpServer(
          name: server.name,
          type: server.type,
          url: server.url,
          authorizationToken: server.authorizationToken,
          toolConfiguration: server.toolConfiguration == null
              ? null
              : modern_anthropic.AnthropicMcpToolConfiguration(
                  enabled: server.toolConfiguration!.enabled,
                  allowedTools: server.toolConfiguration!.allowedTools,
                ),
        ),
      )
      .toList(growable: false);
}

List<modern_anthropic.AnthropicNativeTool>? _buildAnthropicNativeTools(
  LLMConfig config,
) {
  if (!hasEnabledWebSearch(config)) {
    return null;
  }

  final webSearchConfig =
      config.getExtension<WebSearchConfig>('webSearchConfig');
  final location = webSearchConfig?.location;

  return [
    modern_anthropic.AnthropicTools.webSearch20250305(
      maxUses: webSearchConfig?.maxUses,
      allowedDomains: webSearchConfig?.allowedDomains ?? const [],
      blockedDomains: webSearchConfig?.blockedDomains ?? const [],
      userLocation: location == null
          ? null
          : modern_anthropic.AnthropicApproximateLocation(
              city: location.city,
              region: location.region,
              country: location.country,
              timezone: location.timezone,
            ),
    ),
  ];
}

modern_anthropic.AnthropicGenerateTextOptions _resolveAnthropicProviderOptions(
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

modern_anthropic.AnthropicCacheControl? _mergeAnthropicToolCacheControl(
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

core.ProviderMetadata? _anthropicCacheMetadata(
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

String _fallbackAnthropicToolResultName(
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
