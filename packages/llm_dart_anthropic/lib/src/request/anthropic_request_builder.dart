// Helper for building Anthropic request bodies from prompt-first ModelMessage
// conversations.

import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

import '../config/anthropic_config.dart';
import '../mcp/anthropic_mcp_models.dart';
import '../models/anthropic_models.dart';
import 'anthropic_cache_control_validator.dart';

/// Helper class to build Anthropic API request bodies (sub-package).
class AnthropicRequestBuilder {
  final AnthropicConfig config;

  AnthropicRequestBuilder(this.config);

  /// Compute model-specific max output tokens, mirroring the TypeScript
  /// `getMaxOutputTokensForModel` helper.
  _MaxOutputTokensInfo _getMaxOutputTokensForModel(String modelId) {
    if (modelId.contains('claude-sonnet-4-') ||
        modelId.contains('claude-3-7-sonnet') ||
        modelId.contains('claude-haiku-4-5')) {
      return const _MaxOutputTokensInfo(64000, true);
    } else if (modelId.contains('claude-opus-4-')) {
      return const _MaxOutputTokensInfo(32000, true);
    } else if (modelId.contains('claude-3-5-haiku')) {
      return const _MaxOutputTokensInfo(8192, true);
    } else if (modelId.contains('claude-3-haiku')) {
      return const _MaxOutputTokensInfo(4096, true);
    } else {
      // Fallback: use a conservative default and mark as unknown model
      // so we do not clamp user-provided values too aggressively.
      return const _MaxOutputTokensInfo(4096, false);
    }
  }

  /// Build request body from structured [ModelMessage] list.
  Map<String, dynamic> buildRequestBodyFromPrompt(
    List<ModelMessage> promptMessages,
    List<Tool>? tools,
    bool stream, {
    LanguageModelCallOptions? options,
  }) {
    final processedData = _processMessagesFromPrompt(promptMessages);
    // Per-call tools provided via [LanguageModelCallOptions] should take
    // precedence over the legacy `tools` argument.
    final effectiveTools = options?.resolveTools() ?? tools;
    final processedTools =
        _processToolsFromPrompt(promptMessages, effectiveTools);

    if (processedData.messages.isEmpty) {
      throw const InvalidRequestError(
        'At least one non-system message is required',
      );
    }

    _validateMessageSequence(processedData.messages);

    // Base max output tokens for this model, mirroring the TypeScript
    // implementation. When thinking is enabled, we will adjust this
    // value by the thinking budget and clamp to the model maximum.
    final maxInfo = _getMaxOutputTokensForModel(config.model);
    final baseMaxTokens =
        options?.maxTokens ?? config.maxTokens ?? maxInfo.maxOutputTokens;

    final thinkingEnabled = config.reasoning && config.supportsReasoning;
    final thinkingBudget = config.thinkingBudgetTokens;

    var effectiveMaxTokens = baseMaxTokens;

    if (thinkingEnabled && thinkingBudget != null) {
      // Adjust max tokens to account for thinking budget.
      effectiveMaxTokens = baseMaxTokens + thinkingBudget;

      // Clamp to known model limits to avoid exceeding Anthropic caps.
      if (maxInfo.knownModel && effectiveMaxTokens > maxInfo.maxOutputTokens) {
        effectiveMaxTokens = maxInfo.maxOutputTokens;
      }
    }

    final body = <String, dynamic>{
      'model': config.model,
      'messages': processedData.messages,
      'max_tokens': effectiveMaxTokens,
      'stream': stream,
    };

    _addSystemContentFromPrompt(body, processedData);
    final effectiveToolChoice = options?.toolChoice ?? config.toolChoice;
    _addTools(body, processedTools, toolChoice: effectiveToolChoice);
    _addOptionalParameters(body, options: options);

    return body;
  }

  ProcessedPrompt _processMessagesFromPrompt(
    List<ModelMessage> promptMessages,
  ) {
    final validator = AnthropicCacheControlValidator();

    final systemContent = <Map<String, dynamic>>[];
    final messages = <Map<String, dynamic>>[];

    for (final message in promptMessages) {
      switch (message.role) {
        case ChatRole.system:
          _convertSystemMessageFromPrompt(
            message,
            systemContent,
            validator,
          );
          break;
        case ChatRole.user:
        case ChatRole.assistant:
          messages.add(
            _convertNonSystemMessageFromPrompt(
              message,
              validator,
            ),
          );
          break;
      }
    }

    return ProcessedPrompt(
      systemContent: systemContent,
      messages: messages,
    );
  }

  /// Extract tools from prompt messages plus config-level tools.
  ProcessedTools _processToolsFromPrompt(
    List<ModelMessage> promptMessages,
    List<Tool>? configTools,
  ) {
    final messageTools = <Tool>[];
    Map<String, dynamic>? toolCacheControl;

    for (final prompt in promptMessages) {
      final result = _extractToolsFromPromptMessage(prompt);
      messageTools.addAll(result.tools);
      toolCacheControl ??= result.cacheControl;
    }

    final allTools = <Tool>[];
    allTools.addAll(messageTools);

    final effectiveTools = configTools ?? config.tools;
    if (effectiveTools != null) {
      allTools.addAll(effectiveTools);
    }

    return ProcessedTools(
      tools: allTools,
      cacheControl: toolCacheControl,
    );
  }

  void _convertSystemMessageFromPrompt(
    ModelMessage message,
    List<Map<String, dynamic>> systemContent,
    AnthropicCacheControlValidator validator,
  ) {
    if (message.parts.isEmpty && message.providerOptions.isEmpty) {
      return;
    }

    for (var i = 0; i < message.parts.length; i++) {
      final part = message.parts[i];
      final isLastPart = i == message.parts.length - 1;

      final partOptions =
          part.providerOptions?['anthropic'] ?? part.providerOptions;
      final messageOptions =
          message.providerOptions['anthropic'] ?? message.providerOptions;

      final cacheControl = validator.getCacheControl(
            partOptions,
            contextType: 'system message part',
            canCache: true,
          ) ??
          (isLastPart
              ? validator.getCacheControl(
                  messageOptions,
                  contextType: 'system message',
                  canCache: true,
                )
              : null);

      if (part is TextContentPart || part is ReasoningContentPart) {
        final text = part is TextContentPart
            ? part.text
            : (part as ReasoningContentPart).text;
        systemContent.add({
          'type': 'text',
          'text': text,
          'cache_control': cacheControl?.toJson(),
        });
      }
    }
  }

  Map<String, dynamic> _convertNonSystemMessageFromPrompt(
    ModelMessage message,
    AnthropicCacheControlValidator validator,
  ) {
    final content = <Map<String, dynamic>>[];
    final role = message.role == ChatRole.user ? 'user' : 'assistant';

    for (var i = 0; i < message.parts.length; i++) {
      final part = message.parts[i];
      final isLastPart = i == message.parts.length - 1;

      final partOptions =
          part.providerOptions?['anthropic'] ?? part.providerOptions;
      final messageOptions =
          message.providerOptions['anthropic'] ?? message.providerOptions;

      final cacheControl = validator.getCacheControl(
            partOptions,
            contextType: '$role message part',
            canCache: true,
          ) ??
          (isLastPart
              ? validator.getCacheControl(
                  messageOptions,
                  contextType: '$role message',
                  canCache: true,
                )
              : null);

      if (part is TextContentPart || part is ReasoningContentPart) {
        final text = part is TextContentPart
            ? part.text
            : (part as ReasoningContentPart).text;
        content.add({
          'type': 'text',
          'text': text,
          'cache_control': cacheControl?.toJson(),
        });
      } else if (part is FileContentPart) {
        _convertFilePartForPrompt(
          part,
          cacheControl,
          content,
        );
      } else if (part is UrlFileContentPart) {
        final mimeType = part.mime.mimeType;
        final text = '[URL-based files are not supported by Anthropic '
            '(mime: $mimeType). Provide the file bytes via FileContentPart instead: '
            '${part.url}]';
        content.add({
          'type': 'text',
          'text': text,
          'cache_control': cacheControl?.toJson(),
        });
      } else if (part is ToolCallContentPart && role == 'assistant') {
        _convertToolCallPartForPrompt(
          part,
          cacheControl,
          content,
        );
      } else if (part is ToolResultContentPart && role == 'user') {
        _convertToolResultPartForPrompt(
          part,
          cacheControl,
          content,
        );
      }
    }

    return {
      'role': role,
      'content': content,
    };
  }

  void _convertFilePartForPrompt(
    FileContentPart part,
    AnthropicCacheControl? cacheControl,
    List<Map<String, dynamic>> content,
  ) {
    final mimeType = part.mime.mimeType;

    if (mimeType.startsWith('image/')) {
      content.add({
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': mimeType,
          'data': base64Encode(part.data),
        },
        'cache_control': cacheControl?.toJson(),
      });
    } else if (mimeType == 'application/pdf') {
      if (!config.supportsPDF) {
        content.add({
          'type': 'text',
          'text': '[PDF documents are not supported by model ${config.model}]',
          'cache_control': cacheControl?.toJson(),
        });
      } else {
        content.add({
          'type': 'document',
          'source': {
            'type': 'base64',
            'media_type': mimeType,
            'data': base64Encode(part.data),
          },
          'cache_control': cacheControl?.toJson(),
        });
      }
    } else if (mimeType == 'text/plain') {
      content.add({
        'type': 'document',
        'source': {
          'type': 'text',
          'media_type': 'text/plain',
          'data': utf8.decode(part.data),
        },
        'cache_control': cacheControl?.toJson(),
      });
    } else {
      content.add({
        'type': 'text',
        'text':
            '[File type ${part.mime.description} (${part.mime.mimeType}) is not supported by Anthropic. Only PDF documents and plain text are supported as documents.]',
        'cache_control': cacheControl?.toJson(),
      });
    }
  }

  void _convertToolCallPartForPrompt(
    ToolCallContentPart part,
    AnthropicCacheControl? cacheControl,
    List<Map<String, dynamic>> content,
  ) {
    dynamic input;
    try {
      input = jsonDecode(part.argumentsJson);
    } catch (_) {
      input = part.argumentsJson;
    }

    final id = part.toolCallId ?? 'tool_${content.length}';

    content.add({
      'type': 'tool_use',
      'id': id,
      'name': part.toolName,
      'input': input,
      'cache_control': cacheControl?.toJson(),
    });
  }

  void _convertToolResultPartForPrompt(
    ToolResultContentPart part,
    AnthropicCacheControl? cacheControl,
    List<Map<String, dynamic>> content,
  ) {
    dynamic toolContent;
    bool? isError;

    final payload = part.payload;
    if (payload is ToolResultTextPayload) {
      toolContent = payload.value;
    } else if (payload is ToolResultJsonPayload) {
      toolContent = jsonEncode(payload.value);
    } else if (payload is ToolResultErrorPayload) {
      toolContent = payload.message;
      isError = true;
    } else if (payload is ToolResultContentPayload) {
      // For now, flatten nested parts into text segments.
      final texts = <String>[];
      for (final nested in payload.parts) {
        if (nested is TextContentPart) {
          texts.add(nested.text);
        }
      }
      toolContent = texts.join('\n');
    } else {
      toolContent = '';
    }

    content.add({
      'type': 'tool_result',
      'tool_use_id': part.toolCallId,
      'content': toolContent,
      'is_error': isError,
      'cache_control': cacheControl?.toJson(),
    });
  }

  ToolExtractionResult _extractToolsFromPromptMessage(ModelMessage message) {
    final tools = <Tool>[];
    Map<String, dynamic>? cacheControl;

    final rawProviderOptions = message.providerOptions['anthropic'];
    if (rawProviderOptions is Map<String, dynamic>) {
      final contentBlocks =
          rawProviderOptions['contentBlocks'] as List<dynamic>?;
      if (contentBlocks != null) {
        for (final block in contentBlocks) {
          if (block is Map<String, dynamic>) {
            if (block['cache_control'] != null && block['text'] == '') {
              cacheControl = block['cache_control'];
            } else if (block['type'] == 'tools') {
              tools.addAll(_convertToolsFromBlock(block));
            }
          }
        }
      }
    }

    return ToolExtractionResult(tools: tools, cacheControl: cacheControl);
  }

  List<Tool> _convertToolsFromBlock(Map<String, dynamic> toolsBlock) {
    final tools = <Tool>[];
    final toolsList = toolsBlock['tools'] as List<dynamic>?;

    if (toolsList != null) {
      for (final toolData in toolsList) {
        if (toolData is Map<String, dynamic>) {
          if (toolData.containsKey('function') &&
              toolData.containsKey('type')) {
            final function = toolData['function'] as Map<String, dynamic>;
            tools.add(Tool(
              toolType: toolData['type'] as String? ?? 'function',
              function: FunctionTool(
                name: function['name'] as String,
                description: function['description'] as String,
                parameters: ParametersSchema.fromJson(
                  function['parameters'] as Map<String, dynamic>,
                ),
              ),
            ));
          } else {
            try {
              tools.add(Tool.fromJson(toolData));
            } catch (_) {
              continue;
            }
          }
        }
      }
    }

    return tools;
  }

  void _addSystemContentFromPrompt(
      Map<String, dynamic> body, ProcessedPrompt data) {
    final allSystemContent = <Map<String, dynamic>>[];

    if (config.systemPrompt != null && config.systemPrompt!.isNotEmpty) {
      allSystemContent.add({
        'type': 'text',
        'text': config.systemPrompt!,
      });
    }

    allSystemContent.addAll(data.systemContent);

    if (allSystemContent.isNotEmpty) {
      body['system'] = allSystemContent;
    }
  }

  void _addTools(
    Map<String, dynamic> body,
    ProcessedTools processedTools, {
    ToolChoice? toolChoice,
  }) {
    if (processedTools.tools.isNotEmpty) {
      final convertedTools =
          processedTools.tools.map((t) => convertTool(t)).toList();

      if (processedTools.cacheControl != null && convertedTools.isNotEmpty) {
        convertedTools.last['cache_control'] = processedTools.cacheControl;
      }

      body['tools'] = convertedTools;

      if (toolChoice != null) {
        body['tool_choice'] = _convertToolChoice(toolChoice);
      }
    }
  }

  void _addOptionalParameters(
    Map<String, dynamic> body, {
    LanguageModelCallOptions? options,
  }) {
    final thinkingEnabled = config.reasoning && config.supportsReasoning;

    // Sampling parameters are not supported when thinking is enabled on
    // reasoning-capable models. We only forward them for standard calls.
    if (!thinkingEnabled) {
      final effectiveTemperature = options?.temperature ?? config.temperature;
      if (effectiveTemperature != null) {
        body['temperature'] = effectiveTemperature;
      }

      final effectiveTopP = options?.topP ?? config.topP;
      if (effectiveTopP != null) {
        body['top_p'] = effectiveTopP;
      }

      final effectiveTopK = options?.topK ?? config.topK;
      if (effectiveTopK != null) {
        body['top_k'] = effectiveTopK;
      }
    }

    if (thinkingEnabled) {
      final thinkingConfig = <String, dynamic>{
        'type': 'enabled',
      };

      if (config.thinkingBudgetTokens != null) {
        thinkingConfig['budget_tokens'] = config.thinkingBudgetTokens;
      }

      body['thinking'] = thinkingConfig;
    }

    final effectiveStopSequences =
        options?.stopSequences ?? config.stopSequences;
    if (effectiveStopSequences != null && effectiveStopSequences.isNotEmpty) {
      body['stop_sequences'] = effectiveStopSequences;
    }

    final effectiveServiceTier = options?.serviceTier ?? config.serviceTier;
    if (effectiveServiceTier != null) {
      body['service_tier'] = effectiveServiceTier.value;
    }

    final metadata = <String, dynamic>{};
    final effectiveUser = options?.user ?? config.user;
    if (effectiveUser != null) {
      metadata['user_id'] = effectiveUser;
    }

    final customMetadata =
        config.getExtension<Map<String, dynamic>>(LLMConfigKeys.metadata);
    if (customMetadata != null) {
      metadata.addAll(customMetadata);
    }

    final callMetadata = options?.metadata;
    if (callMetadata != null) {
      metadata.addAll(callMetadata);
    }

    if (metadata.isNotEmpty) {
      body['metadata'] = metadata;
    }

    final container = config.getExtension<String>(LLMConfigKeys.container);
    if (container != null) {
      body['container'] = container;
    }

    final mcpServers = config.getExtension<List<AnthropicMCPServer>>(
      LLMConfigKeys.mcpServers,
    );
    if (mcpServers != null && mcpServers.isNotEmpty) {
      body['mcp_servers'] =
          mcpServers.map((server) => server.toJson()).toList();
    }
  }

  Map<String, dynamic> convertTool(Tool tool) {
    try {
      if (tool.function.name == 'web_search') {
        final schema = tool.function.parameters.toJson();

        final inputSchema = Map<String, dynamic>.from(schema);
        if (inputSchema['type'] != 'object') {
          inputSchema['type'] = 'object';
        }
        if (!inputSchema.containsKey('properties')) {
          inputSchema['properties'] = <String, dynamic>{};
        }

        // Base definition for Anthropic web search tool.
        final toolDef = <String, dynamic>{
          'name': 'web_search',
          'description': tool.function.description.isNotEmpty
              ? tool.function.description
              : 'Search the web for current information',
          'input_schema': inputSchema,
          'type': 'web_search_20250305',
        };

        // Optionally augment with WebSearchConfig when provided via LLMConfig.
        final webSearchConfig = config.getExtension<WebSearchConfig>(
          LLMConfigKeys.webSearchConfig,
        );

        if (webSearchConfig != null) {
          if (webSearchConfig.maxUses != null) {
            toolDef['max_uses'] = webSearchConfig.maxUses;
          }
          if (webSearchConfig.allowedDomains != null) {
            toolDef['allowed_domains'] = webSearchConfig.allowedDomains;
          }
          if (webSearchConfig.blockedDomains != null) {
            toolDef['blocked_domains'] = webSearchConfig.blockedDomains;
          }
          if (webSearchConfig.location != null) {
            toolDef['user_location'] = webSearchConfig.location!.toJson();
          }
        }

        return toolDef;
      }

      final schema = tool.function.parameters.toJson();

      if (schema['type'] != 'object') {
        throw ArgumentError(
          'Anthropic tools require input_schema to be of type "object". '
          'Tool "${tool.function.name}" has type "${schema['type']}".',
        );
      }

      final inputSchema = Map<String, dynamic>.from(schema);
      if (!inputSchema.containsKey('properties')) {
        inputSchema['properties'] = <String, dynamic>{};
      }

      return {
        'name': tool.function.name,
        'description': tool.function.description.isNotEmpty
            ? tool.function.description
            : 'No description provided',
        'input_schema': inputSchema,
      };
    } catch (e) {
      throw ArgumentError(
        'Failed to convert tool "${tool.function.name}" to Anthropic format: $e',
      );
    }
  }

  dynamic _convertToolChoice(ToolChoice toolChoice) {
    switch (toolChoice) {
      case AutoToolChoice(disableParallelToolUse: final disableParallel):
        if (disableParallel == true) {
          return {'type': 'auto', 'disable_parallel_tool_use': true};
        }
        return 'auto';
      case AnyToolChoice(disableParallelToolUse: final disableParallel):
        if (disableParallel == true) {
          return {'type': 'any', 'disable_parallel_tool_use': true};
        }
        return 'any';
      case SpecificToolChoice(
          toolName: final toolName,
          disableParallelToolUse: final disableParallel
        ):
        final result = <String, dynamic>{'type': 'tool', 'name': toolName};
        if (disableParallel == true) {
          result['disable_parallel_tool_use'] = true;
        }
        return result;
      case NoneToolChoice():
        return 'none';
    }
  }

  void _validateMessageSequence(List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) return;

    for (int i = 0; i < messages.length; i++) {
      final content = messages[i]['content'];
      if (content is List && content.isEmpty) {
        throw const InvalidRequestError('Message content cannot be empty');
      }
      if (content is String && content.trim().isEmpty) {
        throw const InvalidRequestError('Message content cannot be empty');
      }
    }
  }
}

class ProcessedPrompt {
  final List<Map<String, dynamic>> systemContent;
  final List<Map<String, dynamic>> messages;

  ProcessedPrompt({
    required this.systemContent,
    required this.messages,
  });
}

class ProcessedTools {
  final List<Tool> tools;
  final Map<String, dynamic>? cacheControl;

  ProcessedTools({
    required this.tools,
    this.cacheControl,
  });
}

class ToolExtractionResult {
  final List<Tool> tools;
  final Map<String, dynamic>? cacheControl;

  ToolExtractionResult({
    required this.tools,
    this.cacheControl,
  });
}

/// Internal helper mirroring the TypeScript getMaxOutputTokensForModel.
class _MaxOutputTokensInfo {
  final int maxOutputTokens;
  final bool knownModel;

  const _MaxOutputTokensInfo(this.maxOutputTokens, this.knownModel);
}
