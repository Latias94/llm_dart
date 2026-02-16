import 'package:llm_dart_core/llm_dart_core.dart';

({List<ProviderTool>? providerTools, List<LLMWarning> warnings})
    normalizeProviderToolsAndCollectWarnings({
  required ChatCapability model,
  List<ProviderTool>? providerTools,
}) {
  final tools = providerTools;
  if (tools == null || tools.isEmpty) {
    return (providerTools: providerTools, warnings: const []);
  }

  final identity = model is ModelIdentityCapability
      ? (model as ModelIdentityCapability)
      : null;
  if (identity == null) {
    return (providerTools: providerTools, warnings: const []);
  }

  final providerId = identity.providerId;
  final modelId = identity.modelId;

  if (providerId == 'groq') {
    return _normalizeGroqProviderTools(tools, modelId: modelId);
  }

  final hasAnthropicProviderTools =
      tools.any((t) => t.id.startsWith('anthropic.'));
  if (hasAnthropicProviderTools) {
    return _normalizeAnthropicProviderTools(tools);
  }

  return (providerTools: providerTools, warnings: const []);
}

({List<ProviderTool>? providerTools, List<LLMWarning> warnings})
    _normalizeGroqProviderTools(
  List<ProviderTool> tools, {
  required String modelId,
}) {
  const supportedModels = <String>[
    'openai/gpt-oss-20b',
    'openai/gpt-oss-120b',
  ];
  final supportsBrowserSearch = supportedModels.contains(modelId);

  var hadBrowserSearch = false;
  final filtered = <ProviderTool>[];
  for (final tool in tools) {
    if (tool.id == 'groq.browser_search') {
      hadBrowserSearch = true;
      if (!supportsBrowserSearch) {
        continue;
      }
    }
    filtered.add(tool);
  }

  if (hadBrowserSearch && !supportsBrowserSearch) {
    return (
      providerTools: filtered,
      warnings: [
        LLMUnsupportedWarning(
          feature: 'provider-defined tool groq.browser_search',
          details: 'Browser search is only supported on the following models: '
              '${supportedModels.join(', ')}. Current model: $modelId',
        ),
      ],
    );
  }

  return (providerTools: filtered, warnings: const []);
}

({List<ProviderTool>? providerTools, List<LLMWarning> warnings})
    _normalizeAnthropicProviderTools(
  List<ProviderTool> tools,
) {
  const supportedIds = <String>{
    // Code execution
    'anthropic.code_execution_20250522',
    'anthropic.code_execution_20250825',

    // Web search / fetch
    'anthropic.web_search_20250305',
    'anthropic.web_fetch_20250910',

    // Computer use family
    'anthropic.computer_20241022',
    'anthropic.computer_20250124',
    'anthropic.computer_20251124',
    'anthropic.text_editor_20241022',
    'anthropic.text_editor_20250124',
    'anthropic.text_editor_20250429',
    'anthropic.text_editor_20250728',
    'anthropic.bash_20241022',
    'anthropic.bash_20250124',

    // Memory tool
    'anthropic.memory_20250818',

    // Tool search
    'anthropic.tool_search_regex_20251119',
    'anthropic.tool_search_bm25_20251119',
  };

  String? canonicalNameForId(String id) {
    final suffix = id.startsWith('anthropic.') ? id.substring(10) : id;

    if (suffix.startsWith('code_execution_')) return 'code_execution';
    if (suffix.startsWith('web_search_')) return 'web_search';
    if (suffix.startsWith('web_fetch_')) return 'web_fetch';
    if (suffix.startsWith('computer_')) return 'computer';
    if (suffix.startsWith('bash_')) return 'bash';
    if (suffix.startsWith('memory_')) return 'memory';

    if (suffix == 'tool_search_regex_20251119') return 'tool_search';
    if (suffix == 'tool_search_bm25_20251119') return 'tool_search';

    if (suffix == 'text_editor_20241022' || suffix == 'text_editor_20250124') {
      return 'str_replace_editor';
    }
    if (suffix.startsWith('text_editor_')) {
      return 'str_replace_based_edit_tool';
    }

    return null;
  }

  bool isDeferred(String id) {
    final suffix = id.startsWith('anthropic.') ? id.substring(10) : id;
    return suffix.startsWith('code_execution_') ||
        suffix.startsWith('web_search_') ||
        suffix.startsWith('web_fetch_') ||
        suffix == 'tool_search_regex_20251119' ||
        suffix == 'tool_search_bm25_20251119';
  }

  bool isEnabled(ProviderTool t) {
    final enabled = t.options['enabled'];
    if (enabled is bool) return enabled;
    return true;
  }

  final warnings = <LLMWarning>[];
  final filtered = <ProviderTool>[];

  for (final tool in tools) {
    if (!tool.id.startsWith('anthropic.')) {
      filtered.add(tool);
      continue;
    }

    if (!isEnabled(tool)) {
      continue;
    }

    if (!supportedIds.contains(tool.id)) {
      warnings.add(LLMUnsupportedWarning(feature: 'provider-defined tool ${tool.id}'));
      continue;
    }

    final name = (tool.name != null && tool.name!.trim().isNotEmpty)
        ? tool.name!.trim()
        : canonicalNameForId(tool.id);

    final supportsDeferredResults =
        tool.supportsDeferredResults || isDeferred(tool.id);

    filtered.add(
      ProviderTool(
        id: tool.id,
        name: name,
        options: tool.options,
        supportsDeferredResults: supportsDeferredResults,
      ),
    );
  }

  return (
    providerTools: filtered,
    warnings: List<LLMWarning>.unmodifiable(warnings),
  );
}
