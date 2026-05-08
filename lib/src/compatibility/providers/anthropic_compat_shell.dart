import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as modern_anthropic;

import '../../../core/capability.dart';
import '../../../core/config.dart';
import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../../../providers/anthropic/config.dart';
import '../../../providers/anthropic/mcp_models.dart';
import '../chat_route_compatibility.dart';
import '../compat_transport.dart';
import '../legacy_chat_adapter.dart';
import 'anthropic/provider_compat.dart';
import 'anthropic_compat_adapter.dart';
import 'anthropic_config_adapter.dart';
import 'compat_provider_support.dart';

ChatCapability buildCompatAnthropicProvider(LLMConfig config) {
  final legacyConfig = createLegacyAnthropicConfig(config);
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
        extendedThinking: legacyConfig.reasoning,
        thinkingBudgetTokens: legacyConfig.thinkingBudgetTokens,
        interleavedThinking: legacyConfig.interleavedThinking,
        serviceTier: legacyConfig.serviceTier?.value,
        metadata: buildAnthropicCompatMetadata(legacyConfig),
        container: legacyConfig.container,
        mcpServers: mapAnthropicCompatMcpServers(legacyConfig.mcpServers),
        tools: buildAnthropicCompatNativeTools(legacyConfig),
      ),
    ),
  );
}

final class CompatAnthropicProvider extends AnthropicProvider {
  final CompatChatBridgeRouter _chatRouter;

  CompatAnthropicProvider({
    required LLMConfig originalConfig,
    required AnthropicConfig legacyConfig,
    required LegacyChatCapabilityAdapter adapter,
  })  : _chatRouter = CompatChatBridgeRouter(
          originalConfig: originalConfig,
          adapter: adapter,
          canUseBridge: canUseAnthropicChatBridge,
        ),
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
    return _chatRouter.chatWithTools(
      messages: messages,
      tools: tools,
      cancelToken: cancelToken,
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
    return _chatRouter.chatStream(
      messages: messages,
      tools: tools,
      cancelToken: cancelToken,
      fallback: () => super.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
    );
  }
}

Map<String, Object?>? buildAnthropicCompatMetadata(AnthropicConfig config) {
  final metadata = <String, Object?>{};
  if (config.user != null) {
    metadata['user_id'] = config.user;
  }

  final customMetadata = config.metadata;
  if (customMetadata != null) {
    metadata.addAll(
      customMetadata.map(
        (key, value) => MapEntry(key, compatNormalizeJsonValue(value)),
      ),
    );
  }

  return metadata.isEmpty ? null : metadata;
}

List<modern_anthropic.AnthropicMcpServer>? mapAnthropicCompatMcpServers(
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

List<modern_anthropic.AnthropicNativeTool>? buildAnthropicCompatNativeTools(
  AnthropicConfig config,
) {
  if (!config.webSearchEnabled) {
    return null;
  }

  final webSearchConfig = config.webSearchConfig;
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
