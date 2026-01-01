import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'client.dart';
import 'config.dart';

class _GoogleBuiltRequest {
  final Map<String, dynamic> body;
  final ToolNameMapping toolNameMapping;

  const _GoogleBuiltRequest({
    required this.body,
    required this.toolNameMapping,
  });
}

/// Google file upload response
class GoogleFile {
  final String name;
  final String displayName;
  final String mimeType;
  final int sizeBytes;
  final String state;
  final String? uri;

  const GoogleFile({
    required this.name,
    required this.displayName,
    required this.mimeType,
    required this.sizeBytes,
    required this.state,
    this.uri,
  });

  factory GoogleFile.fromJson(Map<String, dynamic> json) => GoogleFile(
        name: json['name'] as String,
        displayName: json['displayName'] as String,
        mimeType: json['mimeType'] as String,
        sizeBytes: int.parse(json['sizeBytes'] as String),
        state: json['state'] as String,
        uri: json['uri'] as String?,
      );

  bool get isActive => state == 'ACTIVE';
}

/// Google Chat capability implementation
///
/// This module handles all chat-related functionality for Google providers,
/// including streaming, tool calling, and reasoning model support.
class GoogleChat implements ChatCapability, ChatStreamPartsCapability {
  final GoogleClient client;
  final GoogleConfig config;

  /// Cache for uploaded files to avoid re-uploading
  static final Map<String, GoogleFile> _fileCache = {};

  // Buffer for incomplete JSON chunks
  String _streamBuffer = '';
  bool _isFirstChunk = true;

  GoogleChat(this.client, this.config);

  String get _chatEndpoint => 'models/${config.model}:generateContent';

  String get _chatStreamEndpoint =>
      'models/${config.model}:streamGenerateContent';

  _GoogleBuiltRequest _buildRequest(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
  ) {
    final effectiveTools = tools ?? config.tools;
    final toolNameMapping = _createToolNameMapping(effectiveTools);
    return _GoogleBuiltRequest(
      body:
          _buildRequestBody(messages, effectiveTools, stream, toolNameMapping),
      toolNameMapping: toolNameMapping,
    );
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    final built = _buildRequest(messages, tools, false);
    final responseData = await client.postJson(
      _chatEndpoint,
      built.body,
      cancelToken: cancelToken,
    );
    return _parseResponse(responseData, built.toolNameMapping);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    // Reset stream state for new requests
    _resetStreamState();

    final effectiveTools = tools ?? config.tools;
    final built = _buildRequest(messages, effectiveTools, true);

    // Create JSON array stream
    final stream = client.postStreamRaw(
      _chatStreamEndpoint,
      built.body,
      cancelToken: cancelToken,
    );

    await for (final chunk in stream) {
      final events = _parseStreamEvents(chunk, built.toolNameMapping);
      for (final event in events) {
        yield event;
      }
    }
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    final effectiveTools = tools ?? config.tools;
    final built = _buildRequest(messages, effectiveTools, true);
    final requestBody = built.body;
    final toolNameMapping = built.toolNameMapping;

    var streamBuffer = '';
    final nameCounts = <String, int>{};

    var inText = false;
    var inThinking = false;

    final fullText = StringBuffer();
    final fullThinking = StringBuffer();
    final functionCallParts = <Map<String, dynamic>>[];
    Map<String, dynamic>? usageMetadata;

    final startedToolCalls = <String>{};

    List<Map<String, dynamic>> extractJsonObjects(String chunk) {
      streamBuffer += chunk;
      final results = <Map<String, dynamic>>[];

      while (true) {
        final start = streamBuffer.indexOf('{');
        if (start == -1) {
          // Keep at most a small tail to avoid unbounded growth on junk.
          if (streamBuffer.length > 8192) {
            streamBuffer = streamBuffer.substring(streamBuffer.length - 8192);
          }
          return results;
        }

        if (start > 0) {
          streamBuffer = streamBuffer.substring(start);
        }

        var depth = 0;
        var inString = false;
        var escaped = false;
        int? end;

        for (var i = 0; i < streamBuffer.length; i++) {
          final ch = streamBuffer.codeUnitAt(i);

          if (inString) {
            if (escaped) {
              escaped = false;
              continue;
            }
            if (ch == 0x5C) {
              escaped = true;
              continue;
            }
            if (ch == 0x22) {
              inString = false;
            }
            continue;
          }

          if (ch == 0x22) {
            inString = true;
            continue;
          }

          if (ch == 0x7B) {
            depth++;
            continue;
          }
          if (ch == 0x7D) {
            depth--;
            if (depth == 0) {
              end = i;
              break;
            }
          }
        }

        if (end == null) {
          return results; // Need more data.
        }

        final jsonStr = streamBuffer.substring(0, end + 1);
        try {
          final decoded = jsonDecode(jsonStr);
          if (decoded is Map<String, dynamic>) {
            results.add(decoded);
          }
        } catch (_) {
          // Ignore malformed object and continue searching.
        }

        streamBuffer = streamBuffer.substring(end + 1);
      }
    }

    String nextToolCallId(String name) {
      final count = nameCounts[name] ?? 0;
      nameCounts[name] = count + 1;
      return count == 0 ? 'call_$name' : 'call_${name}_$count';
    }

    List<LLMStreamPart> closeOpenBlocks() {
      final parts = <LLMStreamPart>[];
      if (inText) {
        inText = false;
        parts.add(LLMTextEndPart(fullText.toString()));
      }
      if (inThinking) {
        inThinking = false;
        parts.add(LLMReasoningEndPart(fullThinking.toString()));
      }
      for (final id in startedToolCalls) {
        parts.add(LLMToolCallEndPart(id));
      }
      return parts;
    }

    final stream = client.postStreamRaw(
      _chatStreamEndpoint,
      requestBody,
      cancelToken: cancelToken,
    );

    await for (final chunk in stream) {
      for (final json in extractJsonObjects(chunk)) {
        if (json.containsKey('error')) {
          try {
            throw _handleGoogleApiError(json);
          } catch (e) {
            final err =
                e is LLMError ? e : ProviderError('Google API error: $e');
            yield LLMErrorPart(err);
            return;
          }
        }

        final candidates = json['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) continue;

        final candidate = candidates.first as Map<String, dynamic>;
        final content = candidate['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List?;

        if (json['usageMetadata'] is Map<String, dynamic>) {
          usageMetadata = json['usageMetadata'] as Map<String, dynamic>;
        } else if (json['usageMetadata'] is Map) {
          usageMetadata =
              Map<String, dynamic>.from(json['usageMetadata'] as Map);
        }

        if (parts != null) {
          for (final part in parts) {
            if (part is! Map<String, dynamic>) continue;

            final functionCall = part['functionCall'] as Map<String, dynamic>?;
            if (functionCall != null) {
              final requestName = functionCall['name'] as String? ?? '';
              final args = functionCall['args'] as Map<String, dynamic>? ?? {};
              if (requestName.isNotEmpty) {
                if (toolNameMapping.providerToolIdForRequestName(requestName) !=
                    null) {
                  continue;
                }
                final name = toolNameMapping
                        .originalFunctionNameForRequestName(requestName) ??
                    requestName;
                final id = nextToolCallId(name);
                final toolCall = ToolCall(
                  id: id,
                  callType: 'function',
                  function: FunctionCall(
                    name: name,
                    arguments: jsonEncode(args),
                  ),
                );
                startedToolCalls.add(id);
                functionCallParts.add({
                  'functionCall': {
                    'name': name,
                    'args': args,
                  },
                });
                yield LLMToolCallStartPart(toolCall);
              }
              continue;
            }

            final inlineData = part['inlineData'] as Map<String, dynamic>?;
            if (inlineData != null) {
              final mimeType = inlineData['mimeType'] as String?;
              if (mimeType != null && mimeType.startsWith('image/')) {
                final placeholder = '[Generated image: $mimeType]';
                if (!inText) {
                  inText = true;
                  yield const LLMTextStartPart();
                }
                fullText.write(placeholder);
                yield LLMTextDeltaPart(placeholder);
              }
              continue;
            }

            final isThought = part['thought'] as bool? ?? false;
            final text = part['text'] as String?;
            if (text != null && text.isNotEmpty) {
              if (isThought) {
                if (!inThinking) {
                  inThinking = true;
                  yield const LLMReasoningStartPart();
                }
                fullThinking.write(text);
                yield LLMReasoningDeltaPart(text);
              } else {
                if (!inText) {
                  inText = true;
                  yield const LLMTextStartPart();
                }
                fullText.write(text);
                yield LLMTextDeltaPart(text);
              }
            }
          }
        }

        final finishReason = candidate['finishReason'] as String?;
        if (finishReason != null) {
          for (final part in closeOpenBlocks()) {
            yield part;
          }

          final responseParts = <Map<String, dynamic>>[
            if (fullThinking.isNotEmpty)
              {'text': fullThinking.toString(), 'thought': true},
            if (fullText.isNotEmpty) {'text': fullText.toString()},
            ...functionCallParts,
          ];

          final response = GoogleChatResponse({
            'modelVersion': config.model,
            'candidates': [
              {
                'content': {'parts': responseParts},
                'finishReason': finishReason,
              },
            ],
            if (usageMetadata != null) 'usageMetadata': usageMetadata,
          }, toolNameMapping);

          final metadata = response.providerMetadata;
          if (metadata != null && metadata.isNotEmpty) {
            yield LLMProviderMetadataPart(metadata);
          }
          yield LLMFinishPart(response);
          return;
        }
      }
    }

    // Best-effort finish if stream ends unexpectedly.
    for (final part in closeOpenBlocks()) {
      yield part;
    }
    final responseParts = <Map<String, dynamic>>[
      if (fullThinking.isNotEmpty)
        {'text': fullThinking.toString(), 'thought': true},
      if (fullText.isNotEmpty) {'text': fullText.toString()},
      ...functionCallParts,
    ];
    final response = GoogleChatResponse({
      'modelVersion': config.model,
      'candidates': [
        {
          'content': {'parts': responseParts},
        },
      ],
      if (usageMetadata != null) 'usageMetadata': usageMetadata,
    }, toolNameMapping);
    final metadata = response.providerMetadata;
    if (metadata != null && metadata.isNotEmpty) {
      yield LLMProviderMetadataPart(metadata);
    }
    yield LLMFinishPart(response);
  }

  /// Reset stream parsing state for new requests
  void _resetStreamState() {
    _streamBuffer = '';
    _isFirstChunk = true;
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) async {
    return chatWithTools(messages, null, cancelToken: cancelToken);
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

  /// Upload a file to Google AI Files API
  Future<GoogleFile> uploadFile({
    required List<int> data,
    required String mimeType,
    required String displayName,
  }) async {
    try {
      // Create file metadata
      final metadata = {
        'file': {
          'displayName': displayName,
          'mimeType': mimeType,
        }
      };

      // Create multipart form data
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

      // Cache the uploaded file
      final cacheKey = '${displayName}_${data.length}_$mimeType';
      _fileCache[cacheKey] = uploadedFile;

      return uploadedFile;
    } on DioException catch (e) {
      throw await _handleDioError(e);
    } catch (e) {
      throw GenericError('File upload error: $e');
    }
  }

  /// Get or upload a file, using cache when possible
  Future<GoogleFile?> getOrUploadFile({
    required List<int> data,
    required String mimeType,
    required String displayName,
  }) async {
    final cacheKey = '${displayName}_${data.length}_$mimeType';

    // Check cache first
    final cachedFile = _fileCache[cacheKey];
    if (cachedFile != null && cachedFile.isActive) {
      return cachedFile;
    }

    // Upload new file
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

  /// Handle Dio errors and convert to appropriate LLM errors
  Future<LLMError> _handleDioError(DioException e) async {
    // Handle Google-specific error response format first
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

    // Fall back to standard error handling
    return await DioErrorHandler.handleDioError(e, 'Google');
  }

  /// Handle Google API error response format
  LLMError _handleGoogleApiError(Map<String, dynamic> responseData) {
    if (!responseData.containsKey('error')) {
      throw ArgumentError('No error found in response data');
    }

    final error = responseData['error'] as Map<String, dynamic>;
    final message = error['message'] as String? ?? 'Unknown error';
    final details = error['details'] as List?;

    // Handle specific Google API error types
    if (details != null) {
      for (final detail in details) {
        if (detail is Map && detail['reason'] == 'API_KEY_INVALID') {
          return const AuthError('Invalid Google API key');
        }
      }
    }

    return ProviderError('Google API error: $message');
  }

  /// Parse response from Google API
  GoogleChatResponse _parseResponse(
    Map<String, dynamic> responseData,
    ToolNameMapping toolNameMapping,
  ) {
    // Check for Google API errors first
    if (responseData.containsKey('error')) {
      throw _handleGoogleApiError(responseData);
    }

    return GoogleChatResponse(responseData, toolNameMapping);
  }

  /// Parse stream events from JSON array chunks
  List<ChatStreamEvent> _parseStreamEvents(
    String chunk,
    ToolNameMapping toolNameMapping,
  ) {
    final events = <ChatStreamEvent>[];

    // Google's streaming format returns a JSON array: [{...}, {...}, {...}]
    // We use the default JSON array format for compatibility with our HTTP client
    // Based on flutter_gemini implementation

    try {
      // Add chunk to buffer
      _streamBuffer += chunk;

      String processedData = _streamBuffer.trim();

      // Handle array format - remove brackets and commas
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

      // Split by lines and try to parse complete JSON objects
      final lines = const LineSplitter().convert(processedData);
      String jsonAccumulator = '';

      for (final line in lines) {
        if (jsonAccumulator == '' && line == ',') {
          continue;
        }

        jsonAccumulator += line;

        try {
          // Try to parse the accumulated JSON
          final json = jsonDecode(jsonAccumulator) as Map<String, dynamic>;
          final streamEvents = _parseStreamEvent(json, toolNameMapping);
          if (streamEvents != null) {
            events.add(streamEvents);
          }

          // Successfully parsed, clear accumulator and update buffer
          jsonAccumulator = '';
          _streamBuffer = '';
        } catch (e) {
          // JSON incomplete, continue accumulating
          continue;
        }
      }

      // Keep incomplete JSON in buffer for next chunk
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

  /// Parse individual stream event
  ChatStreamEvent? _parseStreamEvent(
    Map<String, dynamic> json,
    ToolNameMapping toolNameMapping,
  ) {
    final candidates = json['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final content = candidates.first['content'] as Map<String, dynamic>?;
    if (content == null) return null;

    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) return null;

    // Process all parts in the response
    for (final part in parts) {
      // Check for thinking content first - according to Google API docs,
      // thinking content has a 'thought' boolean flag set to true
      final isThought = part['thought'] as bool? ?? false;
      final text = part['text'] as String?;

      if (isThought && text != null && text.isNotEmpty) {
        return ThinkingDeltaEvent(text);
      }

      // Regular text content (not thinking)
      if (!isThought && text != null && text.isNotEmpty) {
        return TextDeltaEvent(text);
      }

      // Check for inline image data (generated images)
      final inlineData = part['inlineData'] as Map<String, dynamic>?;
      if (inlineData != null) {
        final mimeType = inlineData['mimeType'] as String?;
        final data = inlineData['data'] as String?;
        if (mimeType != null && data != null && mimeType.startsWith('image/')) {
          // This is a generated image - we could emit a custom event for this
          // For now, we'll include it as text content indicating image generation
          return TextDeltaEvent('[Generated image: $mimeType]');
        }
      }

      // Function calls
      final functionCall = part['functionCall'] as Map<String, dynamic>?;
      if (functionCall != null) {
        final requestName = functionCall['name'] as String;
        final args = functionCall['args'] as Map<String, dynamic>? ?? {};

        // Provider-native tools should not be surfaced as local tool calls;
        // otherwise local tool loops may try to execute them.
        if (toolNameMapping.providerToolIdForRequestName(requestName) != null) {
          return null;
        }

        final name =
            toolNameMapping.originalFunctionNameForRequestName(requestName) ??
                requestName;
        final toolCall = ToolCall(
          id: 'call_$name',
          callType: 'function',
          function: FunctionCall(name: name, arguments: jsonEncode(args)),
        );

        return ToolCallDeltaEvent(toolCall);
      }
    }

    // Check if this is the final message
    final finishReason = candidates.first['finishReason'] as String?;
    if (finishReason != null) {
      final usage = json['usageMetadata'] as Map<String, dynamic>?;
      final response = GoogleChatResponse({
        'candidates': [],
        'usageMetadata': usage,
      }, toolNameMapping);
      return CompletionEvent(response);
    }

    return null;
  }

  /// Build request body for Google API
  Map<String, dynamic> _buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
    ToolNameMapping toolNameMapping,
  ) {
    final contents = <Map<String, dynamic>>[];

    // Add system message if configured
    if (config.systemPrompt != null) {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': config.systemPrompt},
        ],
      });
    }

    // Convert messages to Google format
    for (final message in messages) {
      // Skip system messages as they are handled separately
      if (message.role == ChatRole.system) continue;

      contents.add(_convertMessage(message, toolNameMapping));
    }

    return _buildBodyWithConfig(contents, tools, stream, toolNameMapping);
  }

  /// Create request body with configuration
  Map<String, dynamic> _buildBodyWithConfig(
    List<Map<String, dynamic>> contents,
    List<Tool>? tools,
    bool isStreaming,
    ToolNameMapping toolNameMapping,
  ) {
    final body = <String, dynamic>{'contents': contents};

    // Add generation config if needed
    final generationConfig = <String, dynamic>{};

    // Standard GenerationConfig fields
    if (config.candidateCount != null) {
      generationConfig['candidateCount'] = config.candidateCount;
    }
    if (config.stopSequences != null && config.stopSequences!.isNotEmpty) {
      generationConfig['stopSequences'] = config.stopSequences;
    }
    if (config.maxTokens != null) {
      generationConfig['maxOutputTokens'] = config.maxTokens;
    }
    if (config.temperature != null) {
      generationConfig['temperature'] = config.temperature;
    }
    if (config.topP != null) {
      generationConfig['topP'] = config.topP;
    }
    if (config.topK != null) {
      generationConfig['topK'] = config.topK;
    }

    // Add structured output if configured
    if (config.jsonSchema != null && config.jsonSchema!.schema != null) {
      generationConfig['responseMimeType'] = 'application/json';

      // Remove additionalProperties if present (Google API doesn't support it)
      final schema = Map<String, dynamic>.from(config.jsonSchema!.schema!);
      schema.remove('additionalProperties');

      generationConfig['responseSchema'] = schema;
    }

    // Add thinking configuration for reasoning models
    if (config.reasoningEffort != null ||
        config.thinkingBudgetTokens != null ||
        config.includeThoughts != null) {
      final thinkingConfig = <String, dynamic>{};

      // Include thoughts in response (for getting thinking summaries)
      if (config.includeThoughts != null) {
        thinkingConfig['includeThoughts'] = config.includeThoughts;
      } else if (isStreaming) {
        // For streaming, we want to include thoughts by default to get thinking deltas
        thinkingConfig['includeThoughts'] = true;
      }

      // Set thinking budget (token limit for thinking)
      if (config.thinkingBudgetTokens != null) {
        thinkingConfig['thinkingBudget'] = config.thinkingBudgetTokens;
      }

      if (thinkingConfig.isNotEmpty) {
        generationConfig['thinkingConfig'] = thinkingConfig;
      }
    } else if (isStreaming) {
      // For streaming without explicit thinking config, still enable includeThoughts
      // to get thinking deltas in the stream
      generationConfig['thinkingConfig'] = {
        'includeThoughts': true,
      };
    }

    // Add image generation configuration
    if (config.enableImageGeneration == true) {
      if (config.responseModalities != null) {
        generationConfig['responseModalities'] = config.responseModalities;
      } else {
        // Default to text and image modalities for image generation
        generationConfig['responseModalities'] = ['TEXT', 'IMAGE'];
      }
      generationConfig['responseMimeType'] = 'text/plain';
    }

    if (generationConfig.isNotEmpty) {
      body['generationConfig'] = generationConfig;
    }

    // Add safety settings
    final effectiveSafetySettings =
        config.safetySettings ?? GoogleConfig.defaultSafetySettings;
    if (effectiveSafetySettings.isNotEmpty) {
      body['safetySettings'] =
          effectiveSafetySettings.map((s) => s.toJson()).toList();
    }

    // Add tools if provided
    final effectiveTools = tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] = <Map<String, dynamic>>[
        {
          'functionDeclarations': effectiveTools
              .map((t) => _convertFunctionTool(t, toolNameMapping))
              .toList(),
        },
      ];

      // Add tool choice configuration
      final effectiveToolChoice = config.toolChoice;
      if (effectiveToolChoice != null) {
        body['tool_config'] = _convertToolChoice(
          effectiveToolChoice,
          effectiveTools,
          toolNameMapping,
        );
      }
    }

    final supportsGemini2OrNewer = _isGemini2OrNewerModel();
    final providerTools = config.originalConfig?.providerTools;
    if (supportsGemini2OrNewer &&
        providerTools != null &&
        providerTools.isNotEmpty) {
      final enabledIds = providerTools.map((t) => t.id).toSet();

      if (enabledIds.contains('google.code_execution')) {
        body['tools'] ??= [];
        (body['tools'] as List).add(<String, dynamic>{
          'codeExecution': <String, dynamic>{},
        });
      }

      if (enabledIds.contains('google.url_context')) {
        body['tools'] ??= [];
        (body['tools'] as List).add(<String, dynamic>{
          'urlContext': <String, dynamic>{},
        });
      }
    }

    if (config.webSearchEnabled) {
      body['tools'] ??= [];
      (body['tools'] as List).add(_buildGoogleSearchTool());
    }

    return body;
  }

  Map<String, dynamic> _buildGoogleSearchTool() {
    final modelId = config.model;
    final isLatest = const [
      'gemini-flash-latest',
      'gemini-flash-lite-latest',
      'gemini-pro-latest',
    ].contains(modelId);
    final isGemini2OrNewer = modelId.contains('gemini-2') ||
        modelId.contains('gemini-3') ||
        isLatest;

    if (isGemini2OrNewer) {
      return <String, dynamic>{
        'googleSearch': <String, dynamic>{},
      };
    }

    final options = config.webSearchToolOptions;
    final dynamicConfig = options == null
        ? null
        : <String, dynamic>{
            if (options.mode != null) 'mode': options.mode!.apiValue,
            if (options.dynamicThreshold != null)
              'dynamicThreshold': options.dynamicThreshold,
          };

    return <String, dynamic>{
      'googleSearchRetrieval': <String, dynamic>{
        if (dynamicConfig != null && dynamicConfig.isNotEmpty)
          'dynamicRetrievalConfig': dynamicConfig,
      },
    };
  }

  bool _isGemini2OrNewerModel() {
    final modelId = config.model;
    final isLatest = const [
      'gemini-flash-latest',
      'gemini-flash-lite-latest',
      'gemini-pro-latest',
    ].contains(modelId);

    return modelId.contains('gemini-2') ||
        modelId.contains('gemini-3') ||
        isLatest;
  }

  /// Convert ChatMessage to Google format
  Map<String, dynamic> _convertMessage(
    ChatMessage message,
    ToolNameMapping toolNameMapping,
  ) {
    final parts = <Map<String, dynamic>>[];

    // Determine role - Google API uses 'user', 'model', 'function'
    String role;
    switch (message.messageType) {
      case ToolResultMessage():
        role = 'function';
        break;
      default:
        role = message.role == ChatRole.user ? 'user' : 'model';
    }

    switch (message.messageType) {
      case TextMessage():
        parts.add({'text': message.content});
        break;
      case ImageMessage(mime: final mime, data: final data):
        parts.add({
          'inlineData': {
            'mimeType': mime.mimeType,
            'data': base64Encode(data),
          },
        });
        break;
      case FileMessage(mime: final mime, data: final data):
        if (data.length > config.maxInlineDataSize) {
          throw InvalidRequestError(
            'File too large for Google inlineData: ${data.length} bytes '
            '(maxInlineDataSize=${config.maxInlineDataSize}).',
          );
        }
        parts.add({
          'inlineData': {
            'mimeType': mime.mimeType,
            'data': base64Encode(data),
          },
        });
        break;
      case ImageUrlMessage(url: final url):
        parts.add({
          'fileData': {
            'fileUri': url,
            'mimeType': _guessImageMimeTypeFromUrl(url) ?? 'image/png',
          },
        });
        break;
      case ToolUseMessage(toolCalls: final toolCalls):
        for (final toolCall in toolCalls) {
          try {
            final args = jsonDecode(toolCall.function.arguments);
            final requestName =
                toolNameMapping.requestNameForFunction(toolCall.function.name);
            parts.add({
              'functionCall': {
                'name': requestName,
                'args': args,
              },
            });
          } catch (e) {
            client.logger.warning(
                'Failed to parse tool call arguments: ${toolCall.function.arguments}, error: $e');
            parts.add({
              'text':
                  '[Error: Invalid tool call arguments for ${toolCall.function.name}]',
            });
          }
        }
        break;
      case ToolResultMessage(results: final results):
        for (final result in results) {
          final requestName =
              toolNameMapping.requestNameForFunction(result.function.name);
          parts.add({
            'functionResponse': {
              'name': requestName,
              'response': {
                'name': requestName,
                'content': jsonDecode(result.function.arguments),
              },
            },
          });
        }
        break;
    }

    return {
      'role': role,
      'parts': parts,
    };
  }

  static String? _guessImageMimeTypeFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return null;
  }

  /// Convert Tool to Google format
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
      // Return a minimal valid tool definition
      return {
        'name': tool.function.name,
        'description': tool.function.description.isNotEmpty
            ? tool.function.description
            : 'Tool with invalid schema',
        'parameters': {
          'type': 'object',
          'properties': {},
        },
      };
    }
  }

  Map<String, dynamic> _convertFunctionTool(
    Tool tool,
    ToolNameMapping toolNameMapping,
  ) {
    final converted = _convertTool(tool);
    final requestName =
        toolNameMapping.requestNameForFunction(tool.function.name);
    if (requestName != tool.function.name) {
      converted['name'] = requestName;
    }
    return converted;
  }

  /// Convert ToolChoice to Google format
  ///
  /// https://ai.google.dev/gemini-api/docs/function-calling?example=meeting#function_calling_modes
  ///
  Map<String, dynamic> _convertToolChoice(
    ToolChoice toolChoice,
    List<Tool> tools,
    ToolNameMapping toolNameMapping,
  ) {
    switch (toolChoice) {
      case AutoToolChoice():
        return {
          'function_calling_config': {
            'mode': 'AUTO',
          },
        };
      case AnyToolChoice():
        return {
          'function_calling_config': {
            'mode': 'ANY',
          },
        };
      case SpecificToolChoice(toolName: final toolName):
        // Validate that the specified tool exists in the available tools
        final toolExists = tools.any((tool) => tool.function.name == toolName);
        if (!toolExists) {
          client.logger.warning(
              'Tool "$toolName" specified in SpecificToolChoice not found in available tools');
          // Fall back to AUTO mode if tool not found
          return {
            'function_calling_config': {
              'mode': 'AUTO',
            },
          };
        }
        final requestName = toolNameMapping.requestNameForFunction(toolName);
        return {
          'function_calling_config': {
            'mode': 'ANY',
            'allowed_function_names': [requestName],
          },
        };
      case NoneToolChoice():
        return {
          'function_calling_config': {
            'mode': 'NONE',
          },
        };
    }
  }

  ToolNameMapping _createToolNameMapping(List<Tool>? tools) {
    final functionToolNames =
        (tools ?? const <Tool>[]).map((t) => t.function.name);

    final providerToolRequestNamesById = <String, String>{};

    // Reserve provider-native web search tool name when enabled.
    if (config.webSearchEnabled) {
      providerToolRequestNamesById['google.google_search'] = 'google_search';
    }

    final providerTools =
        config.originalConfig?.providerTools ?? const <ProviderTool>[];
    final supportsGemini2OrNewer = _isGemini2OrNewerModel();
    if (supportsGemini2OrNewer) {
      final enabledIds = providerTools.map((t) => t.id).toSet();
      if (enabledIds.contains('google.code_execution')) {
        providerToolRequestNamesById['google.code_execution'] =
            'code_execution';
      }
      if (enabledIds.contains('google.url_context')) {
        providerToolRequestNamesById['google.url_context'] = 'url_context';
      }
    }

    return createToolNameMapping(
      functionToolNames: functionToolNames,
      providerToolRequestNamesById: providerToolRequestNamesById,
    );
  }
}

/// Google chat response implementation
class GoogleChatResponse implements ChatResponse {
  final Map<String, dynamic> _rawResponse;
  final ToolNameMapping? _toolNameMapping;

  GoogleChatResponse(this._rawResponse, [this._toolNameMapping]);

  @override
  String? get text {
    final candidates = _rawResponse['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final content = candidates.first['content'] as Map<String, dynamic>?;
    if (content == null) return null;

    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) return null;

    // According to Google API docs, only return non-thinking content
    // Thinking content has thought: true flag, regular content has thought: false or no thought field
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
    // Extract thinking content from candidates
    final candidates = _rawResponse['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final content = candidates.first['content'] as Map<String, dynamic>?;
    if (content == null) return null;

    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) return null;

    // According to Google API docs, thinking content has thought: true flag
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
  Map<String, dynamic>? get providerMetadata {
    final modelVersion = _rawResponse['modelVersion'] as String? ??
        _rawResponse['model'] as String?;

    final candidates = _rawResponse['candidates'] as List?;
    final firstCandidate =
        (candidates != null && candidates.isNotEmpty && candidates.first is Map)
            ? Map<String, dynamic>.from(candidates.first as Map)
            : null;

    final finishReason = firstCandidate?['finishReason'] as String?;
    final safetyRatings = firstCandidate?['safetyRatings'];
    final promptFeedback = _rawResponse['promptFeedback'];

    final rawUsageMetadata = _rawResponse['usageMetadata'];
    final Map<String, dynamic>? usageMetadata;
    if (rawUsageMetadata is Map<String, dynamic>) {
      usageMetadata = rawUsageMetadata;
    } else if (rawUsageMetadata is Map) {
      usageMetadata = Map<String, dynamic>.from(rawUsageMetadata);
    } else {
      usageMetadata = null;
    }

    if (modelVersion == null &&
        finishReason == null &&
        safetyRatings == null &&
        promptFeedback == null &&
        usageMetadata == null) {
      return null;
    }

    return {
      'google': {
        if (modelVersion != null) 'model': modelVersion,
        if (finishReason != null) 'finishReason': finishReason,
        if (finishReason != null) 'stopReason': finishReason,
        if (usageMetadata != null)
          'usage': {
            if (usageMetadata['promptTokenCount'] != null)
              'promptTokens': usageMetadata['promptTokenCount'],
            if (usageMetadata['candidatesTokenCount'] != null)
              'completionTokens': usageMetadata['candidatesTokenCount'],
            if (usageMetadata['totalTokenCount'] != null)
              'totalTokens': usageMetadata['totalTokenCount'],
            if (usageMetadata['thoughtsTokenCount'] != null)
              'reasoningTokens': usageMetadata['thoughtsTokenCount'],
          },
        if (promptFeedback != null) 'promptFeedback': promptFeedback,
        if (safetyRatings != null) 'safetyRatings': safetyRatings,
      },
    };
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
    final nameCounts = <String, int>{};

    for (final part in parts) {
      final functionCall = part['functionCall'] as Map<String, dynamic>?;
      if (functionCall != null) {
        final requestName = functionCall['name'] as String;
        final args = functionCall['args'] as Map<String, dynamic>? ?? {};

        if (requestName == 'google_search') {
          continue;
        }

        final name =
            _toolNameMapping?.originalFunctionNameForRequestName(requestName) ??
                requestName;
        final count = nameCounts[name] ?? 0;
        nameCounts[name] = count + 1;
        final id = count == 0 ? 'call_$name' : 'call_${name}_$count';

        functionCalls.add(
          ToolCall(
            id: id,
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

    // Safely convert Map<dynamic, dynamic> to Map<String, dynamic>
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
