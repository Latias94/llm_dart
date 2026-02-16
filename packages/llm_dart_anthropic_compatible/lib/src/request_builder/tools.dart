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
    ToolNameMapping toolNameMapping, {
    List<ProviderTool>? providerTools,
  }) {
    final convertedTools = processedTools.tools
        .map((t) => _convertFunctionTool(t, toolNameMapping))
        .toList();

    final providerToolDefsByName = <String, Map<String, dynamic>>{};
    void putProviderToolDef(Map<String, dynamic>? def) {
      if (def == null || def.isEmpty) return;
      final name = def['name'];
      if (name is! String || name.trim().isEmpty) return;
      providerToolDefsByName[name] = def;
    }

    // Config-driven server tools (providerOptions-based enable).
    putProviderToolDef(_buildWebSearchToolDefinitionIfEnabled());
    putProviderToolDef(_buildWebFetchToolDefinitionIfEnabled());

    // ProviderTools-driven server tools (LLMConfig/providerTools call override).
    final enabledProviderTools = _collectEnabledProviderTools(providerTools);
    for (final tool in enabledProviderTools) {
      putProviderToolDef(_convertProviderToolToDefinition(tool));
    }

    if (providerToolDefsByName.isNotEmpty) {
      convertedTools.addAll(providerToolDefsByName.values);
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

    for (var i = convertedTools.length - 1; i >= 0; i--) {
      final tool = convertedTools[i];

      // Anthropic allows `cache_control` on function tools, but provider-native
      // tools (web search, web fetch, computer use, code execution, etc.) do
      // not accept it consistently. Apply caching only to the last function
      // tool (identified by `input_schema`).
      if (tool['input_schema'] is Map) {
        tool['cache_control'] = cacheControl;
        return;
      }
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

  ToolNameMapping _createToolNameMapping(
    ProcessedTools processedTools, {
    List<ProviderTool>? providerTools,
  }) {
    final webSearchToolType = config.webSearchToolType;
    final webFetchToolType = config.webFetchToolType;

    final providerToolIdByRequestName = <String, String>{};

    void reserveProviderTool(String requestName, String toolId) {
      final name = requestName.trim();
      final id = toolId.trim();
      if (name.isEmpty || id.isEmpty) return;
      providerToolIdByRequestName[name] = id;
    }

    // Config-driven tools (when enabled via providerOptions).
    if (webSearchToolType != null && webSearchToolType.isNotEmpty) {
      final normalizedType = webSearchToolType.startsWith('web_search_')
          ? webSearchToolType
          : 'web_search_20250305';
      reserveProviderTool('web_search', 'anthropic.$normalizedType');
    }

    if (webFetchToolType != null && webFetchToolType.isNotEmpty) {
      final normalizedType = webFetchToolType.startsWith('web_fetch_')
          ? webFetchToolType
          : 'web_fetch_20250910';
      reserveProviderTool('web_fetch', 'anthropic.$normalizedType');
    }

    // ProviderTools-driven tools (call-level overrides included).
    final enabledProviderTools = _collectEnabledProviderTools(providerTools);
    for (final tool in enabledProviderTools) {
      final requestName = _requestNameForProviderTool(tool);
      reserveProviderTool(requestName, tool.id);
    }

    final providerToolRequestNamesById = <String, String>{};
    for (final entry in providerToolIdByRequestName.entries) {
      providerToolRequestNamesById[entry.value] = entry.key;
    }

    return createToolNameMapping(
      functionToolNames: processedTools.tools.map((t) => t.function.name),
      providerToolRequestNamesById: providerToolRequestNamesById,
    );
  }

  List<ProviderTool> _collectEnabledProviderTools(List<ProviderTool>? tools) {
    final list = tools;
    if (list == null || list.isEmpty) return const [];

    final result = <ProviderTool>[];
    final providerPrefix = '${config.providerId}.';
    for (final tool in list) {
      final id = tool.id.trim();
      if (id.isEmpty) continue;

      final isRelevant =
          id.startsWith(providerPrefix) || id.startsWith('anthropic.');
      if (!isRelevant) continue;

      final enabled = tool.options['enabled'];
      if (enabled is bool && enabled == false) continue;
      result.add(tool);
    }

    return result;
  }

  String _requestNameForProviderTool(ProviderTool tool) {
    final suffix = tool.id.split('.').last.trim();
    if (suffix.startsWith('web_search_')) return 'web_search';
    if (suffix.startsWith('web_fetch_')) return 'web_fetch';
    if (suffix.startsWith('code_execution_')) return 'code_execution';
    if (suffix.startsWith('computer_')) return 'computer';
    if (suffix.startsWith('bash_')) return 'bash';
    if (suffix.startsWith('memory_')) return 'memory';

    if (suffix == 'tool_search_regex_20251119') {
      return 'tool_search_tool_regex';
    }
    if (suffix == 'tool_search_bm25_20251119') {
      return 'tool_search_tool_bm25';
    }

    if (suffix == 'text_editor_20241022' || suffix == 'text_editor_20250124') {
      return 'str_replace_editor';
    }
    if (suffix.startsWith('text_editor_')) return 'str_replace_based_edit_tool';

    return suffix;
  }

  Map<String, dynamic>? _convertProviderToolToDefinition(ProviderTool tool) {
    final idSuffix = tool.id.split('.').last.trim();
    if (idSuffix.isEmpty) return null;

    Map<String, dynamic> optionsWithoutEnabled() {
      final opts = Map<String, dynamic>.from(tool.options);
      opts.remove('enabled');
      return opts;
    }

    int? readInt(Map<String, dynamic> m, String key, {String? fallbackKey}) {
      final v = m[key] ?? (fallbackKey == null ? null : m[fallbackKey]);
      if (v is int) return v;
      if (v is num) return v.toInt();
      return null;
    }

    bool? readBool(Map<String, dynamic> m, String key, {String? fallbackKey}) {
      final v = m[key] ?? (fallbackKey == null ? null : m[fallbackKey]);
      if (v is bool) return v;
      return null;
    }

    switch (idSuffix) {
      case final s when s.startsWith('web_search_'):
        return <String, dynamic>{
          'type': s,
          'name': 'web_search',
          ...optionsWithoutEnabled(),
        };
      case final s when s.startsWith('web_fetch_'):
        return <String, dynamic>{
          'type': s,
          'name': 'web_fetch',
          ...optionsWithoutEnabled(),
        };
      case final s when s.startsWith('code_execution_'):
        return <String, dynamic>{
          'type': s,
          'name': 'code_execution',
        };
      case final s when s.startsWith('computer_'):
        final opts = optionsWithoutEnabled();
        final width =
            readInt(opts, 'display_width_px', fallbackKey: 'displayWidthPx');
        final height =
            readInt(opts, 'display_height_px', fallbackKey: 'displayHeightPx');
        final displayNumber =
            readInt(opts, 'display_number', fallbackKey: 'displayNumber');
        final enableZoom =
            readBool(opts, 'enable_zoom', fallbackKey: 'enableZoom');

        if (width == null || width <= 0 || height == null || height <= 0) {
          throw const InvalidRequestError(
            'Anthropic computer tools require displayWidthPx/displayHeightPx '
            '(or display_width_px/display_height_px).',
          );
        }

        final def = <String, dynamic>{
          'type': s,
          'name': 'computer',
          'display_width_px': width,
          'display_height_px': height,
          if (displayNumber != null) 'display_number': displayNumber,
        };
        if (enableZoom != null) def['enable_zoom'] = enableZoom;
        return def;

      case final s when s.startsWith('text_editor_'):
        final opts = optionsWithoutEnabled();
        final maxCharacters = readInt(
          opts,
          'max_characters',
          fallbackKey: 'maxCharacters',
        );

        final name = _requestNameForProviderTool(tool);
        return <String, dynamic>{
          'type': s,
          'name': name,
          if (maxCharacters != null) 'max_characters': maxCharacters,
        };

      case final s when s.startsWith('bash_'):
        return <String, dynamic>{
          'type': s,
          'name': 'bash',
        };

      case final s when s.startsWith('memory_'):
        return <String, dynamic>{
          'type': s,
          'name': 'memory',
        };

      case 'tool_search_regex_20251119':
        return <String, dynamic>{
          'type': 'tool_search_tool_regex_20251119',
          'name': 'tool_search_tool_regex',
        };

      case 'tool_search_bm25_20251119':
        return <String, dynamic>{
          'type': 'tool_search_tool_bm25_20251119',
          'name': 'tool_search_tool_bm25',
        };

      default:
        return null;
    }
  }
}
