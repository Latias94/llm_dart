// Google chat capability implementation built on ChatMessage-based
// ChatCapability. Internally this module works with ModelMessage
// prompts but keeps ChatMessage for compatibility with llm_dart_core.
// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../client/google_client.dart';
import '../config/google_config.dart';
import '../files/google_files.dart';

class GoogleChat implements ChatCapability, PromptChatCapability {
  final GoogleClient client;
  final GoogleConfig config;

  static final Map<String, GoogleFile> _fileCache = {};

  String _streamBuffer = '';
  bool _isFirstChunk = true;

  GoogleChat(this.client, this.config);

  String _buildEndpoint({required bool stream}) {
    final suffix = stream ? ':streamGenerateContent' : ':generateContent';
    return 'models/${config.model}$suffix';
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    final promptMessages =
        messages.map((message) => message.toPromptMessage()).toList();
    return chatPrompt(
      promptMessages,
      tools: tools,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    final promptMessages =
        messages.map((message) => message.toPromptMessage()).toList();
    yield* chatPromptStream(
      promptMessages,
      tools: tools,
      options: options,
      cancelToken: cancelToken,
    );
  }

  void _resetStreamState() {
    _streamBuffer = '';
    _isFirstChunk = true;
  }

  @override
  Future<ChatResponse> chatPrompt(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    final requestBody = _buildRequestBodyFromPrompt(
      messages,
      tools,
      false,
      options: options,
    );
    final responseData = await client.postJson(
      _buildEndpoint(stream: false),
      requestBody,
      cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
    );
    return _parseResponse(responseData);
  }

  @override
  Stream<ChatStreamEvent> chatPromptStream(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    _resetStreamState();

    final requestBody = _buildRequestBodyFromPrompt(
      messages,
      tools,
      true,
      options: options,
    );

    final stream = client.postStreamRaw(
      _buildEndpoint(stream: true),
      requestBody,
      cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
    );

    await for (final chunk in stream) {
      final events = _parseStreamEvents(chunk);
      for (final event in events) {
        yield event;
      }
    }
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    return chatWithTools(
      messages,
      null,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    final prompt =
        'Summarize in 2-3 sentences:\n${messages.map((m) => '${m.role.name}: ${m.content}').join('\n')}';
    final request = [ChatMessage.user(prompt)];
    final response = await chat(request);
    final text = response.text;
    if (text == null) {
      throw const GenericError('no text in summary response');
    }
    return text;
  }

  Future<GoogleFile> uploadFile({
    required List<int> data,
    required String mimeType,
    required String displayName,
  }) async {
    try {
      final metadata = {
        'file': {
          'displayName': displayName,
          'mimeType': mimeType,
        }
      };

      final formData = FormData.fromMap({
        'metadata': jsonEncode(metadata),
        'data': MultipartFile.fromBytes(
          data,
          filename: displayName,
        ),
      });

      final response = await client.dio.post(
        'upload/v1beta/files?key=${config.apiKey}',
        data: formData,
        options: Options(
          headers: {
            'X-Goog-Upload-Protocol': 'multipart',
          },
        ),
      );

      if (response.statusCode != 200) {
        final errorMessage = response.data?['error']?['message'] ??
            'File upload failed: ${response.statusCode}';
        throw ProviderError(errorMessage);
      }

      final fileData = response.data['file'] as Map<String, dynamic>;
      final uploadedFile = GoogleFile.fromJson(fileData);

      final cacheKey = '${displayName}_${data.length}_$mimeType';
      _fileCache[cacheKey] = uploadedFile;

      return uploadedFile;
    } on DioException catch (e) {
      throw await _handleDioError(e);
    } catch (e) {
      throw GenericError('File upload error: $e');
    }
  }

  Future<GoogleFile?> getOrUploadFile({
    required List<int> data,
    required String mimeType,
    required String displayName,
  }) async {
    final cacheKey = '${displayName}_${data.length}_$mimeType';

    final cachedFile = _fileCache[cacheKey];
    if (cachedFile != null && cachedFile.isActive) {
      return cachedFile;
    }

    try {
      return await uploadFile(
        data: data,
        mimeType: mimeType,
        displayName: displayName,
      );
    } catch (e) {
      client.logger.warning('File upload failed: $e');
      return null;
    }
  }

  Future<LLMError> _handleDioError(DioException e) async {
    if (e.response?.data is Map<String, dynamic>) {
      final errorData = e.response!.data as Map<String, dynamic>;
      try {
        return _handleGoogleApiError(errorData);
      } catch (googleError) {
        if (googleError is LLMError) {
          return googleError;
        }
      }
    }
    return DioErrorHandler.handleDioError(e, 'Google');
  }

  LLMError _handleGoogleApiError(Map<String, dynamic> responseData) {
    if (!responseData.containsKey('error')) {
      throw ArgumentError('No error found in response data');
    }

    final error = responseData['error'] as Map<String, dynamic>;
    final message = error['message'] as String? ?? 'Unknown error';
    final details = error['details'] as List?;

    if (details != null) {
      for (final detail in details) {
        if (detail is Map && detail['reason'] == 'API_KEY_INVALID') {
          return const AuthError('Invalid Google API key');
        }
      }
    }

    return ProviderError('Google API error: $message');
  }

  GoogleChatResponse _parseResponse(Map<String, dynamic> responseData) {
    if (responseData.containsKey('error')) {
      throw _handleGoogleApiError(responseData);
    }

    return GoogleChatResponse(responseData, config.model);
  }

  List<ChatStreamEvent> _parseStreamEvents(String chunk) {
    final events = <ChatStreamEvent>[];

    try {
      _streamBuffer += chunk;

      String processedData = _streamBuffer.trim();

      if (_isFirstChunk && processedData.startsWith('[')) {
        processedData = processedData.replaceFirst('[', '');
        _isFirstChunk = false;
      }

      if (processedData.startsWith(',')) {
        processedData = processedData.replaceFirst(',', '');
      }

      if (processedData.endsWith(']')) {
        processedData = processedData.substring(0, processedData.length - 1);
      }

      processedData = processedData.trim();

      final lines = const LineSplitter().convert(processedData);
      String jsonAccumulator = '';

      for (final line in lines) {
        if (jsonAccumulator == '' && line == ',') {
          continue;
        }

        jsonAccumulator += line;

        try {
          final json = jsonDecode(jsonAccumulator) as Map<String, dynamic>;
          final streamEvents = _parseStreamEvent(json);
          if (streamEvents != null) {
            events.add(streamEvents);
          }

          jsonAccumulator = '';
          _streamBuffer = '';
        } catch (_) {
          continue;
        }
      }

      if (jsonAccumulator.isNotEmpty) {
        _streamBuffer = jsonAccumulator;
      }
    } catch (e) {
      client.logger.warning('Failed to parse Google stream chunk: $e');
      client.logger.fine('Raw chunk: $chunk');
      client.logger.fine('Buffer content: $_streamBuffer');
    }

    return events;
  }

  ChatStreamEvent? _parseStreamEvent(Map<String, dynamic> json) {
    final candidates = json['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final content = candidates.first['content'] as Map<String, dynamic>?;
    if (content == null) return null;

    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) return null;

    for (final part in parts) {
      final isThought = part['thought'] as bool? ?? false;
      final text = part['text'] as String?;

      if (isThought && text != null && text.isNotEmpty) {
        return ThinkingDeltaEvent(text);
      }

      if (!isThought && text != null && text.isNotEmpty) {
        return TextDeltaEvent(text);
      }

      final inlineData = part['inlineData'] as Map<String, dynamic>?;
      if (inlineData != null) {
        final mimeType = inlineData['mimeType'] as String?;
        final data = inlineData['data'] as String?;
        if (mimeType != null && data != null && mimeType.startsWith('image/')) {
          return TextDeltaEvent('[Generated image: $mimeType]');
        }
      }

      final functionCall = part['functionCall'] as Map<String, dynamic>?;
      if (functionCall != null) {
        final name = functionCall['name'] as String;
        final args = functionCall['args'] as Map<String, dynamic>? ?? {};

        final toolCall = ToolCall(
          id: 'call_$name',
          callType: 'function',
          function: FunctionCall(
            name: name,
            arguments: jsonEncode(args),
          ),
        );

        return ToolCallDeltaEvent(toolCall);
      }
    }

    return null;
  }

  Map<String, dynamic> _buildRequestBodyFromPrompt(
    List<ModelMessage> promptMessages,
    List<Tool>? tools,
    bool stream, {
    LanguageModelCallOptions? options,
  }) {
    final contents = <Map<String, dynamic>>[];

    final systemTexts = <String>[];

    if (config.systemPrompt != null && config.systemPrompt!.isNotEmpty) {
      systemTexts.add(config.systemPrompt!);
    }

    final remainingMessages = <ModelMessage>[];
    var isPrefix = true;
    for (final message in promptMessages) {
      if (isPrefix && message.role == ChatRole.system) {
        for (final part in message.parts) {
          if (part is TextContentPart && part.text.isNotEmpty) {
            systemTexts.add(part.text);
          } else if (part is ReasoningContentPart && part.text.isNotEmpty) {
            // Treat reasoning content in system messages as plain text.
            systemTexts.add(part.text);
          }
        }
      } else {
        isPrefix = false;
        remainingMessages.add(message);
      }
    }

    for (final message in remainingMessages) {
      contents.add(_convertPromptMessage(message));
    }

    final body = <String, dynamic>{
      'contents': contents,
    };

    if (systemTexts.isNotEmpty) {
      body['systemInstruction'] = {
        'parts': systemTexts.map((text) => {'text': text}).toList(),
      };
    }

    final generationConfig = <String, dynamic>{};

    final effectiveMaxTokens = options?.maxTokens ?? config.maxTokens;
    final effectiveTemperature = options?.temperature ?? config.temperature;
    final effectiveTopP = options?.topP ?? config.topP;
    final effectiveTopK = options?.topK ?? config.topK;
    final effectiveStopSequences =
        options?.stopSequences ?? config.stopSequences;

    if (effectiveMaxTokens != null) {
      generationConfig['maxOutputTokens'] = effectiveMaxTokens;
    }
    if (effectiveTemperature != null) {
      generationConfig['temperature'] = effectiveTemperature;
    }
    if (effectiveTopP != null) {
      generationConfig['topP'] = effectiveTopP;
    }
    if (effectiveTopK != null) {
      generationConfig['topK'] = effectiveTopK;
    }
    if (config.candidateCount != null) {
      generationConfig['candidateCount'] = config.candidateCount;
    }
    if (effectiveStopSequences != null) {
      generationConfig['stopSequences'] = effectiveStopSequences;
    }

    if (config.frequencyPenalty != null) {
      generationConfig['frequencyPenalty'] = config.frequencyPenalty;
    }
    if (config.presencePenalty != null) {
      generationConfig['presencePenalty'] = config.presencePenalty;
    }
    if (config.seed != null) {
      generationConfig['seed'] = config.seed;
    }

    if (config.reasoningEffort != null || config.includeThoughts == true) {
      final thinkingConfig = <String, dynamic>{};

      if (config.includeThoughts == true) {
        thinkingConfig['includeThoughts'] = true;
      }

      if (config.reasoningEffort != null) {
        thinkingConfig['reasoningEffort'] = config.reasoningEffort!.value;
      }

      if (config.thinkingBudgetTokens != null) {
        thinkingConfig['thinkingBudget'] = config.thinkingBudgetTokens;
      }

      if (thinkingConfig.isNotEmpty) {
        generationConfig['thinkingConfig'] = thinkingConfig;
      }
    } else if (stream) {
      generationConfig['thinkingConfig'] = {
        'includeThoughts': true,
      };
    }

    if (config.enableImageGeneration == true) {
      if (config.responseModalities != null) {
        generationConfig['responseModalities'] = config.responseModalities;
      } else {
        generationConfig['responseModalities'] = ['TEXT', 'IMAGE'];
      }
      generationConfig['responseMimeType'] = 'text/plain';
    }

    if (config.jsonSchema?.schema != null &&
        config.enableImageGeneration != true) {
      generationConfig['responseMimeType'] ??= 'application/json';
      generationConfig['responseSchema'] = config.jsonSchema!.schema;
    }

    if (generationConfig.isNotEmpty) {
      body['generationConfig'] = generationConfig;
    }

    final effectiveSafetySettings =
        config.safetySettings ?? GoogleConfig.defaultSafetySettings;
    if (effectiveSafetySettings.isNotEmpty) {
      body['safetySettings'] =
          effectiveSafetySettings.map((s) => s.toJson()).toList();
    }

    // Preferred tool path: unified callTools (function + provider-defined).
    //
    // When [callTools] is provided, it takes precedence over the legacy
    // [tools] list and allows providers to interpret provider-defined
    // tools (for example Google grounding tools) in a Vercel AI SDK-style
    // fashion. This mirrors the behavior of `google-prepare-tools.ts`.
    final callTools = options?.callTools;
    if (callTools != null && callTools.isNotEmpty) {
      final functionSpecs = <FunctionCallToolSpec>[];
      final providerSpecs = <ProviderDefinedToolSpec>[];

      for (final spec in callTools) {
        if (spec is FunctionCallToolSpec) {
          functionSpecs.add(spec);
        } else if (spec is ProviderDefinedToolSpec) {
          providerSpecs.add(spec);
        }
      }

      final hasFunctionTools = functionSpecs.isNotEmpty;
      final hasProviderDefinedTools = providerSpecs.isNotEmpty;

      // When both function tools and provider-defined tools are present,
      // we follow the Vercel semantics: provider-defined tools win and
      // function tools are ignored.
      if (hasProviderDefinedTools) {
        final googleTools = <Map<String, dynamic>>[];

        for (final spec in providerSpecs) {
          switch (spec.id) {
            case 'google.google_search':
              if (_isGemini2OrNewer) {
                // Gemini 2.x and newer use the new googleSearch tool.
                googleTools.add({'googleSearch': <String, dynamic>{}});
              } else if (_supportsDynamicRetrieval) {
                // Older Gemini models (1.5 Flash) use googleSearchRetrieval
                // with dynamicRetrievalConfig provided via args.
                final dynamicRetrievalConfig = <String, dynamic>{};
                final mode = spec.args['mode'];
                if (mode is String && mode.isNotEmpty) {
                  dynamicRetrievalConfig['mode'] = mode;
                }
                final dynamicThreshold = spec.args['dynamicThreshold'];
                if (dynamicThreshold is num) {
                  dynamicRetrievalConfig['dynamicThreshold'] = dynamicThreshold;
                }

                googleTools.add({
                  'googleSearchRetrieval': {
                    'dynamicRetrievalConfig': dynamicRetrievalConfig,
                  },
                });
              } else {
                // Fallback for non-Gemini-2 models without dynamic retrieval
                googleTools.add({
                  'googleSearchRetrieval': <String, dynamic>{},
                });
              }
              break;

            case 'google.url_context':
              if (_supportsUrlContextTool) {
                googleTools.add({'urlContext': <String, dynamic>{}});
              } else {
                client.logger.warning(
                  'The URL context tool is only supported on Gemini 2.x models. '
                  'Current model: ${config.model}',
                );
              }
              break;

            case 'google.code_execution':
              if (_supportsCodeExecutionTool) {
                googleTools.add({'codeExecution': <String, dynamic>{}});
              } else {
                client.logger.warning(
                  'The code execution tool is only supported on Gemini 2.x models. '
                  'Current model: ${config.model}',
                );
              }
              break;

            case 'google.file_search':
              if (_supportsFileSearchTool) {
                final args = <String, dynamic>{};
                for (final entry in spec.args.entries) {
                  args[entry.key] = entry.value;
                }
                googleTools.add({'fileSearch': args});
              } else {
                client.logger.warning(
                  'The file search tool is only supported on Gemini 2.5 models. '
                  'Current model: ${config.model}',
                );
              }
              break;

            case 'google.vertex_rag_store':
              if (_isGemini2OrNewer) {
                final ragCorpus = spec.args['ragCorpus'];
                final topK = spec.args['topK'];

                if (ragCorpus is String && ragCorpus.isNotEmpty) {
                  final ragStore = <String, dynamic>{
                    'rag_resources': {
                      'rag_corpus': ragCorpus,
                    },
                  };
                  if (topK is num) {
                    ragStore['similarity_top_k'] = topK;
                  }

                  googleTools.add({
                    'retrieval': {
                      'vertex_rag_store': ragStore,
                    },
                  });
                } else {
                  client.logger.warning(
                    'google.vertex_rag_store tool requires a non-empty "ragCorpus" argument.',
                  );
                }
              } else {
                client.logger.warning(
                  'The Vertex RAG store tool is only supported on Gemini 2.x models. '
                  'Current model: ${config.model}',
                );
              }
              break;

            default:
              client.logger.warning(
                'Unsupported provider-defined tool id for Google: ${spec.id}',
              );
              break;
          }
        }

        if (googleTools.isNotEmpty) {
          body['tools'] = googleTools;
        }

        // When provider-defined tools are used we intentionally skip
        // functionDeclarations and toolConfig, mirroring the behavior of
        // the Vercel AI SDK where provider-defined tools form an
        // alternative tool path.
        return body;
      }

      // If only function tools are present in callTools, fall back to the
      // same behavior as the legacy [tools] list but using the wrapped
      // [Tool] instances from [FunctionCallToolSpec].
      if (hasFunctionTools) {
        final functionTools =
            functionSpecs.map((spec) => spec.tool).toList(growable: false);

        body['tools'] = [
          {
            'functionDeclarations':
                functionTools.map((t) => _convertTool(t)).toList(),
          },
        ];

        final effectiveToolChoice = options?.toolChoice ?? config.toolChoice;
        if (effectiveToolChoice != null) {
          body['toolConfig'] =
              _convertToolChoice(effectiveToolChoice, functionTools);
        }

        return body;
      }
    }

    final effectiveTools = options?.tools ?? tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] = [
        {
          'functionDeclarations':
              effectiveTools.map((t) => _convertTool(t)).toList(),
        },
      ];

      final effectiveToolChoice = options?.toolChoice ?? config.toolChoice;
      if (effectiveToolChoice != null) {
        body['toolConfig'] =
            _convertToolChoice(effectiveToolChoice, effectiveTools);
      }
    }

    // Collect non-function tools (google_search, file_search, etc.).
    final extraTools = (body['tools'] as List?)?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];

    // Google Search grounding tools.
    //
    // We mirror the Vercel AI SDK semantics:
    // - For Gemini 2.x / 3.x / latest aliases, use the new googleSearch tool.
    // - For Gemini 1.5 Flash models that support dynamic retrieval, use
    //   googleSearchRetrieval with dynamicRetrievalConfig.
    // - For other non-Gemini-2 models, fall back to basic googleSearchRetrieval.
    if (config.webSearchEnabled) {
      final webConfig = config.webSearchConfig;

      // Map unified WebSearchConfig.mode to Google dynamic retrieval modes:
      // - 'MODE_DYNAMIC' / 'mode_dynamic' -> MODE_DYNAMIC
      // - 'MODE_UNSPECIFIED' / 'mode_unspecified' -> MODE_UNSPECIFIED
      // - 'auto'   -> MODE_DYNAMIC      (run retrieval when needed)
      // - 'on'     -> MODE_UNSPECIFIED  (always allow retrieval)
      // - 'always' -> MODE_UNSPECIFIED
      String? dynamicMode;
      if (webConfig != null && webConfig.mode != null) {
        final rawMode = webConfig.mode!;

        // Direct Google modes take precedence if provided.
        if (rawMode == 'MODE_DYNAMIC' || rawMode == 'mode_dynamic') {
          dynamicMode = 'MODE_DYNAMIC';
        } else if (rawMode == 'MODE_UNSPECIFIED' ||
            rawMode == 'mode_unspecified') {
          dynamicMode = 'MODE_UNSPECIFIED';
        } else {
          final mode = rawMode.toLowerCase();
          if (mode == 'auto') {
            dynamicMode = 'MODE_DYNAMIC';
          } else if (mode == 'on' || mode == 'always') {
            dynamicMode = 'MODE_UNSPECIFIED';
          }
        }
      }

      if (_isGemini2OrNewer) {
        // Gemini 2.x and newer use the new googleSearch grounding tool.
        //
        // Note: The current Google API surface does not expose mode /
        // dynamicThreshold configuration on this tool, so we intentionally
        // send an empty config object (same as Vercel).
        extraTools.add({'googleSearch': <String, dynamic>{}});
      } else if (_supportsDynamicRetrieval) {
        // Older Gemini models (1.5 Flash) use googleSearchRetrieval with
        // dynamicRetrievalConfig. We propagate mode and optional
        // dynamicThreshold (when provided via WebSearchConfig).
        final dynamicRetrievalConfig = <String, dynamic>{};
        if (dynamicMode != null) {
          dynamicRetrievalConfig['mode'] = dynamicMode;
        }

        if (webConfig?.dynamicThreshold != null) {
          dynamicRetrievalConfig['dynamicThreshold'] =
              webConfig!.dynamicThreshold;
        }

        extraTools.add({
          'googleSearchRetrieval': {
            'dynamicRetrievalConfig': dynamicRetrievalConfig,
          },
        });
      } else {
        // Fallback for non-Gemini-2 models without dynamic retrieval
        // support: basic googleSearchRetrieval without extra config.
        extraTools.add({
          'googleSearchRetrieval': <String, dynamic>{},
        });
      }
    }

    // Gemini File Search tool (file_search).
    final fileSearchConfig = config.fileSearchConfig;
    if (fileSearchConfig != null && _supportsFileSearchTool) {
      final fs = <String, dynamic>{
        'fileSearchStoreNames': fileSearchConfig.fileSearchStoreNames,
      };
      if (fileSearchConfig.topK != null) {
        fs['topK'] = fileSearchConfig.topK;
      }
      if (fileSearchConfig.metadataFilter != null) {
        fs['metadataFilter'] = fileSearchConfig.metadataFilter;
      }
      extraTools.add({'fileSearch': fs});
    } else if (fileSearchConfig != null && !_supportsFileSearchTool) {
      client.logger.warning(
        'Google File Search tool is only supported on Gemini 2.5 models. '
        'Current model: ${config.model}',
      );
    }

    // Gemini code execution tool (code_execution).
    if (config.codeExecutionEnabled && _supportsCodeExecutionTool) {
      extraTools.add({'codeExecution': <String, dynamic>{}});
    } else if (config.codeExecutionEnabled && !_supportsCodeExecutionTool) {
      client.logger.warning(
        'Gemini code execution tool is only supported on Gemini 2.x models. '
        'Current model: ${config.model}',
      );
    }

    // Gemini URL context tool (url_context).
    if (config.urlContextEnabled && _supportsUrlContextTool) {
      extraTools.add({'urlContext': <String, dynamic>{}});
    } else if (config.urlContextEnabled && !_supportsUrlContextTool) {
      client.logger.warning(
        'Gemini URL context tool is only supported on Gemini 2.x models. '
        'Current model: ${config.model}',
      );
    }

    if (extraTools.isNotEmpty) {
      body['tools'] = extraTools;
    }

    return body;
  }

  /// Whether current model is a "latest" alias that resolves to a modern
  /// Gemini model.
  ///
  /// We follow the Vercel AI SDK logic:
  /// - gemini-flash-latest
  /// - gemini-flash-lite-latest
  /// - gemini-pro-latest
  bool get _isLatestModel {
    final model = config.model;
    return model == 'gemini-flash-latest' ||
        model == 'gemini-flash-lite-latest' ||
        model == 'gemini-pro-latest';
  }

  /// Whether current model should be treated as Gemini 2.x or newer.
  ///
  /// This mirrors Vercel's `isGemini2orNewer` check and is used to decide
  /// when to enable the new `googleSearch` grounding tool.
  bool get _isGemini2OrNewer {
    final model = config.model;
    return model.contains('gemini-2') ||
        model.contains('gemini-3') ||
        _isLatestModel;
  }

  /// Whether current model supports dynamic retrieval configuration.
  ///
  /// Mirrors Vercel's `supportsDynamicRetrieval` logic:
  /// - gemini-1.5-flash (excluding -8b variants)
  bool get _supportsDynamicRetrieval {
    final model = config.model;
    return model.contains('gemini-1.5-flash') && !model.contains('-8b');
  }

  /// Whether current model supports the Gemini File Search tool.
  ///
  /// File Search is currently limited to Gemini 2.5 models.
  bool get _supportsFileSearchTool {
    final model = config.model;
    return model.contains('gemini-2.5');
  }

  /// Whether current model supports Gemini code execution and URL context
  /// provider-defined tools.
  ///
  /// These tools are currently limited to Gemini 2.x models.
  bool get _supportsCodeExecutionTool {
    final model = config.model;
    return model.contains('gemini-2');
  }

  bool get _supportsUrlContextTool => _supportsCodeExecutionTool;

  Map<String, dynamic> _convertPromptMessage(ModelMessage message) {
    final parts = <Map<String, dynamic>>[];

    final role = message.role == ChatRole.user ? 'user' : 'model';

    for (final part in message.parts) {
      if (part is TextContentPart) {
        if (part.text.isNotEmpty) {
          parts.add({'text': part.text});
        }
      } else if (part is ReasoningContentPart) {
        if (part.text.isNotEmpty) {
          // For input, treat reasoning as regular text.
          parts.add({'text': part.text});
        }
      } else if (part is FileContentPart) {
        _convertFilePart(part, parts);
      } else if (part is UrlFileContentPart) {
        parts.add({
          'fileData': {
            'mimeType': _inferImageMimeTypeFromUrl(part.url),
            'fileUri': part.url,
          },
        });
      } else if (part is ToolCallContentPart &&
          message.role == ChatRole.assistant) {
        _convertToolCallPart(part, parts);
      } else if (part is ToolResultContentPart &&
          message.role == ChatRole.user) {
        _convertToolResultPart(part, parts);
      }
    }

    return {'role': role, 'parts': parts};
  }

  /// Infer image MIME type from URL path.
  ///
  /// This is a best-effort guess based on common file extensions.
  String _inferImageMimeTypeFromUrl(String url) {
    try {
      final path = Uri.parse(url).path.toLowerCase();
      if (path.endsWith('.png')) return 'image/png';
      if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
        return 'image/jpeg';
      }
      if (path.endsWith('.gif')) return 'image/gif';
      if (path.endsWith('.webp')) return 'image/webp';
    } catch (_) {
      // Fallback to generic JPEG if parsing fails.
    }
    return 'image/jpeg';
  }

  void _convertFilePart(
    FileContentPart part,
    List<Map<String, dynamic>> parts,
  ) {
    final mime = part.mime;
    final data = part.data;

    // If a URI is provided (e.g. Files API resource or remote URL),
    // prefer fileData representation instead of inlining bytes.
    if (part.uri != null && part.uri!.isNotEmpty) {
      parts.add({
        'fileData': {
          'mimeType': mime.mimeType,
          'fileUri': part.uri,
        },
      });
      return;
    }

    // Image handling
    if (mime.mimeType.startsWith('image/')) {
      const supportedFormats = [
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp'
      ];
      if (!supportedFormats.contains(mime.mimeType)) {
        parts.add({
          'text':
              '[Unsupported image format: ${mime.mimeType}. Supported formats: ${supportedFormats.join(', ')}]',
        });
      } else {
        parts.add({
          'inlineData': {
            'mimeType': mime.mimeType,
            'data': base64Encode(data),
          },
        });
      }
      return;
    }

    // Generic file handling
    if (data.length > config.maxInlineDataSize) {
      parts.add({
        'text':
            '[File too large: ${data.length} bytes. Maximum size: ${config.maxInlineDataSize} bytes]',
      });
    } else if (mime.isDocument || mime.isAudio || mime.isVideo) {
      parts.add({
        'inlineData': {
          'mimeType': mime.mimeType,
          'data': base64Encode(data),
        },
      });
    } else {
      parts.add({
        'text':
            '[File type ${mime.description} (${mime.mimeType}) may not be supported by Google AI]',
      });
    }
  }

  void _convertToolCallPart(
    ToolCallContentPart part,
    List<Map<String, dynamic>> parts,
  ) {
    try {
      final args = jsonDecode(part.argumentsJson);
      parts.add({
        'functionCall': {
          'name': part.toolName,
          'args': args,
        },
      });
    } catch (_) {
      parts.add({
        'text': '[Error: Invalid tool call arguments for ${part.toolName}]',
      });
    }
  }

  void _convertToolResultPart(
    ToolResultContentPart part,
    List<Map<String, dynamic>> parts,
  ) {
    String responseText;

    final payload = part.payload;
    if (payload is ToolResultTextPayload) {
      responseText = payload.value;
    } else if (payload is ToolResultJsonPayload) {
      responseText = jsonEncode(payload.value);
    } else if (payload is ToolResultErrorPayload) {
      responseText = payload.message;
    } else if (payload is ToolResultContentPayload) {
      final texts = <String>[];
      for (final nested in payload.parts) {
        if (nested is TextContentPart) {
          texts.add(nested.text);
        }
      }
      responseText = texts.join('\n');
    } else {
      responseText = '';
    }

    parts.add({
      'functionResponse': {
        'name': part.toolName,
        'response': {
          'name': part.toolName,
          'content': [
            {
              'text': responseText,
            }
          ],
        },
      },
    });
  }

  /// Convert Tool to Google format.
  Map<String, dynamic> _convertTool(Tool tool) {
    try {
      final schema = tool.function.parameters.toJson();

      return {
        'name': tool.function.name,
        'description': tool.function.description.isNotEmpty
            ? tool.function.description
            : 'No description provided',
        'parameters': schema,
      };
    } catch (e) {
      client.logger.warning('Failed to convert tool ${tool.function.name}: $e');
      return {
        'name': tool.function.name,
        'description': tool.function.description.isNotEmpty
            ? tool.function.description
            : 'Tool with invalid schema',
        'parameters': {
          'type': 'object',
          'properties': <String, dynamic>{},
        },
      };
    }
  }

  /// Convert ToolChoice to Google format.
  ///
  /// See:
  /// https://ai.google.dev/gemini-api/docs/function-calling?example=meeting#function_calling_modes
  Map<String, dynamic> _convertToolChoice(
    ToolChoice toolChoice,
    List<Tool> tools,
  ) {
    switch (toolChoice) {
      case AutoToolChoice():
        return {
          'functionCallingConfig': {
            'mode': 'AUTO',
          },
        };
      case AnyToolChoice():
        return {
          'functionCallingConfig': {
            'mode': 'ANY',
          },
        };
      case SpecificToolChoice(toolName: final toolName):
        final toolExists = tools.any((tool) => tool.function.name == toolName);
        if (!toolExists) {
          client.logger.warning(
            'Tool "$toolName" specified in SpecificToolChoice not found in available tools',
          );
          return {
            'functionCallingConfig': {
              'mode': 'AUTO',
            },
          };
        }
        return {
          'functionCallingConfig': {
            'mode': 'ANY',
            'allowedFunctionNames': [toolName],
          },
        };
      case NoneToolChoice():
        return {
          'functionCallingConfig': {
            'mode': 'NONE',
          },
        };
    }
  }
}

/// Google chat response implementation for the Google sub-package.
class GoogleChatResponse implements ChatResponse {
  final Map<String, dynamic> _rawResponse;

  /// Logical model identifier used for this call.
  ///
  /// The Google API may not always echo the model id back in the
  /// response body, so we store the configured model explicitly
  /// for observability and metadata purposes.
  final String _modelId;

  GoogleChatResponse(this._rawResponse, this._modelId);

  /// Full raw response returned by the Google API.
  Map<String, dynamic> get rawResponse => _rawResponse;

  /// All candidates returned by the model (if any).
  ///
  /// This exposes the complete candidate list so callers can access
  /// alternative generations when [GoogleConfig.candidateCount] > 1.
  List<Map<String, dynamic>>? get candidates {
    final rawCandidates = _rawResponse['candidates'] as List?;
    if (rawCandidates == null || rawCandidates.isEmpty) return null;

    return rawCandidates.map<Map<String, dynamic>>((candidate) {
      if (candidate is Map<String, dynamic>) {
        return candidate;
      }
      if (candidate is Map) {
        return Map<String, dynamic>.from(candidate);
      }
      return <String, dynamic>{};
    }).toList();
  }

  @override
  String? get text {
    final candidates = _rawResponse['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final content = candidates.first['content'] as Map<String, dynamic>?;
    if (content == null) return null;

    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) return null;

    // Only return non-thinking content.
    final textParts = parts
        .where((part) {
          final isThought = part['thought'] as bool? ?? false;
          final text = part['text'] as String?;
          return !isThought && text != null && text.isNotEmpty;
        })
        .map((part) => part['text'] as String)
        .toList();

    return textParts.isEmpty ? null : textParts.join('\n');
  }

  @override
  String? get thinking {
    final candidates = _rawResponse['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final content = candidates.first['content'] as Map<String, dynamic>?;
    if (content == null) return null;

    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) return null;

    final thinkingParts = parts
        .where((part) {
          final isThought = part['thought'] as bool? ?? false;
          final text = part['text'] as String?;
          return isThought && text != null && text.isNotEmpty;
        })
        .map((part) => part['text'] as String)
        .toList();

    return thinkingParts.isEmpty ? null : thinkingParts.join('\n');
  }

  @override
  List<ToolCall>? get toolCalls {
    final candidates = _rawResponse['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final content = candidates.first['content'] as Map<String, dynamic>?;
    if (content == null) return null;

    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) return null;

    final functionCalls = <ToolCall>[];

    for (final part in parts) {
      final functionCall = part['functionCall'] as Map<String, dynamic>?;
      if (functionCall != null) {
        final name = functionCall['name'] as String;
        final args = functionCall['args'] as Map<String, dynamic>? ?? {};

        functionCalls.add(
          ToolCall(
            id: 'call_$name',
            callType: 'function',
            function: FunctionCall(name: name, arguments: jsonEncode(args)),
          ),
        );
      }
    }

    return functionCalls.isEmpty ? null : functionCalls;
  }

  @override
  UsageInfo? get usage {
    final rawUsageMetadata = _rawResponse['usageMetadata'];
    if (rawUsageMetadata == null) return null;

    final Map<String, dynamic> usageMetadata;
    if (rawUsageMetadata is Map<String, dynamic>) {
      usageMetadata = rawUsageMetadata;
    } else if (rawUsageMetadata is Map) {
      usageMetadata = Map<String, dynamic>.from(rawUsageMetadata);
    } else {
      return null;
    }

    return UsageInfo(
      promptTokens: usageMetadata['promptTokenCount'] as int?,
      completionTokens: usageMetadata['candidatesTokenCount'] as int?,
      totalTokens: usageMetadata['totalTokenCount'] as int?,
      reasoningTokens: usageMetadata['thoughtsTokenCount'] as int?,
    );
  }

  @override
  List<CallWarning> get warnings => const [];

  @override
  Map<String, dynamic>? get metadata {
    final candidates = _rawResponse['candidates'] as List?;
    final promptFeedback =
        _rawResponse['promptFeedback'] as Map<String, dynamic>?;
    final usageMetadata = _rawResponse['usageMetadata'];

    bool hasThinkingBlocks = false;
    bool hasSafetyRatings = false;

    Map<String, dynamic>? groundingMetadata;
    Map<String, dynamic>? urlContextMetadata;
    dynamic candidateSafetyRatings;

    if (candidates != null && candidates.isNotEmpty) {
      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      if (parts != null) {
        for (final part in parts) {
          final isThought = part['thought'] as bool? ?? false;
          if (isThought) {
            hasThinkingBlocks = true;
            break;
          }
        }
      }

      final candidate = candidates.first as Map<String, dynamic>?;
      final candidateSafety = candidate?['safetyRatings'];
      if (candidateSafety is List && candidateSafety.isNotEmpty) {
        hasSafetyRatings = true;
        candidateSafetyRatings = candidateSafety;
      }

      final gm = candidate?['groundingMetadata'];
      if (gm is Map<String, dynamic>) {
        groundingMetadata = gm;
      } else if (gm is Map) {
        groundingMetadata = Map<String, dynamic>.from(gm);
      }

      final ucm = candidate?['urlContextMetadata'];
      if (ucm is Map<String, dynamic>) {
        urlContextMetadata = ucm;
      } else if (ucm is Map) {
        urlContextMetadata = Map<String, dynamic>.from(ucm);
      }
    }

    final promptSafety = promptFeedback?['safetyRatings'];
    if (!hasSafetyRatings && promptSafety is List && promptSafety.isNotEmpty) {
      hasSafetyRatings = true;
    }

    return {
      'provider': 'google',
      'model': _modelId,
      if (candidates != null) 'candidateCount': candidates.length,
      'hasThinking': hasThinkingBlocks,
      'hasSafetyRatings': hasSafetyRatings,
      // Expose raw safety and grounding data for observability.
      if (candidateSafetyRatings != null)
        'candidateSafetyRatings': candidateSafetyRatings,
      if (promptFeedback != null) 'promptFeedback': promptFeedback,
      if (groundingMetadata != null) 'groundingMetadata': groundingMetadata,
      if (urlContextMetadata != null) 'urlContextMetadata': urlContextMetadata,
      if (usageMetadata != null) 'usageMetadata': usageMetadata,
    };
  }

  @override
  CallMetadata? get callMetadata {
    final data = metadata;
    if (data == null) return null;
    return CallMetadata.fromJson(data);
  }

  @override
  String toString() {
    final textContent = text;
    final calls = toolCalls;
    final thinkingContent = thinking;

    final parts = <String>[];

    if (thinkingContent != null) {
      parts.add('Thinking: $thinkingContent');
    }

    if (calls != null) {
      parts.add(calls.map((c) => c.toString()).join('\n'));
    }

    if (textContent != null) {
      parts.add(textContent);
    }

    return parts.join('\n');
  }
}
