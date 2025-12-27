part of 'package:llm_dart_anthropic_compatible/request_builder.dart';

extension _AnthropicRequestBuilderTools on AnthropicRequestBuilder {
  ProcessedTools _processTools(
      List<ChatMessage> messages, List<Tool>? configTools) {
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
      cacheControl: toolCacheControl ?? _defaultCacheControl,
    );
  }

  ToolExtractionResult _extractToolsFromMessage(ChatMessage message) {
    final tools = <Tool>[];
    final cacheControlFromMessageOptions =
        _cacheControlFromProviderOptions(message.providerOptions);
    Map<String, dynamic>? cacheControlFromBlocks;

    final anthropicData = message.getProtocolPayload<Map<String, dynamic>>(
      'anthropic',
    );
    if (anthropicData != null) {
      final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>?;
      if (contentBlocks != null) {
        for (final block in contentBlocks) {
          if (block is Map) {
            final blockMap = Map<String, dynamic>.from(block);
            if (blockMap['cache_control'] != null && blockMap['text'] == '') {
              cacheControlFromBlocks = blockMap['cache_control'];
            } else if (blockMap['type'] == 'tools') {
              tools.addAll(_convertToolsFromBlock(blockMap));
            }
          }
        }
      }
    }

    return ToolExtractionResult(
      tools: tools,
      cacheControl: cacheControlFromBlocks ?? cacheControlFromMessageOptions,
    );
  }

  List<Tool> _convertToolsFromBlock(Map<String, dynamic> toolsBlock) {
    final tools = <Tool>[];
    final toolsList = toolsBlock['tools'] as List<dynamic>?;

    if (toolsList != null) {
      for (final toolData in toolsList) {
        if (toolData is Map) {
          final toolMap = Map<String, dynamic>.from(toolData);
          if (toolMap.containsKey('function') && toolMap.containsKey('type')) {
            final function =
                Map<String, dynamic>.from(toolMap['function'] as Map);
            tools.add(
              Tool(
                toolType: toolMap['type'] as String? ?? 'function',
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
              tools.add(Tool.fromJson(toolMap));
            } catch (_) {
              continue;
            }
          }
        }
      }
    }

    return tools;
  }

  void _addTools(
    Map<String, dynamic> body,
    ProcessedTools processedTools,
    ToolNameMapping toolNameMapping,
  ) {
    final convertedTools = processedTools.tools
        .map((t) => _convertFunctionTool(t, toolNameMapping))
        .toList();

    final webSearchToolDef = _buildWebSearchToolDefinitionIfEnabled();
    if (webSearchToolDef != null) {
      convertedTools.add(webSearchToolDef);
    }

    final webFetchToolDef = _buildWebFetchToolDefinitionIfEnabled();
    if (webFetchToolDef != null) {
      convertedTools.add(webFetchToolDef);
    }

    if (convertedTools.isEmpty) return;

    _applyToolCacheControl(convertedTools, processedTools.cacheControl);

    body['tools'] = convertedTools;

    if (config.toolChoice != null) {
      body['tool_choice'] = _convertToolChoice(
        config.toolChoice!,
        toolNameMapping,
      );
    }
  }

  void _applyToolCacheControl(
    List<Map<String, dynamic>> convertedTools,
    Map<String, dynamic>? cacheControl,
  ) {
    if (cacheControl == null) return;

    // Anthropic allows `cache_control` on function tools, but provider-native
    // server tools like `web_search_*` / `web_fetch_*` do not accept it. When
    // server tools are enabled, apply caching to the last cacheable tool
    // instead of blindly using the last item in the tools list.
    for (var i = convertedTools.length - 1; i >= 0; i--) {
      final tool = convertedTools[i];
      final type = tool['type'];
      if (type is String &&
          (type.startsWith('web_search_') || type.startsWith('web_fetch_'))) {
        continue;
      }
      tool['cache_control'] = cacheControl;
      return;
    }
  }

  Map<String, dynamic> _convertFunctionTool(
    Tool tool,
    ToolNameMapping toolNameMapping,
  ) {
    final converted = convertTool(tool);
    final requestName =
        toolNameMapping.requestNameForFunction(tool.function.name);
    if (requestName != tool.function.name) {
      converted['name'] = requestName;
    }
    return converted;
  }

  Map<String, dynamic>? _buildWebSearchToolDefinitionIfEnabled() {
    final toolType = config.webSearchToolType;
    if (toolType == null || toolType.isEmpty) return null;

    final normalizedType =
        toolType.startsWith('web_search_') ? toolType : 'web_search_20250305';

    final toolDef = <String, dynamic>{
      'type': normalizedType,
      'name': 'web_search',
      ...?config.webSearchToolOptions?.toJson(),
    };

    return toolDef;
  }

  Map<String, dynamic>? _buildWebFetchToolDefinitionIfEnabled() {
    final toolType = config.webFetchToolType;
    if (toolType == null || toolType.isEmpty) return null;

    final normalizedType =
        toolType.startsWith('web_fetch_') ? toolType : 'web_fetch_20250910';

    final toolDef = <String, dynamic>{
      'type': normalizedType,
      'name': 'web_fetch',
      ...?config.webFetchToolOptions?.toJson(),
    };

    return toolDef;
  }

  dynamic _convertToolChoice(
    ToolChoice toolChoice,
    ToolNameMapping toolNameMapping,
  ) {
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
        final requestName = toolNameMapping.requestNameForFunction(toolName);
        final result = <String, dynamic>{'type': 'tool', 'name': requestName};
        if (disableParallel == true) {
          result['disable_parallel_tool_use'] = true;
        }
        return result;
      case NoneToolChoice():
        return 'none';
    }
  }

  ToolNameMapping _createToolNameMapping(ProcessedTools processedTools) {
    final webSearchToolType = config.webSearchToolType;
    final webFetchToolType = config.webFetchToolType;

    if (webSearchToolType == null && webFetchToolType == null) {
      return createToolNameMapping(
        functionToolNames: processedTools.tools.map((t) => t.function.name),
        providerToolRequestNamesById: const {},
      );
    }

    final providerToolRequestNamesById = <String, String>{};

    if (webSearchToolType != null && webSearchToolType.isNotEmpty) {
      final normalizedType = webSearchToolType.startsWith('web_search_')
          ? webSearchToolType
          : 'web_search_20250305';
      providerToolRequestNamesById['anthropic.$normalizedType'] = 'web_search';
    }

    if (webFetchToolType != null && webFetchToolType.isNotEmpty) {
      final normalizedType = webFetchToolType.startsWith('web_fetch_')
          ? webFetchToolType
          : 'web_fetch_20250910';
      providerToolRequestNamesById['anthropic.$normalizedType'] = 'web_fetch';
    }

    return createToolNameMapping(
      functionToolNames: processedTools.tools.map((t) => t.function.name),
      providerToolRequestNamesById: providerToolRequestNamesById,
    );
  }
}
