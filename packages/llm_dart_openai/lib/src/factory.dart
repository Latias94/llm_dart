import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/config.dart';
import 'package:llm_dart_core/core/llm_error.dart';
import 'package:llm_dart_core/core/provider_defaults.dart';
import 'package:llm_dart_core/core/provider_options.dart';
import 'package:llm_dart_core/core/registry.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';
import 'package:llm_dart_provider_utils/factories/base_factory.dart';

import 'openai.dart';

/// OpenAI provider id used in the core registry.
const String openaiProviderId = 'openai';

/// Register the OpenAI provider in the global [LLMProviderRegistry].
///
/// - If [replace] is false (default), registration is idempotent and will
///   not override an existing provider registered under the same id.
/// - If [replace] is true, the existing registration (if any) is replaced.
void registerOpenAI({bool replace = false}) {
  if (!replace && LLMProviderRegistry.isRegistered(openaiProviderId)) return;
  final factory = OpenAIProviderFactory();
  if (replace) {
    LLMProviderRegistry.registerOrReplace(factory);
    return;
  }
  LLMProviderRegistry.register(factory);
}

/// Factory for creating OpenAI provider instances.
class OpenAIProviderFactory
    extends OpenAICompatibleBaseFactory<ChatCapability> {
  @override
  String get providerId => openaiProviderId;

  @override
  String get displayName => 'OpenAI';

  @override
  String get description =>
      'OpenAI GPT models including GPT-4, GPT-3.5, and reasoning models';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.embedding,
        LLMCapability.modelListing,
        LLMCapability.toolCalling,
        LLMCapability.reasoning,
        LLMCapability.vision,
        LLMCapability.textToSpeech,
        LLMCapability.speechToText,
        LLMCapability.audioTranslation,
        LLMCapability.imageGeneration,
        LLMCapability.fileManagement,
        LLMCapability.moderation,
        LLMCapability.assistants,
        LLMCapability.completion,
        // Best-effort: can be enabled via providerOptions['openai']['useResponsesAPI'].
        LLMCapability.openaiResponses,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<OpenAIConfig>(
      config,
      () => _transformConfig(config),
      (openaiConfig) => OpenAIProvider(openaiConfig),
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return ProviderDefaults.getDefaults(openaiProviderId);
  }

  /// Transform unified config to OpenAI-specific config.
  OpenAIConfig _transformConfig(LLMConfig config) {
    // Handle web search configuration.
    String? model = config.model;

    final providerOptions = config.providerOptions;
    final extraBody =
        readProviderOptionMap(providerOptions, providerId, 'extraBody');
    final extraHeadersRaw =
        readProviderOptionMap(providerOptions, providerId, 'extraHeaders');
    final extraHeaders = _parseStringMap(extraHeadersRaw);

    final webSearchEnabledFromProviderOptions = readProviderOption<bool>(
      providerOptions,
      providerId,
      'webSearchEnabled',
    );

    final rawWebSearch = readProviderOptionMap(
          providerOptions,
          providerId,
          'webSearch',
        ) ??
        readProviderOption<dynamic>(
          providerOptions,
          providerId,
          'webSearch',
        );
    final webSearchEnabledFromLegacyProviderOptions =
        _parseLegacyWebSearchEnabled(rawWebSearch);
    final legacyProviderOptionContextSize =
        _parseLegacyWebSearchContextSize(rawWebSearch);

    final providerTools = config.providerTools;
    ProviderTool? webSearchProviderTool;
    if (providerTools != null) {
      for (final t in providerTools) {
        if (t.id == 'openai.web_search_preview') {
          webSearchProviderTool = t;
          break;
        }
      }
    }
    final hasProviderToolWebSearch = webSearchProviderTool != null;
    final providerToolContextSize =
        _parseProviderToolWebSearchContextSize(webSearchProviderTool);

    final webSearchEnabled = webSearchEnabledFromProviderOptions ??
        webSearchEnabledFromLegacyProviderOptions ??
        (hasProviderToolWebSearch ? true : null);

    final shouldEnableResponsesForWebSearch =
        webSearchEnabled == true || hasProviderToolWebSearch;

    var useResponsesAPI = readProviderOption<bool>(
            providerOptions, providerId, 'useResponsesAPI') ??
        false;

    final builtInToolsFromProviderOptions = _parseBuiltInTools(
      readProviderOption<dynamic>(providerOptions, providerId, 'builtInTools'),
    );

    List<OpenAIBuiltInTool>? builtInTools = builtInToolsFromProviderOptions;
    final builtInToolsFromProviderTools =
        _buildBuiltInToolsFromProviderTools(config);
    if (builtInToolsFromProviderTools != null &&
        builtInToolsFromProviderTools.isNotEmpty) {
      final merged = List<OpenAIBuiltInTool>.from(builtInTools ?? const []);
      for (final tool in builtInToolsFromProviderTools) {
        if (merged.any((t) => t.type == tool.type)) continue;
        merged.add(tool);
      }
      builtInTools = merged.isEmpty ? null : merged;
    }

    final fileSearchTool = _buildFileSearchToolFromProviderOptions(config);
    final computerUseTool = _buildComputerUseToolFromProviderOptions(config);

    if (shouldEnableResponsesForWebSearch) {
      // OpenAI web search is a provider-native built-in tool in the Responses API.
      useResponsesAPI = true;

      final tools = List<OpenAIBuiltInTool>.from(builtInTools ?? const []);
      final hasWebSearchTool = tools.any(
        (t) => t.type == OpenAIBuiltInToolType.webSearch,
      );

      if (!hasWebSearchTool) {
        tools.add(
          OpenAIBuiltInTools.webSearch(
            contextSize: providerToolContextSize ??
                legacyProviderOptionContextSize ??
                OpenAIWebSearchContextSize.medium,
          ),
        );
      }

      builtInTools = tools.isEmpty ? null : tools;
    }

    if (fileSearchTool != null || computerUseTool != null) {
      useResponsesAPI = true;
      final tools = List<OpenAIBuiltInTool>.from(builtInTools ?? const []);

      if (fileSearchTool != null &&
          !tools.any((t) => t.type == OpenAIBuiltInToolType.fileSearch)) {
        tools.add(fileSearchTool);
      }

      if (computerUseTool != null &&
          !tools.any((t) => t.type == OpenAIBuiltInToolType.computerUse)) {
        tools.add(computerUseTool);
      }

      builtInTools = tools.isEmpty ? null : tools;
    }

    // If any built-in tools are configured, force Responses API.
    if ((builtInTools?.isNotEmpty ?? false) && useResponsesAPI == false) {
      useResponsesAPI = true;
    }

    return OpenAIConfig(
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl,
      model: model,
      extraBody: extraBody,
      extraHeaders: extraHeaders,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      systemPrompt: config.systemPrompt,
      timeout: config.timeout,
      topP: config.topP,
      topK: config.topK,
      tools: config.tools,
      toolChoice: config.toolChoice,
      stopSequences: config.stopSequences,
      user: config.user,
      serviceTier: config.serviceTier,
      reasoningEffort: ReasoningEffort.fromString(
        readProviderOption<String>(
            providerOptions, providerId, 'reasoningEffort'),
      ),
      jsonSchema: readProviderOption<StructuredOutputFormat>(
        providerOptions,
        providerId,
        'jsonSchema',
      ),
      voice: readProviderOption<String>(providerOptions, providerId, 'voice'),
      embeddingEncodingFormat: readProviderOption<String>(
        providerOptions,
        providerId,
        'embeddingEncodingFormat',
      ),
      embeddingDimensions: readProviderOption<int>(
        providerOptions,
        providerId,
        'embeddingDimensions',
      ),
      useResponsesAPI: useResponsesAPI,
      previousResponseId: readProviderOption<String>(
          providerOptions, providerId, 'previousResponseId'),
      builtInTools: builtInTools,
      originalConfig: config,
    );
  }

  Map<String, String>? _parseStringMap(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return null;
    final result = <String, String>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is String) {
        result[entry.key] = value;
      }
    }
    return result.isEmpty ? null : result;
  }

  bool? _parseLegacyWebSearchEnabled(dynamic rawWebSearch) {
    if (rawWebSearch == null) return null;
    if (rawWebSearch is bool) return rawWebSearch;

    if (rawWebSearch is Map<String, dynamic>) {
      final enabled = rawWebSearch['enabled'];
      if (enabled is bool) return enabled;
      return true; // presence implies enable (legacy behavior)
    }

    if (rawWebSearch is Map) {
      final enabled = rawWebSearch['enabled'];
      if (enabled is bool) return enabled;
      return true; // presence implies enable (legacy behavior)
    }

    return null;
  }

  OpenAIWebSearchContextSize? _parseLegacyWebSearchContextSize(
    dynamic rawWebSearch,
  ) {
    if (rawWebSearch is Map<String, dynamic>) {
      return _parseContextSizeValue(
        rawWebSearch['contextSize'] ??
            rawWebSearch['context_size'] ??
            rawWebSearch['search_context_size'],
      );
    }
    if (rawWebSearch is Map) {
      return _parseContextSizeValue(
        rawWebSearch['contextSize'] ??
            rawWebSearch['context_size'] ??
            rawWebSearch['search_context_size'],
      );
    }
    return null;
  }

  OpenAIWebSearchContextSize? _parseProviderToolWebSearchContextSize(
    ProviderTool? tool,
  ) {
    if (tool == null) return null;
    return _parseContextSizeValue(tool.options['search_context_size']);
  }

  OpenAIWebSearchContextSize? _parseContextSizeValue(dynamic value) {
    if (value is! String) return null;
    return OpenAIWebSearchContextSize.tryParse(value);
  }

  OpenAIFileSearchTool? _buildFileSearchToolFromProviderOptions(
      LLMConfig config) {
    final providerOptions = config.providerOptions;
    final enabled = readProviderOption<bool>(
        providerOptions, providerId, 'fileSearchEnabled');

    final map =
        readProviderOptionMap(providerOptions, providerId, 'fileSearch') ??
            <String, dynamic>{};
    if (enabled != true && map.isEmpty) return null;

    final enabledFromMap = map['enabled'];
    final effectiveEnabled = enabled == true || enabledFromMap == true;
    if (!effectiveEnabled) return null;

    final vectorStoreIds =
        (map['vectorStoreIds'] as List?)?.whereType<String>().toList() ??
            (map['vector_store_ids'] as List?)?.whereType<String>().toList();

    final explicitParameters = map['parameters'];
    final parameters = <String, dynamic>{};
    if (explicitParameters is Map<String, dynamic>) {
      parameters.addAll(explicitParameters);
    } else if (explicitParameters is Map) {
      parameters.addAll(Map<String, dynamic>.from(explicitParameters));
    }

    // Allow extra keys as a flexible escape hatch.
    for (final entry in map.entries) {
      if (entry.key == 'enabled' ||
          entry.key == 'vectorStoreIds' ||
          entry.key == 'vector_store_ids' ||
          entry.key == 'parameters') {
        continue;
      }
      parameters[entry.key] = entry.value;
    }

    return OpenAIBuiltInTools.fileSearch(
      vectorStoreIds: vectorStoreIds?.isEmpty == true ? null : vectorStoreIds,
      parameters: parameters.isEmpty ? null : parameters,
    );
  }

  OpenAIComputerUseTool? _buildComputerUseToolFromProviderOptions(
      LLMConfig config) {
    final providerOptions = config.providerOptions;
    final enabled = readProviderOption<bool>(
      providerOptions,
      providerId,
      'computerUseEnabled',
    );

    final map =
        readProviderOptionMap(providerOptions, providerId, 'computerUse') ??
            <String, dynamic>{};
    if (enabled != true && map.isEmpty) return null;

    final enabledFromMap = map['enabled'];
    final effectiveEnabled = enabled == true || enabledFromMap == true;
    if (!effectiveEnabled) return null;

    final displayWidth =
        (map['displayWidth'] as int?) ?? (map['display_width'] as int?);
    final displayHeight =
        (map['displayHeight'] as int?) ?? (map['display_height'] as int?);
    final environment = map['environment'] as String?;

    if (displayWidth == null || displayHeight == null || environment == null) {
      throw const InvalidRequestError(
        'OpenAI computer use requires providerOptions["openai"]["computerUse"] '
        'to include displayWidth, displayHeight, and environment.',
      );
    }

    final explicitParameters = map['parameters'];
    final parameters = <String, dynamic>{};
    if (explicitParameters is Map<String, dynamic>) {
      parameters.addAll(explicitParameters);
    } else if (explicitParameters is Map) {
      parameters.addAll(Map<String, dynamic>.from(explicitParameters));
    }

    for (final entry in map.entries) {
      if (entry.key == 'enabled' ||
          entry.key == 'displayWidth' ||
          entry.key == 'display_height' ||
          entry.key == 'displayHeight' ||
          entry.key == 'display_width' ||
          entry.key == 'environment' ||
          entry.key == 'parameters') {
        continue;
      }
      parameters[entry.key] = entry.value;
    }

    return OpenAIBuiltInTools.computerUse(
      displayWidth: displayWidth,
      displayHeight: displayHeight,
      environment: environment,
      parameters: parameters.isEmpty ? null : parameters,
    );
  }

  List<OpenAIBuiltInTool>? _parseBuiltInTools(dynamic raw) {
    if (raw == null) return null;
    if (raw is List<OpenAIBuiltInTool>) return raw;
    if (raw is! List) return null;

    final result = <OpenAIBuiltInTool>[];

    for (final item in raw) {
      if (item is OpenAIBuiltInTool) {
        result.add(item);
        continue;
      }
      if (item is! Map) continue;

      final map = Map<String, dynamic>.from(item);
      final type = map['type'];
      if (type is! String) continue;

      switch (type) {
        case 'web_search_preview':
          OpenAIWebSearchContextSize? contextSize;
          final rawContextSize = map['search_context_size'];
          if (rawContextSize is String) {
            contextSize = OpenAIWebSearchContextSize.tryParse(rawContextSize);
          }
          result.add(OpenAIBuiltInTools.webSearch(contextSize: contextSize));
          break;

        case 'file_search':
          final vectorStoreIds =
              (map['vector_store_ids'] as List?)?.whereType<String>().toList();

          final parameters = Map<String, dynamic>.from(map)
            ..remove('type')
            ..remove('vector_store_ids');

          result.add(
            OpenAIBuiltInTools.fileSearch(
              vectorStoreIds:
                  vectorStoreIds?.isEmpty == true ? null : vectorStoreIds,
              parameters: parameters.isEmpty ? null : parameters,
            ),
          );
          break;

        case 'computer_use_preview':
          final displayWidth = map['display_width'] as int?;
          final displayHeight = map['display_height'] as int?;
          final environment = map['environment'] as String?;
          if (displayWidth == null ||
              displayHeight == null ||
              environment == null) {
            continue;
          }

          final parameters = Map<String, dynamic>.from(map)
            ..remove('type')
            ..remove('display_width')
            ..remove('display_height')
            ..remove('environment');

          result.add(
            OpenAIBuiltInTools.computerUse(
              displayWidth: displayWidth,
              displayHeight: displayHeight,
              environment: environment,
              parameters: parameters.isEmpty ? null : parameters,
            ),
          );
          break;
      }
    }

    return result.isEmpty ? null : result;
  }

  List<OpenAIBuiltInTool>? _buildBuiltInToolsFromProviderTools(
      LLMConfig config) {
    final providerTools = config.providerTools;
    if (providerTools == null || providerTools.isEmpty) return null;

    final result = <OpenAIBuiltInTool>[];

    for (final tool in providerTools) {
      switch (tool.id) {
        case 'openai.web_search_preview':
          OpenAIWebSearchContextSize? contextSize;
          final rawContextSize = tool.options['search_context_size'] ??
              tool.options['searchContextSize'] ??
              tool.options['contextSize'];
          if (rawContextSize is String) {
            contextSize = OpenAIWebSearchContextSize.tryParse(rawContextSize);
          }
          result.add(
            OpenAIBuiltInTools.webSearch(
              contextSize: contextSize ?? OpenAIWebSearchContextSize.medium,
            ),
          );
          break;

        case 'openai.file_search':
          final rawVectorStoreIds = tool.options['vector_store_ids'] ??
              tool.options['vectorStoreIds'];
          final vectorStoreIds = (rawVectorStoreIds is List)
              ? rawVectorStoreIds.whereType<String>().toList()
              : null;

          final explicitParameters = tool.options['parameters'];
          final parameters = <String, dynamic>{};
          if (explicitParameters is Map<String, dynamic>) {
            parameters.addAll(explicitParameters);
          } else if (explicitParameters is Map) {
            parameters.addAll(Map<String, dynamic>.from(explicitParameters));
          }

          for (final entry in tool.options.entries) {
            if (entry.key == 'vector_store_ids' ||
                entry.key == 'vectorStoreIds' ||
                entry.key == 'parameters') {
              continue;
            }
            parameters[entry.key] = entry.value;
          }

          result.add(
            OpenAIBuiltInTools.fileSearch(
              vectorStoreIds:
                  vectorStoreIds?.isEmpty == true ? null : vectorStoreIds,
              parameters: parameters.isEmpty ? null : parameters,
            ),
          );
          break;

        case 'openai.computer_use_preview':
          final displayWidth = (tool.options['displayWidth'] as int?) ??
              (tool.options['display_width'] as int?);
          final displayHeight = (tool.options['displayHeight'] as int?) ??
              (tool.options['display_height'] as int?);
          final environment = tool.options['environment'] as String?;

          if (displayWidth == null ||
              displayHeight == null ||
              environment == null) {
            throw const InvalidRequestError(
              'OpenAI computer use requires ProviderTool(id: "openai.computer_use_preview") '
              'to include displayWidth, displayHeight, and environment in options.',
            );
          }

          final explicitParameters = tool.options['parameters'];
          final parameters = <String, dynamic>{};
          if (explicitParameters is Map<String, dynamic>) {
            parameters.addAll(explicitParameters);
          } else if (explicitParameters is Map) {
            parameters.addAll(Map<String, dynamic>.from(explicitParameters));
          }

          for (final entry in tool.options.entries) {
            if (entry.key == 'displayWidth' ||
                entry.key == 'display_height' ||
                entry.key == 'displayHeight' ||
                entry.key == 'display_width' ||
                entry.key == 'environment' ||
                entry.key == 'parameters') {
              continue;
            }
            parameters[entry.key] = entry.value;
          }

          result.add(
            OpenAIBuiltInTools.computerUse(
              displayWidth: displayWidth,
              displayHeight: displayHeight,
              environment: environment,
              parameters: parameters.isEmpty ? null : parameters,
            ),
          );
          break;
      }
    }

    return result.isEmpty ? null : result;
  }

  // Note: this factory intentionally does not rewrite `model` when provider-native
  // tools are enabled. If a tool requires a specific model family, the OpenAI API
  // should return an error and the caller can pick an appropriate model.
}
