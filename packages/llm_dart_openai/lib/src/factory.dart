import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../defaults.dart';
import '../builtin_tools.dart';
import '../config.dart';
import '../provider.dart';
import '../web_search_context_size.dart';

/// OpenAI provider id used in the core registry.
const String openaiProviderId = 'openai';

/// OpenAI Chat Completions provider id (explicit chat surface).
const String openaiChatProviderId = 'openai.chat';

/// Register the OpenAI provider in the global [LLMProviderRegistry].
///
/// - If [replace] is false (default), registration is idempotent and will
///   not override an existing provider registered under the same id.
/// - If [replace] is true, the existing registration (if any) is replaced.
void registerOpenAI({bool replace = false}) {
  final responsesRegistered =
      LLMProviderRegistry.isRegistered(openaiProviderId);
  final chatRegistered = LLMProviderRegistry.isRegistered(openaiChatProviderId);

  if (!replace && responsesRegistered && chatRegistered) return;

  final responsesFactory = OpenAIProviderFactory();
  final chatFactory = OpenAIChatProviderFactory();

  if (replace) {
    LLMProviderRegistry.registerOrReplace(responsesFactory);
    LLMProviderRegistry.registerOrReplace(chatFactory);
    return;
  }

  if (!responsesRegistered) {
    LLMProviderRegistry.register(responsesFactory);
  }
  if (!chatRegistered) {
    LLMProviderRegistry.register(chatFactory);
  }
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
      'OpenAI GPT models via the Responses API (default).';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.embedding,
        LLMCapability.toolCalling,
        LLMCapability.reasoning,
        LLMCapability.vision,
        LLMCapability.textToSpeech,
        LLMCapability.speechToText,
        LLMCapability.audioTranslation,
        LLMCapability.imageGeneration,
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
    return {
      'baseUrl': openaiBaseUrl,
      'model': openaiDefaultModel,
    };
  }

  /// Transform unified config to OpenAI-specific config.
  OpenAIConfig _transformConfig(LLMConfig config) {
    final providerOptions = config.providerOptions;
    final fallbackProviderId =
        providerId == openaiChatProviderId ? openaiProviderId : null;

    if (readProviderOption<dynamic>(
          providerOptions,
          providerId,
          'useResponsesAPI',
          fallbackProviderId: fallbackProviderId,
        ) !=
        null) {
      throw InvalidRequestError(
        '"useResponsesAPI" has been removed. Use providerId "$openaiProviderId" '
        '(Responses) or "$openaiChatProviderId" (Chat Completions) instead.',
      );
    }

    final useResponsesAPI = providerId == openaiProviderId;

    final extraBody = readProviderOptionMap(
      providerOptions,
      providerId,
      'extraBody',
      fallbackProviderId: fallbackProviderId,
    );
    final extraHeadersRaw = readProviderOptionMap(
      providerOptions,
      providerId,
      'extraHeaders',
      fallbackProviderId: fallbackProviderId,
    );
    final extraHeaders = _parseStringMap(extraHeadersRaw);

    final builtInToolsFromProviderOptions = _parseBuiltInTools(
      readProviderOption<dynamic>(providerOptions, providerId, 'builtInTools'),
    );

    final previousResponseId = readProviderOption<String>(
      providerOptions,
      providerId,
      'previousResponseId',
    );

    if (!useResponsesAPI) {
      if (config.providerTools != null && config.providerTools!.isNotEmpty) {
        throw InvalidRequestError(
          'providerTools are only supported with the OpenAI Responses API. '
          'Use providerId "$openaiProviderId".',
        );
      }

      if (builtInToolsFromProviderOptions != null &&
          builtInToolsFromProviderOptions.isNotEmpty) {
        throw InvalidRequestError(
          '"builtInTools" are only supported with the OpenAI Responses API. '
          'Use providerId "$openaiProviderId".',
        );
      }

      if (previousResponseId != null && previousResponseId.isNotEmpty) {
        throw InvalidRequestError(
          '"previousResponseId" is only supported with the OpenAI Responses API. '
          'Use providerId "$openaiProviderId".',
        );
      }
    }

    List<OpenAIBuiltInTool>? builtInTools;
    if (useResponsesAPI) {
      builtInTools = builtInToolsFromProviderOptions;
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
    }

    return OpenAIConfig(
      providerId: providerId,
      providerName:
          providerId == openaiChatProviderId ? 'OpenAI (Chat)' : 'OpenAI',
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl,
      model: config.model,
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
          providerOptions,
          providerId,
          'reasoningEffort',
          fallbackProviderId: fallbackProviderId,
        ),
      ),
      jsonSchema: readProviderOption<StructuredOutputFormat>(
        providerOptions,
        providerId,
        'jsonSchema',
        fallbackProviderId: fallbackProviderId,
      ),
      voice: readProviderOption<String>(
        providerOptions,
        providerId,
        'voice',
        fallbackProviderId: fallbackProviderId,
      ),
      embeddingEncodingFormat: readProviderOption<String>(
        providerOptions,
        providerId,
        'embeddingEncodingFormat',
        fallbackProviderId: fallbackProviderId,
      ),
      embeddingDimensions: readProviderOption<int>(
        providerOptions,
        providerId,
        'embeddingDimensions',
        fallbackProviderId: fallbackProviderId,
      ),
      useResponsesAPI: useResponsesAPI,
      previousResponseId: useResponsesAPI ? previousResponseId : null,
      builtInTools: useResponsesAPI ? builtInTools : null,
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

        case 'web_search':
          OpenAIWebSearchContextSize? contextSize;
          final rawContextSize = map['search_context_size'];
          if (rawContextSize is String) {
            contextSize = OpenAIWebSearchContextSize.tryParse(rawContextSize);
          }

          final filters = map['filters'];
          List<String>? allowedDomains;
          if (filters is Map && filters['allowed_domains'] is List) {
            allowedDomains = (filters['allowed_domains'] as List)
                .whereType<String>()
                .toList();
          }

          final userLocation = map['user_location'];
          final userLocationMap = userLocation is Map<String, dynamic>
              ? userLocation
              : userLocation is Map
                  ? Map<String, dynamic>.from(userLocation)
                  : null;

          final parameters = Map<String, dynamic>.from(map)
            ..remove('type')
            ..remove('search_context_size')
            ..remove('external_web_access')
            ..remove('filters')
            ..remove('user_location');

          result.add(
            OpenAIBuiltInTools.webSearchFull(
              allowedDomains:
                  allowedDomains?.isEmpty == true ? null : allowedDomains,
              externalWebAccess: map['external_web_access'] as bool?,
              contextSize: contextSize,
              userLocation: userLocationMap,
              parameters: parameters.isEmpty ? null : parameters,
            ),
          );
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

        case 'code_interpreter':
          final container = map['container'];
          final parameters = Map<String, dynamic>.from(map)
            ..remove('type')
            ..remove('container');
          result.add(
            OpenAIBuiltInTools.codeInterpreter(
              container: container,
              parameters: parameters.isEmpty ? null : parameters,
            ),
          );
          break;

        case 'image_generation':
          final parameters = Map<String, dynamic>.from(map)..remove('type');
          result.add(
            OpenAIBuiltInTools.imageGeneration(
              parameters: parameters.isEmpty ? null : parameters,
            ),
          );
          break;

        case 'mcp':
          final parameters = Map<String, dynamic>.from(map)..remove('type');
          result.add(OpenAIBuiltInTools.mcp(
            parameters: parameters.isEmpty ? null : parameters,
          ));
          break;

        case 'apply_patch':
          result.add(OpenAIBuiltInTools.applyPatch());
          break;

        case 'shell':
          result.add(OpenAIBuiltInTools.shell());
          break;

        case 'local_shell':
          result.add(OpenAIBuiltInTools.localShell());
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

    int? asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }

    List<String>? asStringList(dynamic value) {
      if (value is List<String>) return value;
      if (value is List) return value.whereType<String>().toList();
      return null;
    }

    for (final tool in providerTools) {
      switch (tool.id) {
        case 'openai.web_search_preview':
          OpenAIWebSearchContextSize? contextSize;
          final rawContextSize = tool.args['search_context_size'] ??
              tool.args['searchContextSize'] ??
              tool.args['contextSize'];
          if (rawContextSize is String) {
            contextSize = OpenAIWebSearchContextSize.tryParse(rawContextSize);
          }
          result.add(
            OpenAIBuiltInTools.webSearch(
              contextSize: contextSize ?? OpenAIWebSearchContextSize.medium,
            ),
          );
          break;

        case 'openai.web_search':
          OpenAIWebSearchContextSize? contextSize;
          final rawContextSize = tool.args['search_context_size'] ??
              tool.args['searchContextSize'] ??
              tool.args['contextSize'];
          if (rawContextSize is String) {
            contextSize = OpenAIWebSearchContextSize.tryParse(rawContextSize);
          }

          final filters = tool.args['filters'];
          List<String>? allowedDomains;
          if (filters is Map) {
            allowedDomains = asStringList(filters['allowed_domains']) ??
                asStringList(filters['allowedDomains']);
          }

          final userLocation =
              tool.args['user_location'] ?? tool.args['userLocation'];
          final userLocationMap = userLocation is Map<String, dynamic>
              ? userLocation
              : userLocation is Map
                  ? Map<String, dynamic>.from(userLocation)
                  : null;

          final parameters = Map<String, dynamic>.from(tool.args);
          parameters.remove('filters');
          parameters.remove('external_web_access');
          parameters.remove('externalWebAccess');
          parameters.remove('search_context_size');
          parameters.remove('searchContextSize');
          parameters.remove('contextSize');
          parameters.remove('user_location');
          parameters.remove('userLocation');

          result.add(
            OpenAIBuiltInTools.webSearchFull(
              allowedDomains:
                  allowedDomains?.isEmpty == true ? null : allowedDomains,
              externalWebAccess:
                  (tool.args['external_web_access'] as bool?) ??
                      (tool.args['externalWebAccess'] as bool?),
              contextSize: contextSize,
              userLocation: userLocationMap,
              parameters: parameters.isEmpty ? null : parameters,
            ),
          );
          break;

        case 'openai.file_search':
          final rawVectorStoreIds = tool.args['vector_store_ids'] ??
              tool.args['vectorStoreIds'];
          final vectorStoreIds = (rawVectorStoreIds is List)
              ? rawVectorStoreIds.whereType<String>().toList()
              : null;

          final parameters = <String, dynamic>{};

          final explicitParameters = tool.args['parameters'];
          if (explicitParameters is Map<String, dynamic>) {
            parameters.addAll(explicitParameters);
          } else if (explicitParameters is Map) {
            parameters.addAll(Map<String, dynamic>.from(explicitParameters));
          }

          final maxNumResults = asInt(tool.args['max_num_results']) ??
              asInt(tool.args['maxNumResults']);
          if (maxNumResults != null) {
            parameters['max_num_results'] = maxNumResults;
          }

          final ranking = tool.args['ranking_options'] ??
              tool.args['rankingOptions'] ??
              tool.args['ranking'];
          if (ranking is Map) {
            final ranker = ranking['ranker'];
            final scoreThreshold =
                ranking['score_threshold'] ?? ranking['scoreThreshold'];
            final rankingOptions = <String, dynamic>{};
            if (ranker is String && ranker.isNotEmpty) {
              rankingOptions['ranker'] = ranker;
            }
            if (scoreThreshold is num) {
              rankingOptions['score_threshold'] = scoreThreshold;
            }
            if (rankingOptions.isNotEmpty) {
              parameters['ranking_options'] = rankingOptions;
            }
          }

          final filters = tool.args['filters'];
          if (filters != null) {
            parameters['filters'] = filters;
          }

          for (final entry in tool.args.entries) {
            if (entry.key == 'vector_store_ids' ||
                entry.key == 'vectorStoreIds' ||
                entry.key == 'max_num_results' ||
                entry.key == 'maxNumResults' ||
                entry.key == 'ranking_options' ||
                entry.key == 'rankingOptions' ||
                entry.key == 'ranking' ||
                entry.key == 'filters' ||
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

        case 'openai.computer_use':
          final displayWidth = (tool.args['displayWidth'] as int?) ??
              (tool.args['display_width'] as int?);
          final displayHeight = (tool.args['displayHeight'] as int?) ??
              (tool.args['display_height'] as int?);
          final environment = tool.args['environment'] as String?;

          if (displayWidth == null ||
              displayHeight == null ||
              environment == null) {
            throw const InvalidRequestError(
              'OpenAI computer use requires ProviderTool(id: "openai.computer_use") '
              'to include displayWidth, displayHeight, and environment in args.',
            );
          }

          final explicitParameters = tool.args['parameters'];
          final parameters = <String, dynamic>{};
          if (explicitParameters is Map<String, dynamic>) {
            parameters.addAll(explicitParameters);
          } else if (explicitParameters is Map) {
            parameters.addAll(Map<String, dynamic>.from(explicitParameters));
          }

          for (final entry in tool.args.entries) {
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

        case 'openai.code_interpreter':
          final rawContainer = tool.args['container'];
          dynamic container;
          if (rawContainer == null) {
            container = const <String, Object?>{'type': 'auto'};
          } else if (rawContainer is String) {
            container = rawContainer;
          } else if (rawContainer is Map) {
            final fileIds = asStringList(rawContainer['file_ids']) ??
                asStringList(rawContainer['fileIds']);
            container = <String, Object?>{
              'type': 'auto',
              if (fileIds != null && fileIds.isNotEmpty) 'file_ids': fileIds,
            };
          } else {
            container = rawContainer;
          }

          final parameters = Map<String, dynamic>.from(tool.args)
            ..remove('container');
          result.add(
            OpenAIBuiltInTools.codeInterpreter(
              container: container,
              parameters: parameters.isEmpty ? null : parameters,
            ),
          );
          break;

        case 'openai.image_generation':
          final p = <String, dynamic>{};

          void mapKey(String from, String to) {
            if (!tool.args.containsKey(from)) return;
            p[to] = tool.args[from];
          }

          mapKey('background', 'background');
          mapKey('input_fidelity', 'input_fidelity');
          mapKey('inputFidelity', 'input_fidelity');
          mapKey('model', 'model');
          mapKey('moderation', 'moderation');
          mapKey('partial_images', 'partial_images');
          mapKey('partialImages', 'partial_images');
          mapKey('quality', 'quality');
          mapKey('output_compression', 'output_compression');
          mapKey('outputCompression', 'output_compression');
          mapKey('output_format', 'output_format');
          mapKey('outputFormat', 'output_format');
          mapKey('size', 'size');

          final inputImageMask = tool.args['input_image_mask'] ??
              tool.args['inputImageMask'];
          if (inputImageMask is Map) {
            final fileId =
                inputImageMask['file_id'] ?? inputImageMask['fileId'];
            final imageUrl =
                inputImageMask['image_url'] ?? inputImageMask['imageUrl'];
            final m = <String, dynamic>{};
            if (fileId is String && fileId.isNotEmpty) m['file_id'] = fileId;
            if (imageUrl is String && imageUrl.isNotEmpty) {
              m['image_url'] = imageUrl;
            }
            if (m.isNotEmpty) p['input_image_mask'] = m;
          }

          // Pass through already-snake_case keys as an escape hatch.
          for (final entry in tool.args.entries) {
            final k = entry.key;
            if (!k.contains('_')) continue;
            p.putIfAbsent(k, () => entry.value);
          }

          result.add(OpenAIBuiltInTools.imageGeneration(
            parameters: p.isEmpty ? null : p,
          ));
          break;

        case 'openai.mcp':
          final p = <String, dynamic>{};

          void mapKey(String from, String to) {
            if (!tool.args.containsKey(from)) return;
            p[to] = tool.args[from];
          }

          mapKey('server_label', 'server_label');
          mapKey('serverLabel', 'server_label');
          mapKey('server_description', 'server_description');
          mapKey('serverDescription', 'server_description');
          mapKey('server_url', 'server_url');
          mapKey('serverUrl', 'server_url');
          mapKey('authorization', 'authorization');
          mapKey('connector_id', 'connector_id');
          mapKey('connectorId', 'connector_id');

          final headers = tool.args['headers'];
          if (headers is Map<String, dynamic>) {
            p['headers'] = headers;
          } else if (headers is Map) {
            p['headers'] = Map<String, dynamic>.from(headers);
          }

          final allowedTools =
              tool.args['allowed_tools'] ?? tool.args['allowedTools'];
          if (allowedTools is List) {
            final names = allowedTools.whereType<String>().toList();
            if (names.isNotEmpty) p['allowed_tools'] = names;
          } else if (allowedTools is Map) {
            final readOnly =
                allowedTools['read_only'] ?? allowedTools['readOnly'];
            final toolNames = asStringList(
              allowedTools['tool_names'] ?? allowedTools['toolNames'],
            );
            p['allowed_tools'] = <String, dynamic>{
              if (readOnly is bool) 'read_only': readOnly,
              if (toolNames != null) 'tool_names': toolNames,
            };
          }

          final requireApproval =
              tool.args['require_approval'] ?? tool.args['requireApproval'];
          if (requireApproval is String) {
            p['require_approval'] = requireApproval;
          } else if (requireApproval is Map) {
            final never = requireApproval['never'];
            if (never is Map) {
              final toolNames = asStringList(
                never['tool_names'] ?? never['toolNames'],
              );
              p['require_approval'] = {
                'never': {
                  if (toolNames != null) 'tool_names': toolNames,
                },
              };
            }
          } else {
            // Mirror Vercel default.
            p['require_approval'] = 'never';
          }

          // If `requireApproval` is absent, default to `never` for parity.
          if (!p.containsKey('require_approval')) {
            p['require_approval'] = 'never';
          }

          // Pass through already-snake_case keys as an escape hatch.
          for (final entry in tool.args.entries) {
            final k = entry.key;
            if (!k.contains('_')) continue;
            p.putIfAbsent(k, () => entry.value);
          }

          result.add(OpenAIBuiltInTools.mcp(
            parameters: p.isEmpty ? null : p,
          ));
          break;

        case 'openai.apply_patch':
          result.add(OpenAIBuiltInTools.applyPatch());
          break;

        case 'openai.shell':
          result.add(OpenAIBuiltInTools.shell());
          break;

        case 'openai.local_shell':
          result.add(OpenAIBuiltInTools.localShell());
          break;
      }
    }

    return result.isEmpty ? null : result;
  }

  // Note: this factory intentionally does not rewrite `model` when provider-native
  // tools are enabled. If a tool requires a specific model family, the OpenAI API
  // should return an error and the caller can pick an appropriate model.
}

/// Factory for creating OpenAI Chat Completions provider instances.
class OpenAIChatProviderFactory extends OpenAIProviderFactory {
  @override
  String get providerId => openaiChatProviderId;

  @override
  String get displayName => 'OpenAI (Chat Completions)';

  @override
  String get description =>
      'OpenAI GPT models via Chat Completions (explicit).';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.embedding,
        LLMCapability.toolCalling,
        LLMCapability.reasoning,
        LLMCapability.vision,
        LLMCapability.textToSpeech,
        LLMCapability.speechToText,
        LLMCapability.audioTranslation,
        LLMCapability.imageGeneration,
      };
}
