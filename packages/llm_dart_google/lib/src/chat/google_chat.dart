import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../client/google_client.dart';
import '../config/google_config.dart';

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

class GoogleChat implements ChatCapability {
  final GoogleClient client;
  final GoogleConfig config;

  static final Map<String, GoogleFile> _fileCache = {};

  String _streamBuffer = '';
  bool _isFirstChunk = true;

  GoogleChat(this.client, this.config);

  String get chatEndpoint {
    final endpoint = config.stream
        ? 'models/${config.model}:streamGenerateContent'
        : 'models/${config.model}:generateContent';
    return endpoint;
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    final requestBody = _buildRequestBody(messages, tools, false);
    final responseData = await client.postJson(
      chatEndpoint,
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
      chatEndpoint,
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

    return GoogleChatResponse(responseData);
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
    final contents = <Map<String, dynamic>>[];

    for (final message in messages) {
      contents.add(_convertMessage(message));
    }

    final body = <String, dynamic>{
      'contents': contents,
    };

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
    } else if (config.stream) {
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
        body['tool_config'] =
            _convertToolChoice(effectiveToolChoice, effectiveTools);
      }
    }

    return body;
  }

  Map<String, dynamic> _convertMessage(ChatMessage message) {
    final parts = <Map<String, dynamic>>[];

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
        final supportedFormats = [
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
        break;
      case FileMessage(mime: final mime, data: final data):
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
        break;
      case ImageUrlMessage(url: final url):
        parts.add({
          'text':
              '[Image URL not supported by Google. Please upload the image directly: $url]',
        });
        break;
      case ToolUseMessage(toolCalls: final toolCalls):
        for (final toolCall in toolCalls) {
          try {
            final args = jsonDecode(toolCall.function.arguments);
            parts.add({
              'functionCall': {
                'name': toolCall.function.name,
                'args': args,
              },
            });
          } catch (e) {
            parts.add({
              'text':
                  '[Error: Invalid tool call arguments for ${toolCall.function.name}]',
            });
          }
        }
        break;
      case ToolResultMessage(results: final results):
        for (final result in results) {
          parts.add({
            'functionResponse': {
              'name': result.function.name,
              'response': {
                'name': result.function.name,
                'content': [
                  {
                    'text': result.function.arguments,
                  }
                ],
              },
            },
          });
        }
        break;
    }

    return {'role': role, 'parts': parts};
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
        final toolExists = tools.any((tool) => tool.function.name == toolName);
        if (!toolExists) {
          client.logger.warning(
            'Tool "$toolName" specified in SpecificToolChoice not found in available tools',
          );
          return {
            'function_calling_config': {
              'mode': 'AUTO',
            },
          };
        }
        return {
          'function_calling_config': {
            'mode': 'ANY',
            'allowed_function_names': [toolName],
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
}

/// Google chat response implementation for the Google sub-package.
class GoogleChatResponse implements ChatResponse {
  final Map<String, dynamic> _rawResponse;

  GoogleChatResponse(this._rawResponse);

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
  Map<String, dynamic>? get metadata => null;

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
