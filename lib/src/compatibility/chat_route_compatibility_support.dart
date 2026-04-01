part of 'chat_route_compatibility.dart';

const Set<String> _httpExtensionKeys = {
  'customHeaders',
  'connectionTimeout',
  'receiveTimeout',
  'sendTimeout',
  'enableHttpLogging',
  'httpProxy',
  'bypassSSLVerification',
  'sslCertificate',
  'customTransportClient',
  'customDio',
};

bool _hasUnsupportedExtensions({
  required LLMConfig config,
  required Set<String> allowedKeys,
}) {
  for (final key in config.extensions.keys) {
    if (!allowedKeys.contains(key)) {
      return true;
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
  final structuredOutput =
      config.getExtension<StructuredOutputFormat>('jsonSchema');
  if (structuredOutput == null) {
    return false;
  }

  if (config.getExtension<bool>('enableImageGeneration') == true) {
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

bool hasEnabledWebSearch(LLMConfig config) {
  return config.getExtension<bool>('webSearchEnabled') == true ||
      config.getExtension<WebSearchConfig>('webSearchConfig') != null;
}
