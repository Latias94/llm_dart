part of 'chat_route_compatibility.dart';

const Set<String> _httpExtensionKeys = legacyHttpExtensionKeys;

bool _hasUnsupportedExtensions({
  required LLMConfig config,
  required Set<String> allowedKeys,
  Map<String, Set<String>> allowedProviderOptions = const {},
}) {
  for (final key in config.extensions.keys) {
    if (key == legacyProviderOptionsBagKey) {
      continue;
    }

    if (!allowedKeys.contains(key)) {
      return true;
    }
  }

  if (_hasUnsupportedProviderOptions(
    config: config,
    allowedProviderOptions: allowedProviderOptions,
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

bool _hasGoogleStructuredOutputConflict(
  LLMConfig config,
  List<dynamic>? responseModalities,
) {
  final structuredOutput = getLegacyProviderOption<StructuredOutputFormat>(
    config,
    LegacyProviderOptionNamespaces.google,
    LegacyExtensionKeys.jsonSchema,
  );
  if (structuredOutput == null) {
    return false;
  }

  if (getLegacyProviderOption<bool>(
        config,
        LegacyProviderOptionNamespaces.google,
        LegacyExtensionKeys.enableImageGeneration,
      ) ==
      true) {
    return true;
  }

  if (responseModalities != null &&
      responseModalities
          .any((value) => value.toString().toUpperCase() != 'TEXT')) {
    return true;
  }

  return false;
}

bool _hasMessageDecorators(List<ChatMessage> messages) {
  return messages.any(
    (message) => message.name != null || message.extensions.isNotEmpty,
  );
}

bool _hasNamedMessages(List<ChatMessage> messages) {
  return messages.any((message) => message.name != null);
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
