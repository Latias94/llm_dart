import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as modern_anthropic;
import 'package:llm_dart_core/llm_dart_core.dart' as core;
import 'package:llm_dart_google/llm_dart_google.dart' as modern_google;
import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;

import '../../core/capability.dart';
import '../../core/config.dart';
import '../../core/web_search.dart';
import '../../models/chat_models.dart';
import '../../models/tool_models.dart';
import '../../providers/anthropic/config.dart';
import '../../providers/anthropic/mcp_models.dart';
import '../../providers/anthropic/provider.dart';
import '../../providers/deepseek/config.dart';
import '../../providers/deepseek/provider.dart';
import '../../providers/google/config.dart';
import '../../providers/google/provider.dart';
import '../../providers/groq/config.dart';
import '../../providers/groq/provider.dart';
import '../../providers/openai/builtin_tools.dart';
import '../../providers/openai/config.dart';
import '../../providers/openai/provider.dart';
import '../../providers/xai/config.dart';
import '../../providers/xai/provider.dart';
import 'anthropic_legacy_extensions.dart';
import 'chat_route_compatibility.dart';
import 'compat_transport.dart';
import 'legacy_chat_adapter.dart';

ChatCapability buildCompatOpenAIProvider(LLMConfig config) {
  final legacyConfig = _toLegacyOpenAIConfig(config);
  final model = modern_openai.OpenAI(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    transport: createCompatTransport(config),
  ).chatModel(
    config.model,
    settings: const modern_openai.OpenAIChatModelSettings(
      useResponsesApi: true,
    ),
  );

  return CompatOpenAIProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: LegacyChatCapabilityAdapter(
      model: model,
      config: config,
      providerOptions: modern_openai.OpenAIGenerateTextOptions(
        previousResponseId: config.getExtension<String>('previousResponseId'),
        parallelToolCalls: config.getExtension<bool>('parallelToolCalls'),
        serviceTier: config.serviceTier?.value,
        verbosity: config.getExtension<String>('verbosity'),
        builtInTools: _mapOpenAIBuiltInTools(
          config.getExtension<List<OpenAIBuiltInTool>>('builtInTools'),
        ),
      ),
    ),
  );
}

ChatCapability buildCompatDeepSeekProvider(LLMConfig config) {
  final legacyConfig = DeepSeekConfig.fromLLMConfig(config);
  final model = modern_openai.OpenAI(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    transport: createCompatTransport(config),
    profile: const modern_openai.DeepSeekProfile(),
  ).chatModel(
    config.model,
  );

  return CompatDeepSeekProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: LegacyChatCapabilityAdapter(
      model: model,
      config: config,
    ),
  );
}

ChatCapability buildCompatOpenRouterProvider(LLMConfig config) {
  final legacyConfig = _toLegacyOpenRouterConfig(config);
  final model = modern_openai.OpenAI(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    transport: createCompatTransport(config),
    profile: const modern_openai.OpenRouterProfile(),
  ).chatModel(
    config.model,
    settings: _buildCompatOpenRouterModelSettings(config),
  );

  return CompatOpenRouterProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: LegacyChatCapabilityAdapter(
      model: model,
      config: config,
      providerOptions: modern_openai.OpenAIGenerateTextOptions(
        parallelToolCalls: config.getExtension<bool>('parallelToolCalls'),
        serviceTier: config.serviceTier?.value,
        verbosity: config.getExtension<String>('verbosity'),
      ),
    ),
  );
}

ChatCapability buildCompatGroqProvider(LLMConfig config) {
  final legacyConfig = GroqConfig.fromLLMConfig(config);
  final model = modern_openai.OpenAI(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    transport: createCompatTransport(config),
    profile: const modern_openai.GroqProfile(),
  ).chatModel(
    config.model,
  );

  return CompatGroqProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: LegacyChatCapabilityAdapter(
      model: model,
      config: config,
    ),
  );
}

ChatCapability buildCompatXAIProvider(LLMConfig config) {
  final legacyConfig = XAIConfig.fromLLMConfig(config);
  final model = modern_openai.OpenAI(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    transport: createCompatTransport(config),
    profile: const modern_openai.XAIProfile(),
  ).chatModel(
    config.model,
  );

  return CompatXAIProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: LegacyChatCapabilityAdapter(
      model: model,
      config: config,
      providerOptions: modern_openai.XAIGenerateTextOptions(
        common: const modern_openai.OpenAIGenerateTextOptions(),
        search: _buildCompatXAILiveSearchOptions(legacyConfig),
      ),
    ),
  );
}

ChatCapability buildCompatGoogleProvider(LLMConfig config) {
  final legacyConfig = GoogleConfig.fromLLMConfig(config);
  final model = modern_google.Google(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    transport: createCompatTransport(config),
  ).chatModel(
    config.model,
  );

  return CompatGoogleProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: LegacyChatCapabilityAdapter(
      model: model,
      config: config,
      providerOptions: modern_google.GoogleGenerateTextOptions(
        candidateCount: config.getExtension<int>('candidateCount'),
        thinkingBudgetTokens: config.getExtension<int>('thinkingBudgetTokens'),
        thinkingLevel: _mapGoogleThinkingLevel(
          config.extensions['reasoningEffort'],
        ),
        includeThoughts: config.getExtension<bool>('includeThoughts'),
        responseModalities: _mapGoogleResponseModalities(config),
        safetySettings: _mapGoogleSafetySettings(
          config.getExtension<List<SafetySetting>>('safetySettings'),
        ),
        tools: _buildGoogleNativeTools(config),
      ),
    ),
  );
}

ChatCapability buildCompatAnthropicProvider(LLMConfig config) {
  final legacyConfig = AnthropicConfig.fromLLMConfig(config);
  final model = modern_anthropic.Anthropic(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    transport: createCompatTransport(config),
  ).chatModel(
    config.model,
  );

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

final class CompatOpenAIProvider extends OpenAIProvider {
  final LLMConfig _originalConfig;
  final LegacyChatCapabilityAdapter _adapter;

  CompatOpenAIProvider({
    required LLMConfig originalConfig,
    required OpenAIConfig legacyConfig,
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
  }) async {
    if (canUseOpenAIChatBridge(_originalConfig, messages, tools)) {
      try {
        return await _adapter.chatWithTools(
          messages,
          tools,
          cancelToken: cancelToken,
        );
      } catch (error) {
        if (!_isCompatibilityError(error)) {
          rethrow;
        }
      }
    }

    return super.chatWithTools(messages, tools, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) async* {
    if (canUseOpenAIChatBridge(_originalConfig, messages, tools)) {
      try {
        yield* _adapter.chatStream(
          messages,
          tools: tools,
          cancelToken: cancelToken,
        );
        return;
      } catch (error) {
        if (!_isCompatibilityError(error)) {
          rethrow;
        }
      }
    }

    yield* super.chatStream(messages, tools: tools, cancelToken: cancelToken);
  }
}

final class CompatDeepSeekProvider extends DeepSeekProvider {
  final LLMConfig _originalConfig;
  final LegacyChatCapabilityAdapter _adapter;

  CompatDeepSeekProvider({
    required LLMConfig originalConfig,
    required DeepSeekConfig legacyConfig,
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
  }) async {
    if (canUseDeepSeekChatBridge(_originalConfig, messages, tools)) {
      try {
        return await _adapter.chatWithTools(
          messages,
          tools,
          cancelToken: cancelToken,
        );
      } catch (error) {
        if (!_isCompatibilityError(error)) {
          rethrow;
        }
      }
    }

    return super.chatWithTools(messages, tools, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) async* {
    if (canUseDeepSeekChatBridge(_originalConfig, messages, tools)) {
      try {
        yield* _adapter.chatStream(
          messages,
          tools: tools,
          cancelToken: cancelToken,
        );
        return;
      } catch (error) {
        if (!_isCompatibilityError(error)) {
          rethrow;
        }
      }
    }

    yield* super.chatStream(messages, tools: tools, cancelToken: cancelToken);
  }
}

final class CompatOpenRouterProvider extends OpenAIProvider {
  final LLMConfig _originalConfig;
  final LegacyChatCapabilityAdapter _adapter;

  CompatOpenRouterProvider({
    required LLMConfig originalConfig,
    required OpenAIConfig legacyConfig,
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
  }) async {
    if (canUseOpenRouterChatBridge(_originalConfig, messages, tools)) {
      try {
        return await _adapter.chatWithTools(
          messages,
          tools,
          cancelToken: cancelToken,
        );
      } catch (error) {
        if (!_isCompatibilityError(error)) {
          rethrow;
        }
      }
    }

    return super.chatWithTools(messages, tools, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) async* {
    if (canUseOpenRouterChatBridge(_originalConfig, messages, tools)) {
      try {
        yield* _adapter.chatStream(
          messages,
          tools: tools,
          cancelToken: cancelToken,
        );
        return;
      } catch (error) {
        if (!_isCompatibilityError(error)) {
          rethrow;
        }
      }
    }

    yield* super.chatStream(messages, tools: tools, cancelToken: cancelToken);
  }
}

final class CompatGroqProvider extends GroqProvider {
  final LLMConfig _originalConfig;
  final LegacyChatCapabilityAdapter _adapter;

  CompatGroqProvider({
    required LLMConfig originalConfig,
    required GroqConfig legacyConfig,
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
  }) async {
    if (canUseGroqChatBridge(_originalConfig, messages, tools)) {
      try {
        return await _adapter.chatWithTools(
          messages,
          tools,
          cancelToken: cancelToken,
        );
      } catch (error) {
        if (!_isCompatibilityError(error)) {
          rethrow;
        }
      }
    }

    return super.chatWithTools(messages, tools, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) async* {
    if (canUseGroqChatBridge(_originalConfig, messages, tools)) {
      try {
        yield* _adapter.chatStream(
          messages,
          tools: tools,
          cancelToken: cancelToken,
        );
        return;
      } catch (error) {
        if (!_isCompatibilityError(error)) {
          rethrow;
        }
      }
    }

    yield* super.chatStream(messages, tools: tools, cancelToken: cancelToken);
  }
}

final class CompatXAIProvider extends XAIProvider {
  final LLMConfig _originalConfig;
  final LegacyChatCapabilityAdapter _adapter;

  CompatXAIProvider({
    required LLMConfig originalConfig,
    required XAIConfig legacyConfig,
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
  }) async {
    if (canUseXAIChatBridge(_originalConfig, messages, tools)) {
      try {
        return await _adapter.chatWithTools(
          messages,
          tools,
          cancelToken: cancelToken,
        );
      } catch (error) {
        if (!_isCompatibilityError(error)) {
          rethrow;
        }
      }
    }

    return super.chatWithTools(messages, tools, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) async* {
    if (canUseXAIChatBridge(_originalConfig, messages, tools)) {
      try {
        yield* _adapter.chatStream(
          messages,
          tools: tools,
          cancelToken: cancelToken,
        );
        return;
      } catch (error) {
        if (!_isCompatibilityError(error)) {
          rethrow;
        }
      }
    }

    yield* super.chatStream(messages, tools: tools, cancelToken: cancelToken);
  }
}

final class CompatGoogleProvider extends GoogleProvider {
  final LLMConfig _originalConfig;
  final LegacyChatCapabilityAdapter _adapter;

  CompatGoogleProvider({
    required LLMConfig originalConfig,
    required GoogleConfig legacyConfig,
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
  }) async {
    if (canUseGoogleChatBridge(_originalConfig, messages, tools)) {
      try {
        return await _adapter.chatWithTools(
          messages,
          tools,
          cancelToken: cancelToken,
        );
      } catch (error) {
        if (!_isCompatibilityError(error)) {
          rethrow;
        }
      }
    }

    return super.chatWithTools(messages, tools, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) async* {
    if (canUseGoogleChatBridge(_originalConfig, messages, tools)) {
      try {
        yield* _adapter.chatStream(
          messages,
          tools: tools,
          cancelToken: cancelToken,
        );
        return;
      } catch (error) {
        if (!_isCompatibilityError(error)) {
          rethrow;
        }
      }
    }

    yield* super.chatStream(messages, tools: tools, cancelToken: cancelToken);
  }
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
  }) async {
    if (canUseAnthropicChatBridge(_originalConfig, messages, tools)) {
      try {
        return await _adapter.chatWithTools(
          messages,
          tools,
          cancelToken: cancelToken,
        );
      } catch (error) {
        if (!_isCompatibilityError(error)) {
          rethrow;
        }
      }
    }

    return super.chatWithTools(messages, tools, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) async* {
    if (canUseAnthropicChatBridge(_originalConfig, messages, tools)) {
      try {
        yield* _adapter.chatStream(
          messages,
          tools: tools,
          cancelToken: cancelToken,
        );
        return;
      } catch (error) {
        if (!_isCompatibilityError(error)) {
          rethrow;
        }
      }
    }

    yield* super.chatStream(messages, tools: tools, cancelToken: cancelToken);
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

OpenAIConfig _toLegacyOpenAIConfig(LLMConfig config) {
  var model = config.model;
  final webSearchEnabled =
      config.getExtension<bool>('webSearchEnabled') == true;
  final webSearchConfig =
      config.getExtension<WebSearchConfig>('webSearchConfig');
  if ((webSearchEnabled || webSearchConfig != null) &&
      !_isOpenAISearchModel(model)) {
    model = _openAISearchModelFor(model);
  }

  return OpenAIConfig(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    model: model,
    maxTokens: config.maxTokens,
    temperature: config.temperature,
    systemPrompt: config.systemPrompt,
    timeout: config.timeout,
    topP: config.topP,
    topK: config.topK,
    tools: config.tools,
    toolChoice: config.toolChoice,
    reasoningEffort: ReasoningEffort.fromString(
      _stringValue(config.extensions['reasoningEffort']),
    ),
    jsonSchema: config.getExtension<StructuredOutputFormat>('jsonSchema'),
    voice: config.getExtension<String>('voice'),
    embeddingEncodingFormat:
        config.getExtension<String>('embeddingEncodingFormat'),
    embeddingDimensions: config.getExtension<int>('embeddingDimensions'),
    stopSequences: config.stopSequences,
    user: config.user,
    serviceTier: config.serviceTier,
    useResponsesAPI: config.getExtension<bool>('useResponsesAPI') ?? false,
    previousResponseId: config.getExtension<String>('previousResponseId'),
    builtInTools: config.getExtension<List<OpenAIBuiltInTool>>('builtInTools'),
    originalConfig: config,
  );
}

OpenAIConfig _toLegacyOpenRouterConfig(LLMConfig config) {
  var model = config.model;
  final webSearchEnabled =
      config.getExtension<bool>('webSearchEnabled') == true;
  final webSearchConfig =
      config.getExtension<WebSearchConfig>('webSearchConfig');
  if ((webSearchEnabled || webSearchConfig != null) &&
      !model.endsWith(':online')) {
    model = '$model:online';
  }

  return OpenAIConfig(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    model: model,
    maxTokens: config.maxTokens,
    temperature: config.temperature,
    systemPrompt: config.systemPrompt,
    timeout: config.timeout,
    topP: config.topP,
    topK: config.topK,
    tools: config.tools,
    toolChoice: config.toolChoice,
    jsonSchema: config.getExtension<StructuredOutputFormat>('jsonSchema'),
    stopSequences: config.stopSequences,
    user: config.user,
    serviceTier: config.serviceTier,
    useResponsesAPI: config.getExtension<bool>('useResponsesAPI') ?? false,
    previousResponseId: config.getExtension<String>('previousResponseId'),
    builtInTools: config.getExtension<List<OpenAIBuiltInTool>>('builtInTools'),
    originalConfig: config,
  );
}

List<modern_openai.OpenAIBuiltInTool>? _mapOpenAIBuiltInTools(
  List<OpenAIBuiltInTool>? tools,
) {
  if (tools == null || tools.isEmpty) {
    return null;
  }

  final mapped = <modern_openai.OpenAIBuiltInTool>[];
  for (final tool in tools) {
    switch (tool) {
      case OpenAIWebSearchTool():
        mapped.add(modern_openai.OpenAIBuiltInTools.webSearch());
      case OpenAIFileSearchTool(
          :final vectorStoreIds,
          :final parameters,
        ):
        mapped.add(
          modern_openai.OpenAIBuiltInTools.fileSearch(
            vectorStoreIds: vectorStoreIds,
            parameters: parameters == null
                ? null
                : _normalizeCompatJsonValue(parameters) as Map<String, Object?>,
          ),
        );
      case OpenAIComputerUseTool(
          :final displayWidth,
          :final displayHeight,
          :final environment,
          :final parameters,
        ):
        mapped.add(
          modern_openai.OpenAIBuiltInTools.computerUse(
            displayWidth: displayWidth,
            displayHeight: displayHeight,
            environment: environment,
            parameters: parameters == null
                ? null
                : _normalizeCompatJsonValue(parameters) as Map<String, Object?>,
          ),
        );
      default:
        break;
    }
  }

  return mapped.isEmpty ? null : mapped;
}

core.ProviderModelOptions _buildCompatOpenRouterModelSettings(
  LLMConfig config,
) {
  if (hasEnabledWebSearch(config) && !config.model.endsWith(':online')) {
    return const modern_openai.OpenRouterChatModelSettings(
      search: modern_openai.OpenRouterSearchOptions.onlineModel(),
    );
  }

  return const modern_openai.OpenAIChatModelSettings();
}

modern_openai.XAILiveSearchOptions? _buildCompatXAILiveSearchOptions(
  XAIConfig config,
) {
  final searchParameters = _normalizeCompatXAISearchParameters(config);
  if (searchParameters == null) {
    return null;
  }

  final mode = _mapCompatXAISearchMode(searchParameters.mode);
  final sources = _mapCompatXAISearchSources(searchParameters.sources);
  final fromDate = _parseCompatUtcDate(searchParameters.fromDate);
  final toDate = _parseCompatUtcDate(searchParameters.toDate);
  final maxSearchResults = searchParameters.maxSearchResults;

  if (mode == null ||
      sources == null ||
      (searchParameters.fromDate != null && fromDate == null) ||
      (searchParameters.toDate != null && toDate == null) ||
      (maxSearchResults != null &&
          (maxSearchResults < 1 || maxSearchResults > 50)) ||
      (fromDate != null && toDate != null && toDate.isBefore(fromDate))) {
    return null;
  }

  return modern_openai.XAILiveSearchOptions(
    mode: mode,
    fromDate: fromDate,
    toDate: toDate,
    maxSearchResults: maxSearchResults,
    sources: sources,
  );
}

SearchParameters? _normalizeCompatXAISearchParameters(XAIConfig config) {
  final searchParameters = config.searchParameters;
  if (searchParameters == null) {
    return config.liveSearch == true ? SearchParameters.webSearch() : null;
  }

  final sources = searchParameters.sources?.isNotEmpty == true
      ? searchParameters.sources
      : [const SearchSource(sourceType: 'web')];

  return SearchParameters(
    mode: searchParameters.mode ?? 'auto',
    sources: sources,
    maxSearchResults: searchParameters.maxSearchResults,
    fromDate: searchParameters.fromDate,
    toDate: searchParameters.toDate,
  );
}

modern_openai.XAISearchMode? _mapCompatXAISearchMode(String? mode) {
  return switch (mode) {
    null || 'auto' => modern_openai.XAISearchMode.auto,
    'always' || 'on' => modern_openai.XAISearchMode.on,
    'never' || 'off' => modern_openai.XAISearchMode.off,
    _ => null,
  };
}

List<modern_openai.XAISearchSource>? _mapCompatXAISearchSources(
  List<SearchSource>? sources,
) {
  if (sources == null || sources.isEmpty) {
    return const [modern_openai.XAIWebSearchSource()];
  }

  final mapped = <modern_openai.XAISearchSource>[];
  for (final source in sources) {
    switch (source.sourceType) {
      case 'web':
        mapped.add(
          modern_openai.XAIWebSearchSource(
            excludedWebsites: source.excludedWebsites ?? const [],
          ),
        );
        break;
      case 'news':
        mapped.add(
          modern_openai.XAINewsSearchSource(
            excludedWebsites: source.excludedWebsites ?? const [],
          ),
        );
        break;
      default:
        return null;
    }
  }

  return mapped;
}

DateTime? _parseCompatUtcDate(String? value) {
  if (value == null) {
    return null;
  }

  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) {
    return null;
  }

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);

  try {
    final parsed = DateTime.utc(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  } catch (_) {
    return null;
  }
}

bool _isOpenAISearchModel(String model) {
  return model.contains('search-preview') || model.contains('search');
}

String _openAISearchModelFor(String model) {
  if (model.startsWith('gpt-4o-mini')) {
    return 'gpt-4o-mini-search-preview';
  }

  if (model.startsWith('gpt-4o')) {
    return 'gpt-4o-search-preview';
  }

  return 'gpt-4o-search-preview';
}

modern_google.GoogleThinkingLevel? _mapGoogleThinkingLevel(Object? rawValue) {
  final value = _stringValue(rawValue)?.toLowerCase();
  return switch (value) {
    'minimal' => modern_google.GoogleThinkingLevel.minimal,
    'low' => modern_google.GoogleThinkingLevel.low,
    'medium' => modern_google.GoogleThinkingLevel.medium,
    'high' => modern_google.GoogleThinkingLevel.high,
    _ => null,
  };
}

List<modern_google.GoogleResponseModality>? _mapGoogleResponseModalities(
  LLMConfig config,
) {
  final rawValues = config.getExtension<List<dynamic>>('responseModalities');
  final mapped = <modern_google.GoogleResponseModality>[];

  if (rawValues != null) {
    for (final rawValue in rawValues) {
      switch (rawValue.toString().toUpperCase()) {
        case 'TEXT':
          mapped.add(modern_google.GoogleResponseModality.text);
          break;
        case 'IMAGE':
          mapped.add(modern_google.GoogleResponseModality.image);
          break;
        default:
          break;
      }
    }
  } else if (config.getExtension<bool>('enableImageGeneration') == true) {
    mapped.addAll(const [
      modern_google.GoogleResponseModality.text,
      modern_google.GoogleResponseModality.image,
    ]);
  }

  return mapped.isEmpty ? null : mapped;
}

List<modern_google.GoogleSafetySetting>? _mapGoogleSafetySettings(
  List<SafetySetting>? settings,
) {
  if (settings == null || settings.isEmpty) {
    return null;
  }

  return settings
      .map(
        (setting) => modern_google.GoogleSafetySetting(
          category: modern_google.GoogleHarmCategory.values.firstWhere(
            (value) => value.value == setting.category.value,
            orElse: () => modern_google.GoogleHarmCategory.unspecified,
          ),
          threshold: modern_google.GoogleHarmBlockThreshold.values.firstWhere(
            (value) => value.value == setting.threshold.value,
            orElse: () => modern_google.GoogleHarmBlockThreshold.unspecified,
          ),
        ),
      )
      .toList(growable: false);
}

List<modern_google.GoogleNativeTool>? _buildGoogleNativeTools(
    LLMConfig config) {
  if (!hasEnabledWebSearch(config)) {
    return null;
  }

  final webSearchConfig =
      config.getExtension<WebSearchConfig>('webSearchConfig');
  final timeRangeFilter = _buildGoogleTimeRangeFilter(webSearchConfig);

  return [
    modern_google.GoogleTools.googleSearch(
      timeRangeFilter: timeRangeFilter,
    ),
  ];
}

modern_google.GoogleTimeRangeFilter? _buildGoogleTimeRangeFilter(
  WebSearchConfig? config,
) {
  if (config == null || config.fromDate == null || config.toDate == null) {
    return null;
  }

  final startTime = DateTime.tryParse(config.fromDate!);
  final endTime = DateTime.tryParse(config.toDate!);
  if (startTime == null || endTime == null) {
    return null;
  }

  return modern_google.GoogleTimeRangeFilter(
    startTime: startTime,
    endTime: endTime,
  );
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
        (key, value) => MapEntry(key, _normalizeCompatJsonValue(value)),
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

bool _isCompatibilityError(Object error) {
  return error is UnsupportedError ||
      error is ArgumentError ||
      error is FormatException ||
      error is StateError;
}

String? _stringValue(Object? value) {
  return switch (value) {
    null => null,
    String() => value,
    ReasoningEffort() => value.value,
    _ => value.toString(),
  };
}

Object? _normalizeCompatJsonValue(Object? value) {
  return switch (value) {
    null || bool() || num() || String() => value,
    List() => value.map(_normalizeCompatJsonValue).toList(growable: false),
    Map() => value.map(
        (key, nestedValue) => MapEntry(
          key as String,
          _normalizeCompatJsonValue(nestedValue),
        ),
      ),
    _ => value.toString(),
  };
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
