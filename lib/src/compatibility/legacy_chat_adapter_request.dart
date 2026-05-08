part of 'legacy_chat_adapter.dart';

final class _LegacyChatRequestBuilder {
  final LLMConfig config;
  final core.ProviderInvocationOptions? providerOptions;

  const _LegacyChatRequestBuilder({
    required this.config,
    this.providerOptions,
  });

  core.GenerateTextRequest build(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    required List<core.PromptMessage> Function(List<ChatMessage> messages)
        convertMessagesCallback,
    core.ProviderInvocationOptions? providerOptionsOverride,
  }) {
    final effectiveTools = tools ?? config.tools ?? const <Tool>[];
    final convertedTools =
        effectiveTools.map(_convertTool).toList(growable: false);
    final convertedToolChoice =
        convertedTools.isEmpty ? null : _convertToolChoice(config.toolChoice);

    return core.GenerateTextRequest(
      prompt: convertMessagesCallback(messages),
      tools: convertedTools,
      toolChoice: convertedToolChoice,
      options: core.GenerateTextOptions(
        maxOutputTokens: config.maxTokens,
        temperature: config.temperature,
        stopSequences: config.stopSequences,
        topP: config.topP,
        topK: config.topK,
        responseFormat: _buildCompatResponseFormat(config.legacyJsonSchema),
      ),
      callOptions: core.CallOptions(
        timeout: config.timeout,
        providerOptions: providerOptionsOverride ?? providerOptions,
      ),
    );
  }
}
