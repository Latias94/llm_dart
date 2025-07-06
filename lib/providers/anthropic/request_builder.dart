import 'dart:convert';

import '../../core/llm_error.dart';
import '../../models/chat_models.dart';
import '../../models/tool_models.dart';
import 'config.dart';
import 'mcp_models.dart';

/// Helper class to build Anthropic API request bodies
/// Separates the complex request building logic into focused methods
class AnthropicRequestBuilder {
  final AnthropicConfig config;

  AnthropicRequestBuilder(this.config);

  /// Build complete request body for Anthropic API
  Map<String, dynamic> buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
  ) {
    // Extract processed data
    final processedData = _processMessages(messages);
    final processedTools = _processTools(messages, tools);

    // Validate that we have at least one non-system message
    if (processedData.anthropicMessages.isEmpty) {
      throw const InvalidRequestError(
          'At least one non-system message is required');
    }

    // Ensure messages follow Anthropic's requirements
    _validateMessageSequence(processedData.anthropicMessages);

    // Build base request body
    final body = <String, dynamic>{
      'model': config.model,
      'messages': processedData.anthropicMessages,
      'max_tokens': config.maxTokens ?? 1024,
      'stream': stream,
    };

    // Add system content if present
    _addSystemContent(body, processedData);

    // Add tools if present
    _addTools(body, processedTools);

    // Add optional parameters
    _addOptionalParameters(body);

    return body;
  }

  /// Process all messages and extract system/anthropic content
  ProcessedMessages _processMessages(List<ChatMessage> messages) {
    final anthropicMessages = <Map<String, dynamic>>[];
    final systemContentBlocks = <Map<String, dynamic>>[];
    final systemMessages = <String>[];
    Map<String, dynamic>? systemCacheControl;

    for (final message in messages) {
      if (message.role == ChatRole.system) {
        final result = _processSystemMessage(message);
        systemContentBlocks.addAll(result.contentBlocks);
        systemMessages.addAll(result.plainMessages);
        systemCacheControl ??= result.cacheControl;
      } else {
        anthropicMessages.add(_convertMessage(message));
      }
    }

    return ProcessedMessages(
      anthropicMessages: anthropicMessages,
      systemContentBlocks: systemContentBlocks,
      systemMessages: systemMessages,
      systemCacheControl: systemCacheControl,
    );
  }

  /// Process a single system message
  SystemMessageResult _processSystemMessage(ChatMessage message) {
    final contentBlocks = <Map<String, dynamic>>[];
    final plainMessages = <String>[];
    Map<String, dynamic>? cacheControl;

    final anthropicData =
        message.getExtension<Map<String, dynamic>>('anthropic');

    if (anthropicData != null) {
      final blocks = anthropicData['contentBlocks'] as List<dynamic>?;
      if (blocks != null) {
        for (final block in blocks) {
          if (block is Map<String, dynamic>) {
            // Extract cache control marker
            if (block['cache_control'] != null && block['text'] == '') {
              cacheControl = block['cache_control'];
              continue;
            }
            // Skip tools blocks - handled separately
            if (block['type'] == 'tools') {
              continue;
            }
            contentBlocks.add(block);
          }
        }
      }

      // Apply cache control to system content
      if (message.content.isNotEmpty && cacheControl != null) {
        contentBlocks.add({
          'type': 'text',
          'text': message.content,
          'cache_control': cacheControl,
        });
      }
    } else {
      plainMessages.add(message.content);
    }

    return SystemMessageResult(
      contentBlocks: contentBlocks,
      plainMessages: plainMessages,
      cacheControl: cacheControl,
    );
  }

  /// Process tools from messages and config
  ProcessedTools _processTools(
      List<ChatMessage> messages, List<Tool>? configTools) {
    final messageTools = <Tool>[];
    Map<String, dynamic>? toolCacheControl;

    // Extract tools and cache control from messages
    for (final message in messages) {
      final result = _extractToolsFromMessage(message);
      messageTools.addAll(result.tools);
      toolCacheControl ??= result.cacheControl;
    }

    // Combine with config tools
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

  /// Extract tools from a single message
  ToolExtractionResult _extractToolsFromMessage(ChatMessage message) {
    final tools = <Tool>[];
    Map<String, dynamic>? cacheControl;

    final anthropicData =
        message.getExtension<Map<String, dynamic>>('anthropic');
    if (anthropicData != null) {
      final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>?;
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

  /// Convert tools from a tools block
  List<Tool> _convertToolsFromBlock(Map<String, dynamic> toolsBlock) {
    final tools = <Tool>[];
    final toolsList = toolsBlock['tools'] as List<dynamic>?;

    if (toolsList != null) {
      for (final toolData in toolsList) {
        if (toolData is Map<String, dynamic>) {
          // Check if this is already a Tool.toJson() format (with 'type' and 'function' fields)
          if (toolData.containsKey('function') && toolData.containsKey('type')) {
            final function = toolData['function'] as Map<String, dynamic>;
            tools.add(Tool(
              toolType: toolData['type'] as String? ?? 'function',
              function: FunctionTool(
                name: function['name'] as String,
                description: function['description'] as String,
                parameters: ParametersSchema.fromJson(
                    function['parameters'] as Map<String, dynamic>),
              ),
            ));
          } else {
            // This might be a direct tool definition, try to parse it as Tool.fromJson
            try {
              tools.add(Tool.fromJson(toolData));
            } catch (e) {
              // If parsing fails, skip this tool and log a warning
              // This prevents the entire request from failing
              continue;
            }
          }
        }
      }
    }

    return tools;
  }

  /// Add system content to request body
  void _addSystemContent(Map<String, dynamic> body, ProcessedMessages data) {
    final allSystemContent = <Map<String, dynamic>>[];

    // Add config system prompt
    if (config.systemPrompt != null && config.systemPrompt!.isNotEmpty) {
      allSystemContent.add({
        'type': 'text',
        'text': config.systemPrompt!,
      });
    }

    // Add processed content blocks
    allSystemContent.addAll(data.systemContentBlocks);

    // Add plain system messages
    for (final message in data.systemMessages) {
      allSystemContent.add({
        'type': 'text',
        'text': message,
      });
    }

    if (allSystemContent.isNotEmpty) {
      body['system'] = allSystemContent;
    }
  }

  /// Add tools to request body
  void _addTools(Map<String, dynamic> body, ProcessedTools processedTools) {
    if (processedTools.tools.isNotEmpty) {
      final convertedTools =
          processedTools.tools.map((t) => convertTool(t)).toList();

      // Apply cache control to last tool
      if (processedTools.cacheControl != null && convertedTools.isNotEmpty) {
        convertedTools.last['cache_control'] = processedTools.cacheControl;
      }

      body['tools'] = convertedTools;

      // Add tool_choice if specified
      if (config.toolChoice != null) {
        body['tool_choice'] = _convertToolChoice(config.toolChoice!);
      }
    }
  }

  /// Add optional parameters to request body
  void _addOptionalParameters(Map<String, dynamic> body) {
    // Add temperature with validation
    if (config.temperature != null) {
      body['temperature'] = config.temperature;
    }

    // Add top_p with validation
    if (config.topP != null) {
      body['top_p'] = config.topP;
    }

    // Add top_k with validation
    if (config.topK != null) {
      body['top_k'] = config.topK;
    }

    // Add thinking configuration if reasoning is enabled
    if (config.reasoning) {
      final thinkingConfig = <String, dynamic>{
        'type': 'enabled',
      };

      // Add budget tokens if specified
      if (config.thinkingBudgetTokens != null) {
        thinkingConfig['budget_tokens'] = config.thinkingBudgetTokens;
      }

      body['thinking'] = thinkingConfig;
    }

    // Add stop sequences if provided
    if (config.stopSequences != null && config.stopSequences!.isNotEmpty) {
      body['stop_sequences'] = config.stopSequences;
    }

    // Add service tier if specified
    if (config.serviceTier != null) {
      body['service_tier'] = config.serviceTier!.value;
    }

    // Add metadata if user is specified or extensions contain metadata
    final metadata = <String, dynamic>{};
    if (config.user != null) {
      metadata['user_id'] = config.user;
    }

    // Add custom metadata from extensions
    final customMetadata =
        config.getExtension<Map<String, dynamic>>('metadata');
    if (customMetadata != null) {
      metadata.addAll(customMetadata);
    }

    if (metadata.isNotEmpty) {
      body['metadata'] = metadata;
    }

    // Add container identifier from extensions
    final container = config.getExtension<String>('container');
    if (container != null) {
      body['container'] = container;
    }

    // Add MCP servers from extensions
    final mcpServers =
        config.getExtension<List<AnthropicMCPServer>>('mcpServers');
    if (mcpServers != null && mcpServers.isNotEmpty) {
      body['mcp_servers'] =
          mcpServers.map((server) => server.toJson()).toList();
    }
  }

  /// Convert a ChatMessage to Anthropic API format
  Map<String, dynamic> _convertMessage(ChatMessage message) {
    final content = <Map<String, dynamic>>[];

    // Check for Anthropic-specific extensions first
    final anthropicData =
        message.getExtension<Map<String, dynamic>>('anthropic');

    // Handle cache control from extensions
    Map<String, dynamic>? cacheControl;
    if (anthropicData != null) {
      final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>?;
      if (contentBlocks != null) {
        for (final block in contentBlocks) {
          if (block is Map<String, dynamic>) {
            // Check for cache control marker
            if (block['cache_control'] != null && block['text'] == '') {
              cacheControl = block['cache_control'];
              continue; // Skip adding empty cache marker
            }
            content.add(block);
          }
        }
      }

      // Add regular content with cache if flag is set
      if (message.content.isNotEmpty) {
        final textBlock = <String, dynamic>{
          'type': 'text',
          'text': message.content
        };
        if (cacheControl != null) {
          textBlock['cache_control'] = cacheControl;
        }
        content.add(textBlock);
      }
    } else {
      // Fallback to standard message type handling
      switch (message.messageType) {
        case TextMessage():
          content.add({'type': 'text', 'text': message.content});
          break;
        case ImageMessage(mime: final mime, data: final data):
          content.add({
            'type': 'image',
            'source': {
              'type': 'base64',
              'media_type': mime.mimeType,
              'data': data,
            },
          });
          break;
        case ToolUseMessage(toolCalls: final toolCalls):
          for (final toolCall in toolCalls) {
            try {
              final input = jsonDecode(toolCall.function.arguments);
              content.add({
                'type': 'tool_use',
                'id': toolCall.id,
                'name': toolCall.function.name,
                'input': input,
              });
            } catch (e) {
              // If JSON parsing fails, add an error message instead
              content.add({
                'type': 'text',
                'text':
                    '[Error: Invalid tool call arguments for ${toolCall.function.name}]',
              });
            }
          }
          break;
        case ToolResultMessage(results: final results):
          for (final result in results) {
            // Parse the result content to determine if it's an error
            bool isError = false;
            String resultContent = result.function.arguments;

            // Try to parse as JSON to check for error indicators
            try {
              final parsed = jsonDecode(resultContent);
              if (parsed is Map<String, dynamic>) {
                isError = parsed['error'] != null ||
                    parsed['is_error'] == true ||
                    parsed['success'] == false;
              }
            } catch (e) {
              // If not valid JSON, check for common error patterns
              final lowerContent = resultContent.toLowerCase();
              isError = lowerContent.contains('error') ||
                  lowerContent.contains('failed') ||
                  lowerContent.contains('exception');
            }

            content.add({
              'type': 'tool_result',
              'tool_use_id': result.id,
              'content': resultContent,
              'is_error': isError,
            });
          }
          break;
        default:
          content.add({
            'type': 'text',
            'text': message.content,
          });
      }
    }

    return {
      'role': message.role.name,
      'content': content,
    };
  }

  /// Convert a Tool to Anthropic API format
  Map<String, dynamic> convertTool(Tool tool) {
    try {
      final schema = tool.function.parameters.toJson();

      // Anthropic requires input_schema to be a valid JSON Schema object
      // According to official docs, it should be type "object"
      if (schema['type'] != 'object') {
        // Provide helpful error message with suggestion
        throw ArgumentError(
            'Anthropic tools require input_schema to be of type "object". '
            'Tool "${tool.function.name}" has type "${schema['type']}". '
            '\n\nTo fix this, update your tool definition:\n'
            'ParametersSchema(\n'
            '  schemaType: "object",  // <- Change this to "object"\n'
            '  properties: {...},\n'
            '  required: [...],\n'
            ')\n\n'
            'See: https://docs.anthropic.com/en/api/messages#tools');
      }

      // Ensure required fields are present
      final inputSchema = Map<String, dynamic>.from(schema);

      // Add properties if missing (empty object is valid)
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
      // Re-throw with more context
      throw ArgumentError(
          'Failed to convert tool "${tool.function.name}" to Anthropic format: $e');
    }
  }

  /// Convert ToolChoice to Anthropic API format
  dynamic _convertToolChoice(ToolChoice toolChoice) {
    switch (toolChoice) {
      case AutoToolChoice(disableParallelToolUse: final disableParallel):
        if (disableParallel == true) {
          return {'type': 'auto', 'disable_parallel_tool_use': true};
        }
        return 'auto';  // Return string for simple auto choice
      case AnyToolChoice(disableParallelToolUse: final disableParallel):
        if (disableParallel == true) {
          return {'type': 'any', 'disable_parallel_tool_use': true};
        }
        return 'any';   // Return string for simple any choice
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
        // For Anthropic, 'none' is a string, not an object
        return 'none';
    }
  }

  /// Validate that messages follow Anthropic's requirements
  void _validateMessageSequence(List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) return;

    // First message should be from user (Anthropic requirement)
    if (messages.first['role'] != 'user') {
      // Note: In a real implementation, we'd use the logger from the client
      // For now, we'll just validate without logging
    }

    // Validate message content is not empty
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

/// Data classes for better organization
class ProcessedMessages {
  final List<Map<String, dynamic>> anthropicMessages;
  final List<Map<String, dynamic>> systemContentBlocks;
  final List<String> systemMessages;
  final Map<String, dynamic>? systemCacheControl;

  ProcessedMessages({
    required this.anthropicMessages,
    required this.systemContentBlocks,
    required this.systemMessages,
    this.systemCacheControl,
  });
}

class SystemMessageResult {
  final List<Map<String, dynamic>> contentBlocks;
  final List<String> plainMessages;
  final Map<String, dynamic>? cacheControl;

  SystemMessageResult({
    required this.contentBlocks,
    required this.plainMessages,
    this.cacheControl,
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
