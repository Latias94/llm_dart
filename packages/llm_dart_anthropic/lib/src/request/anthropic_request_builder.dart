import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

import '../config/anthropic_config.dart';
import '../mcp/anthropic_mcp_models.dart';

/// Helper class to build Anthropic API request bodies (sub-package).
class AnthropicRequestBuilder {
  final AnthropicConfig config;

  AnthropicRequestBuilder(this.config);

  Map<String, dynamic> buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
  ) {
    final processedData = _processMessages(messages);
    final processedTools = _processTools(messages, tools);

    if (processedData.anthropicMessages.isEmpty) {
      throw const InvalidRequestError(
        'At least one non-system message is required',
      );
    }

    _validateMessageSequence(processedData.anthropicMessages);

    final body = <String, dynamic>{
      'model': config.model,
      'messages': processedData.anthropicMessages,
      'max_tokens': config.maxTokens ?? 1024,
      'stream': stream,
    };

    _addSystemContent(body, processedData);
    _addTools(body, processedTools);
    _addOptionalParameters(body);

    return body;
  }

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
            if (block['cache_control'] != null && block['text'] == '') {
              cacheControl = block['cache_control'];
              continue;
            }
            if (block['type'] == 'tools') {
              continue;
            }
            contentBlocks.add(block);
          }
        }
      }

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

  ProcessedTools _processTools(
    List<ChatMessage> messages,
    List<Tool>? configTools,
  ) {
    final messageTools = <Tool>[];
    Map<String, dynamic>? toolCacheControl;

    for (final message in messages) {
      final result = _extractToolsFromMessage(message);
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

  void _addSystemContent(Map<String, dynamic> body, ProcessedMessages data) {
    final allSystemContent = <Map<String, dynamic>>[];

    if (config.systemPrompt != null && config.systemPrompt!.isNotEmpty) {
      allSystemContent.add({
        'type': 'text',
        'text': config.systemPrompt!,
      });
    }

    allSystemContent.addAll(data.systemContentBlocks);

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

  void _addTools(Map<String, dynamic> body, ProcessedTools processedTools) {
    if (processedTools.tools.isNotEmpty) {
      final convertedTools =
          processedTools.tools.map((t) => convertTool(t)).toList();

      if (processedTools.cacheControl != null && convertedTools.isNotEmpty) {
        convertedTools.last['cache_control'] = processedTools.cacheControl;
      }

      body['tools'] = convertedTools;

      if (config.toolChoice != null) {
        body['tool_choice'] = _convertToolChoice(config.toolChoice!);
      }
    }
  }

  void _addOptionalParameters(Map<String, dynamic> body) {
    if (config.temperature != null) {
      body['temperature'] = config.temperature;
    }

    if (config.topP != null) {
      body['top_p'] = config.topP;
    }

    if (config.topK != null) {
      body['top_k'] = config.topK;
    }

    if (config.reasoning) {
      final thinkingConfig = <String, dynamic>{
        'type': 'enabled',
      };

      if (config.thinkingBudgetTokens != null) {
        thinkingConfig['budget_tokens'] = config.thinkingBudgetTokens;
      }

      body['thinking'] = thinkingConfig;
    }

    if (config.stopSequences != null && config.stopSequences!.isNotEmpty) {
      body['stop_sequences'] = config.stopSequences;
    }

    if (config.serviceTier != null) {
      body['service_tier'] = config.serviceTier!.value;
    }

    final metadata = <String, dynamic>{};
    if (config.user != null) {
      metadata['user_id'] = config.user;
    }

    final customMetadata =
        config.getExtension<Map<String, dynamic>>(LLMConfigKeys.metadata);
    if (customMetadata != null) {
      metadata.addAll(customMetadata);
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

  Map<String, dynamic> _convertMessage(ChatMessage message) {
    final content = <Map<String, dynamic>>[];

    final anthropicData =
        message.getExtension<Map<String, dynamic>>('anthropic');

    Map<String, dynamic>? cacheControl;
    if (anthropicData != null) {
      final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>?;
      if (contentBlocks != null) {
        for (final block in contentBlocks) {
          if (block is Map<String, dynamic>) {
            if (block['cache_control'] != null && block['text'] == '') {
              cacheControl = block['cache_control'];
              continue;
            }
            if (block['type'] == 'tools') {
              continue;
            }
            content.add(block);
          }
        }
      }

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
      switch (message.messageType) {
        case TextMessage():
          content.add({'type': 'text', 'text': message.content});
          break;
        case ImageMessage(mime: final mime, data: final data):
          final supportedFormats = [
            'image/jpeg',
            'image/png',
            'image/gif',
            'image/webp'
          ];
          if (!supportedFormats.contains(mime.mimeType)) {
            content.add({
              'type': 'text',
              'text':
                  '[Unsupported image format: ${mime.mimeType}. Supported formats: ${supportedFormats.join(', ')}]',
            });
          } else {
            content.add({
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': mime.mimeType,
                'data': base64Encode(data),
              },
            });
          }
          break;
        case FileMessage(mime: final mime, data: final data):
          if (mime.mimeType == 'application/pdf') {
            if (!config.supportsPDF) {
              content.add({
                'type': 'text',
                'text':
                    '[PDF documents are not supported by model ${config.model}]',
              });
            } else {
              content.add({
                'type': 'document',
                'source': {
                  'type': 'base64',
                  'media_type': 'application/pdf',
                  'data': base64Encode(data),
                },
              });
            }
          } else {
            content.add({
              'type': 'text',
              'text':
                  '[File type ${mime.description} (${mime.mimeType}) is not supported by Anthropic. Only PDF documents are supported.]',
            });
          }
          break;
        case ImageUrlMessage(url: final url):
          content.add({
            'type': 'text',
            'text':
                '[Image URL not supported by Anthropic. Please upload the image directly: $url]',
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
            bool isError = false;
            String resultContent = result.function.arguments;

            try {
              final parsed = jsonDecode(resultContent);
              if (parsed is Map<String, dynamic>) {
                isError = parsed['error'] != null ||
                    parsed['is_error'] == true ||
                    parsed['success'] == false;
              }
            } catch (_) {
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
      }
    }

    return {'role': message.role.name, 'content': content};
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

        final toolDef = <String, dynamic>{
          'name': 'web_search',
          'description': tool.function.description.isNotEmpty
              ? tool.function.description
              : 'Search the web for current information',
          'input_schema': inputSchema,
          'type': 'web_search_20250305',
        };

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
