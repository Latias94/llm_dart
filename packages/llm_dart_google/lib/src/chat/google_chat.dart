import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../client/google_client.dart';
import '../config/google_config.dart';
import '../files/google_files.dart';

class GoogleChat implements ChatCapability {
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
    CancelToken? cancelToken,
  }) async {
    final effectiveTools = tools ?? config.tools;
    final requestBody = _buildRequestBody(messages, effectiveTools, false);
    final responseData = await client.postJson(
      _buildEndpoint(stream: false),
      requestBody,
      cancelToken: cancelToken,
    );
    return _parseResponse(responseData);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    _resetStreamState();

    final effectiveTools = tools ?? config.tools;
    final requestBody = _buildRequestBody(messages, effectiveTools, true);

    final stream = client.postStreamRaw(
      _buildEndpoint(stream: true),
      requestBody,
      cancelToken: cancelToken,
    );

    await for (final chunk in stream) {
      final events = _parseStreamEvents(chunk);
      for (final event in events) {
        yield event;
      }
    }
  }

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
      throw _handleDioError(e);
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

  LLMError _handleDioError(DioException e) {
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

  Map<String, dynamic> _buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
  ) {
    final promptMessages =
        messages.map((message) => message.toPromptMessage()).toList();

    return _buildRequestBodyFromPrompt(promptMessages, tools, stream);
  }

  Map<String, dynamic> _buildRequestBodyFromPrompt(
    List<ChatPromptMessage> promptMessages,
    List<Tool>? tools,
    bool stream,
  ) {
    final contents = <Map<String, dynamic>>[];

    final systemTexts = <String>[];

    if (config.systemPrompt != null && config.systemPrompt!.isNotEmpty) {
      systemTexts.add(config.systemPrompt!);
    }

    final remainingMessages = <ChatPromptMessage>[];
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
    if (config.candidateCount != null) {
      generationConfig['candidateCount'] = config.candidateCount;
    }
    if (config.stopSequences != null) {
      generationConfig['stopSequences'] = config.stopSequences;
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

    final effectiveTools = tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] = [
        {
          'functionDeclarations':
              effectiveTools.map((t) => _convertTool(t)).toList(),
        },
      ];

      final effectiveToolChoice = config.toolChoice;
      if (effectiveToolChoice != null) {
        body['toolConfig'] =
            _convertToolChoice(effectiveToolChoice, effectiveTools);
      }
    }

    // Collect non-function tools (google_search, file_search, etc.).
    final extraTools = (body['tools'] as List?)?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];

    // Google Search grounding tool (google_search).
    if (config.webSearchEnabled && _supportsGoogleSearchTool) {
      extraTools.add({
        'googleSearch': <String, dynamic>{},
      });
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

  /// Whether current model supports the Google Search grounding tool.
  ///
  /// The official docs recommend using `google_search` for Gemini 2.0+
  /// models. We gate the tool on model id to avoid sending unsupported
  /// parameters to older endpoints.
  bool get _supportsGoogleSearchTool {
    final model = config.model;
    return model.contains('gemini-2.');
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

  Map<String, dynamic> _convertPromptMessage(ChatPromptMessage message) {
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
