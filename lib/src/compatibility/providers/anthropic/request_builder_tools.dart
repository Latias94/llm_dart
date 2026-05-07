part of 'request_builder.dart';

ProcessedTools _processAnthropicTools(
  AnthropicConfig config,
  List<ChatMessage> messages,
  List<Tool>? configTools,
) {
  final messageTools = <Tool>[];
  Map<String, dynamic>? toolCacheControl;

  for (final message in messages) {
    final result = _extractAnthropicToolsFromMessage(message);
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

ToolExtractionResult _extractAnthropicToolsFromMessage(ChatMessage message) {
  final tools = <Tool>[];
  Map<String, dynamic>? cacheControl;

  final anthropicData = message.getExtension<Map<String, dynamic>>(
    'anthropic',
  );
  if (anthropicData != null) {
    final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>?;
    if (contentBlocks != null) {
      for (final block in contentBlocks) {
        if (block is Map<String, dynamic>) {
          if (block['cache_control'] != null && block['text'] == '') {
            cacheControl = block['cache_control'];
          } else if (block['type'] == 'tools') {
            tools.addAll(_convertAnthropicToolsFromBlock(block));
          }
        }
      }
    }
  }

  return ToolExtractionResult(tools: tools, cacheControl: cacheControl);
}

List<Tool> _convertAnthropicToolsFromBlock(Map<String, dynamic> toolsBlock) {
  final tools = <Tool>[];
  final toolsList = toolsBlock['tools'] as List<dynamic>?;

  if (toolsList != null) {
    for (final toolData in toolsList) {
      if (toolData is Map<String, dynamic>) {
        if (toolData.containsKey('function') && toolData.containsKey('type')) {
          final function = toolData['function'] as Map<String, dynamic>;
          tools.add(
            Tool(
              toolType: toolData['type'] as String? ?? 'function',
              function: FunctionTool(
                name: function['name'] as String,
                description: function['description'] as String,
                parameters: ParametersSchema.fromJson(
                  function['parameters'] as Map<String, dynamic>,
                ),
              ),
            ),
          );
        } else {
          try {
            tools.add(Tool.fromJson(toolData));
          } catch (e) {
            continue;
          }
        }
      }
    }
  }

  return tools;
}

Map<String, dynamic> _convertAnthropicTool(
  AnthropicConfig config,
  Tool tool,
) {
  try {
    if (tool.function.name == 'web_search') {
      final webSearchConfig = config.webSearchConfig;

      final toolDef = <String, dynamic>{
        'type': webSearchConfig?.mode ?? 'web_search_20250305',
        'name': 'web_search',
      };

      if (webSearchConfig != null) {
        if (webSearchConfig.maxUses != null) {
          toolDef['max_uses'] = webSearchConfig.maxUses;
        }
        if (webSearchConfig.allowedDomains != null &&
            webSearchConfig.allowedDomains!.isNotEmpty) {
          toolDef['allowed_domains'] = webSearchConfig.allowedDomains;
        }
        if (webSearchConfig.blockedDomains != null &&
            webSearchConfig.blockedDomains!.isNotEmpty) {
          toolDef['blocked_domains'] = webSearchConfig.blockedDomains;
        }
        if (webSearchConfig.location != null) {
          toolDef['user_location'] = {
            'type': 'approximate',
            'city': webSearchConfig.location!.city,
            'region': webSearchConfig.location!.region,
            'country': webSearchConfig.location!.country,
            if (webSearchConfig.location!.timezone != null)
              'timezone': webSearchConfig.location!.timezone,
          };
        }
      }

      return toolDef;
    }

    final schema = tool.function.parameters.toJson();

    if (schema['type'] != 'object') {
      throw ArgumentError(
        'Anthropic tools require input_schema to be of type "object". '
        'Tool "${tool.function.name}" has type "${schema['type']}". '
        '\n\nTo fix this, update your tool definition:\n'
        'ParametersSchema(\n'
        '  schemaType: "object",  // <- Change this to "object"\n'
        '  properties: {...},\n'
        '  required: [...],\n'
        ')\n\n'
        'See: https://docs.anthropic.com/en/api/messages#tools',
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

dynamic _convertAnthropicToolChoice(ToolChoice toolChoice) {
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
