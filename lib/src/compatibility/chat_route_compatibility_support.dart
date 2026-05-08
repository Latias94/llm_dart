part of 'chat_route_compatibility.dart';

const Set<String> _httpExtensionKeys = legacyHttpExtensionKeys;
const _httpOnlyChatBridgeExtensionAllowlist = _ChatBridgeExtensionAllowlist(
  flatKeys: _httpExtensionKeys,
);

final class _ChatBridgeExtensionAllowlist {
  final Set<String> flatKeys;
  final Map<String, Set<String>> providerOptions;

  const _ChatBridgeExtensionAllowlist({
    required this.flatKeys,
    this.providerOptions = const {},
  });
}

bool _hasUnsupportedExtensions({
  required LLMConfig config,
  required _ChatBridgeExtensionAllowlist allowlist,
}) {
  for (final key in config.extensions.keys) {
    if (key == legacyProviderOptionsBagKey) {
      continue;
    }

    if (!allowlist.flatKeys.contains(key)) {
      return true;
    }
  }

  if (_hasUnsupportedProviderOptions(
    config: config,
    allowedProviderOptions: allowlist.providerOptions,
  )) {
    return true;
  }

  return false;
}

bool _hasUnsupportedProviderOptions({
  required LLMConfig config,
  required Map<String, Set<String>> allowedProviderOptions,
}) {
  if (!config.extensions.containsKey(legacyProviderOptionsBagKey)) {
    return false;
  }

  final providerOptions = legacyProviderOptionsBagOrNull(config);
  if (providerOptions == null) {
    return true;
  }

  for (final entry in providerOptions.entries) {
    final allowedKeys = allowedProviderOptions[entry.key];
    final namespaceOptions = legacyProviderOptionsNamespaceOrNull(
      config,
      entry.key,
    );

    if (allowedKeys == null || namespaceOptions == null) {
      return true;
    }

    for (final key in namespaceOptions.keys) {
      if (!allowedKeys.contains(key)) {
        return true;
      }
    }
  }

  return false;
}

bool _hasNonFunctionTools(List<Tool>? tools) {
  if (tools == null) {
    return false;
  }

  return tools.any((tool) => tool.toolType != 'function');
}

bool _canMapOpenAIBuiltInTools(List<OpenAIBuiltInTool>? tools) {
  if (tools == null) {
    return true;
  }

  return tools.every(
    (tool) =>
        tool is OpenAIWebSearchTool ||
        tool is OpenAIFileSearchTool ||
        tool is OpenAIComputerUseTool,
  );
}

bool _hasMessageDecorators(List<ChatMessage> messages) {
  return messages.any(
    (message) => message.name != null || message.extensions.isNotEmpty,
  );
}

bool _hasNamedMessages(List<ChatMessage> messages) {
  return messages.any((message) => message.name != null);
}

bool _hasOpenAICompatibleShellRequestConflict(
  LLMConfig config,
  List<ChatMessage> messages,
) {
  if (config.stopSequences case final stopSequences?
      when stopSequences.isNotEmpty) {
    return true;
  }

  if (config.user != null || config.serviceTier != null) {
    return true;
  }

  if (config.systemPrompt != null &&
      config.systemPrompt!.isNotEmpty &&
      messages.any((message) => message.role == ChatRole.system)) {
    return true;
  }

  return false;
}

bool _hasNonTextMessages(List<ChatMessage> messages) {
  return messages.any((message) => message.messageType is! TextMessage);
}

bool _hasUnsupportedTextToolReplayMessages(List<ChatMessage> messages) {
  for (final message in messages) {
    switch (message.messageType) {
      case TextMessage():
        break;
      case ToolUseMessage():
        if (message.role != ChatRole.assistant) {
          return true;
        }
      case ToolResultMessage():
        if (message.role != ChatRole.user) {
          return true;
        }
      case ImageMessage():
      case ImageUrlMessage():
      case FileMessage():
        return true;
    }
  }

  return false;
}

bool _systemMessagesLead(List<ChatMessage> messages) {
  var sawConversationMessage = false;

  for (final message in messages) {
    if (message.role == ChatRole.system) {
      if (sawConversationMessage) {
        return false;
      }
      continue;
    }

    sawConversationMessage = true;
  }

  return true;
}

bool _hasAnthropicParallelToolOverride(ToolChoice? toolChoice) {
  return switch (toolChoice) {
    AnyToolChoice(:final disableParallelToolUse) =>
      disableParallelToolUse == true,
    AutoToolChoice(:final disableParallelToolUse) =>
      disableParallelToolUse == true,
    SpecificToolChoice(:final disableParallelToolUse) =>
      disableParallelToolUse == true,
    _ => false,
  };
}
