import 'package:llm_dart_community/llm_dart_community.dart' as modern_community;
import 'package:llm_dart_core/llm_dart_core.dart' as core;

import '../../../core/config.dart';
import '../../../models/chat_models.dart';
import '../../../providers/ollama/config.dart';
import '../../config/legacy_config_keys.dart';
import '../legacy_chat_adapter.dart';

/// Root-compatibility glue for the Ollama provider shell.
///
/// This keeps compatibility-specific config shaping, bridge gating, and the
/// legacy chat adapter out of the provider implementation file so the root
/// provider can act more clearly as a shell above package-owned modern models.
final class OllamaCompatShellSupport {
  final LLMConfig compatConfig;
  final LegacyChatCapabilityAdapter compatChat;
  final core.EmbeddingModel embeddingModel;

  const OllamaCompatShellSupport._({
    required this.compatConfig,
    required this.compatChat,
    required this.embeddingModel,
  });

  factory OllamaCompatShellSupport({
    required modern_community.Ollama modernProvider,
    required OllamaConfig config,
  }) {
    final compatConfig = _toCompatConfig(config);

    return OllamaCompatShellSupport._(
      compatConfig: compatConfig,
      compatChat: LegacyChatCapabilityAdapter(
        model: modernProvider.chatModel(config.model),
        config: compatConfig,
        providerOptions: _buildCompatProviderOptions(config),
      ),
      embeddingModel: modernProvider.embeddingModel(config.model),
    );
  }

  bool canUseChatBridge(List<ChatMessage> messages) {
    if (messages.any((message) => message.name != null)) {
      return false;
    }

    final hasConfigSystemPrompt =
        compatConfig.systemPrompt != null && compatConfig.systemPrompt!.isNotEmpty;
    if (hasConfigSystemPrompt &&
        messages.any((message) => message.role == ChatRole.system)) {
      return false;
    }

    return true;
  }
}

LLMConfig _toCompatConfig(OllamaConfig config) {
  return LLMConfig(
    apiKey: config.apiKey,
    baseUrl: config.baseUrl,
    model: config.model,
    maxTokens: config.maxTokens,
    temperature: config.temperature,
    systemPrompt: config.systemPrompt,
    timeout: config.timeout,
    topP: config.topP,
    topK: config.topK,
    tools: config.tools,
    extensions: {
      if (config.jsonSchema != null)
        LegacyExtensionKeys.jsonSchema: config.jsonSchema!,
      if (config.numCtx != null) LegacyExtensionKeys.numCtx: config.numCtx!,
      if (config.numGpu != null) LegacyExtensionKeys.numGpu: config.numGpu!,
      if (config.numThread != null)
        LegacyExtensionKeys.numThread: config.numThread!,
      if (config.numa != null) LegacyExtensionKeys.numa: config.numa!,
      if (config.numBatch != null)
        LegacyExtensionKeys.numBatch: config.numBatch!,
      if (config.keepAlive != null)
        LegacyExtensionKeys.keepAlive: config.keepAlive!,
      if (config.raw != null) LegacyExtensionKeys.raw: config.raw!,
      if (config.reasoning != null)
        LegacyExtensionKeys.reasoning: config.reasoning!,
    },
  );
}

modern_community.OllamaGenerateTextOptions _buildCompatProviderOptions(
  OllamaConfig config,
) {
  return modern_community.OllamaGenerateTextOptions(
    numCtx: config.numCtx,
    numGpu: config.numGpu,
    numThread: config.numThread,
    numBatch: config.numBatch,
    numa: config.numa,
    keepAlive: config.keepAlive ?? '5m',
    raw: config.raw == true ? true : null,
    reasoning: config.reasoning,
  );
}
