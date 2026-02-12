import 'dart:convert';

import 'package:dio/dio.dart' hide CancelToken;
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'client.dart';
import 'config.dart';

/// Ollama Chat capability implementation
///
/// This module handles all chat-related functionality for Ollama providers,
/// including streaming and tool calling. Ollama is designed for local deployment.
class OllamaChat
    implements
        ChatCapability,
        ChatStreamPartsCapability,
        PromptChatCapability,
        PromptChatStreamPartsCapability {
  final OllamaClient client;
  final OllamaConfig config;
  final Map<String, int> _streamToolCallNameCounts = <String, int>{};

  OllamaChat(this.client, this.config);

  String get chatEndpoint => '/api/chat';

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    if (config.baseUrl.isEmpty) {
      throw const InvalidRequestError('Missing Ollama base URL');
    }

    try {
      final requestBody = _buildRequestBody(messages, tools, false);
      final responseData = await client.postJson(
        chatEndpoint,
        requestBody,
        cancelToken: cancelToken,
      );
      return _parseResponse(responseData);
    } on DioException catch (e) {
      throw await DioErrorHandler.handleDioError(e, 'Ollama');
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  @override
  Future<ChatResponse> chatPrompt(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async {
    if (config.baseUrl.isEmpty) {
      throw const InvalidRequestError('Missing Ollama base URL');
    }

    try {
      final requestBody = _buildRequestBodyFromPrompt(prompt, tools, false);
      final responseData = await client.postJson(
        chatEndpoint,
        requestBody,
        cancelToken: cancelToken,
      );
      return _parseResponse(responseData);
    } on DioException catch (e) {
      throw await DioErrorHandler.handleDioError(e, 'Ollama');
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  String _nextStreamToolCallId(String name) {
    final count = _streamToolCallNameCounts[name] ?? 0;
    _streamToolCallNameCounts[name] = count + 1;
    return count == 0 ? 'call_$name' : 'call_${name}_$count';
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    if (config.baseUrl.isEmpty) {
      yield const LLMErrorPart(InvalidRequestError('Missing Ollama base URL'));
      return;
    }

    _streamToolCallNameCounts.clear();

    final effectiveTools = tools ?? config.tools;
    final requestBody = _buildRequestBody(messages, effectiveTools, true);
    yield* _chatStreamPartsFromRequestBody(
      requestBody,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    if (config.baseUrl.isEmpty) {
      yield const LLMErrorPart(InvalidRequestError('Missing Ollama base URL'));
      return;
    }

    _streamToolCallNameCounts.clear();

    final requestBody = _buildRequestBodyFromPrompt(prompt, tools, true);
    yield* _chatStreamPartsFromRequestBody(
      requestBody,
      cancelToken: cancelToken,
    );
  }

  Stream<LLMStreamPart> _chatStreamPartsFromRequestBody(
    Map<String, dynamic> requestBody, {
    CancelToken? cancelToken,
  }) async* {
    final jsonlParser = JsonlChunkParser();

    var inText = false;
    var inThinking = false;

    final fullText = StringBuffer();
    final fullThinking = StringBuffer();
    final currentText = StringBuffer();
    final currentThinking = StringBuffer();

    String? currentTextBlockId;
    String? currentThinkingBlockId;
    var blockCounter = 0;

    final startedToolCalls = <String>{};
    final endedToolCalls = <String>{};
    final toolAccums = <String, _ToolCallAccum>{};
    var didEmitResponseMetadata = false;

    try {
      final stream = client.postStreamRaw(
        chatEndpoint,
        requestBody,
        cancelToken: cancelToken,
      );

      await for (final chunk in stream) {
        for (final json in jsonlParser.parseObjects(chunk)) {
          if (!didEmitResponseMetadata) {
            final model = json['model'] as String? ?? config.model;
            if (model.isNotEmpty) {
              didEmitResponseMetadata = true;
              yield LLMResponseMetadataPart(
                model: model,
                raw: {'model': model},
              );
            }
          }

          final message = json['message'] as Map<String, dynamic>?;
          if (message != null) {
            final thinking = message['thinking'] as String?;
            if (thinking != null && thinking.isNotEmpty) {
              if (inText) {
                inText = false;
                yield LLMTextEndPart(
                  currentText.toString(),
                  blockId: currentTextBlockId,
                );
                currentText.clear();
                currentTextBlockId = null;
              }
              if (!inThinking) {
                inThinking = true;
                currentThinkingBlockId ??= '${blockCounter++}';
                yield LLMReasoningStartPart(blockId: currentThinkingBlockId);
                currentThinking.clear();
              }
              fullThinking.write(thinking);
              currentThinking.write(thinking);
              yield LLMReasoningDeltaPart(
                thinking,
                blockId: currentThinkingBlockId,
              );
            }

            final content = message['content'] as String?;
            if (content != null && content.isNotEmpty) {
              if (inThinking) {
                inThinking = false;
                yield LLMReasoningEndPart(
                  currentThinking.toString(),
                  blockId: currentThinkingBlockId,
                );
                currentThinking.clear();
                currentThinkingBlockId = null;
              }
              if (!inText) {
                inText = true;
                currentTextBlockId ??= '${blockCounter++}';
                yield LLMTextStartPart(blockId: currentTextBlockId);
                currentText.clear();
              }
              fullText.write(content);
              currentText.write(content);
              yield LLMTextDeltaPart(content, blockId: currentTextBlockId);
            }

            final toolCalls = message['tool_calls'] as List?;
            if (toolCalls != null && toolCalls.isNotEmpty) {
              for (final rawCall in toolCalls) {
                if (rawCall is! Map<String, dynamic>) {
                  continue;
                }

                final function =
                    rawCall['function'] as Map<String, dynamic>? ?? {};
                final name = function['name'] as String? ?? '';
                final args = function['arguments'];
                if (name.isEmpty) {
                  continue;
                }

                final id = _nextStreamToolCallId(name);
                final argsJson = args is String ? args : jsonEncode(args);

                final accum = toolAccums.putIfAbsent(
                    id, () => _ToolCallAccum(name: name));
                if (argsJson.isNotEmpty) {
                  accum.arguments.write(argsJson);
                }

                final toolCall = ToolCall(
                  id: id,
                  callType: 'function',
                  function: FunctionCall(
                    name: name,
                    arguments: argsJson,
                  ),
                );

                if (startedToolCalls.add(id)) {
                  yield LLMToolCallStartPart(toolCall);
                } else {
                  yield LLMToolCallDeltaPart(toolCall);
                }
              }
            }
          }

          final done = json['done'] as bool?;
          if (done == true) {
            if (inText) {
              yield LLMTextEndPart(
                currentText.toString(),
                blockId: currentTextBlockId,
              );
              inText = false;
              currentText.clear();
              currentTextBlockId = null;
            }
            if (inThinking) {
              yield LLMReasoningEndPart(
                currentThinking.toString(),
                blockId: currentThinkingBlockId,
              );
              inThinking = false;
              currentThinking.clear();
              currentThinkingBlockId = null;
            }
            for (final id in startedToolCalls) {
              if (endedToolCalls.add(id)) {
                yield LLMToolCallEndPart(id);
              }
            }

            final completedToolCalls = toolAccums.entries
                .map((e) => e.value.toToolCall(e.key))
                .toList(growable: false);

            final response = OllamaChatResponse({
              ...json,
              if (!json.containsKey('model')) 'model': config.model,
              'message': {
                ...?(json['message'] as Map?)?.cast<String, dynamic>(),
                'content': fullText.toString(),
                if (fullThinking.isNotEmpty)
                  'thinking': fullThinking.toString(),
                if (completedToolCalls.isNotEmpty)
                  'tool_calls': completedToolCalls
                      .map((c) => _toOllamaToolCallJson(c))
                      .toList(),
              },
            });

            final metadata = response.providerMetadata;
            if (metadata != null && metadata.isNotEmpty) {
              yield LLMProviderMetadataPart(metadata);
            }
            yield LLMFinishPart(
              response,
              usage: response.usage,
              finishReason: response.finishReason,
            );
            return;
          }
        }
      }

      // Best-effort finish if stream ends unexpectedly.
      if (inText) {
        yield LLMTextEndPart(
          currentText.toString(),
          blockId: currentTextBlockId,
        );
        inText = false;
        currentText.clear();
        currentTextBlockId = null;
      }
      if (inThinking) {
        yield LLMReasoningEndPart(
          currentThinking.toString(),
          blockId: currentThinkingBlockId,
        );
        inThinking = false;
        currentThinking.clear();
        currentThinkingBlockId = null;
      }
      for (final id in startedToolCalls) {
        if (endedToolCalls.add(id)) {
          yield LLMToolCallEndPart(id);
        }
      }
      final completedToolCalls = toolAccums.entries
          .map((e) => e.value.toToolCall(e.key))
          .toList(growable: false);
      final response = OllamaChatResponse({
        'done': true,
        'model': config.model,
        'message': {
          'role': 'assistant',
          'content': fullText.toString(),
          if (fullThinking.isNotEmpty) 'thinking': fullThinking.toString(),
          if (completedToolCalls.isNotEmpty)
            'tool_calls': completedToolCalls
                .map((c) => _toOllamaToolCallJson(c))
                .toList(),
        },
      });
      final metadata = response.providerMetadata;
      if (metadata != null && metadata.isNotEmpty) {
        yield LLMProviderMetadataPart(metadata);
      }
      yield LLMFinishPart(
        response,
        usage: response.usage,
        finishReason: response.finishReason,
      );
    } catch (e) {
      if (e is LLMError) {
        yield LLMErrorPart(e);
        return;
      }
      yield LLMErrorPart(GenericError('Unexpected error: $e'));
      return;
    }
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

  /// Parse response from Ollama API
  OllamaChatResponse _parseResponse(Map<String, dynamic> responseData) {
    return OllamaChatResponse(responseData);
  }

  /// Build request body for Ollama API
  Map<String, dynamic> _buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
  ) {
    final chatMessages = <Map<String, dynamic>>[];

    // Add system message if configured
    if (config.systemPrompt != null) {
      chatMessages.add({'role': 'system', 'content': config.systemPrompt});
    }

    // Convert messages to Ollama format
    for (final message in messages) {
      chatMessages.addAll(_convertChatMessage(message));
    }

    final body = <String, dynamic>{
      'model': config.model,
      'messages': chatMessages,
      'stream': stream,
    };

    // Add options - Ollama supports temperature and other parameters
    final options = <String, dynamic>{};
    if (config.temperature != null) options['temperature'] = config.temperature;
    if (config.topP != null) options['top_p'] = config.topP;
    if (config.topK != null) options['top_k'] = config.topK;
    if (config.maxTokens != null) options['num_predict'] = config.maxTokens;

    // Ollama-specific options
    if (config.numCtx != null) options['num_ctx'] = config.numCtx;
    if (config.numGpu != null) options['num_gpu'] = config.numGpu;
    if (config.numThread != null) options['num_thread'] = config.numThread;
    if (config.numa != null) options['numa'] = config.numa;
    if (config.numBatch != null) options['num_batch'] = config.numBatch;

    if (options.isNotEmpty) {
      body['options'] = options;
    }

    // Add keep_alive parameter for model memory management
    body['keep_alive'] = config.keepAlive ?? '5m'; // Default 5 minutes

    // Add raw mode if configured
    if (config.raw == true) {
      body['raw'] = true;
    }

    // Add structured output format if configured
    if (config.jsonSchema?.schema != null) {
      body['format'] = config.jsonSchema!.schema;
    }

    // Add tools if provided
    final effectiveTools = tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] = effectiveTools.map((t) => _convertTool(t)).toList();
    }

    // Add thinking parameter, if not passed, it will depend on the model's default behavior
    if (config.reasoning != null) {
      body['think'] = config.reasoning;
    }

    return body;
  }

  Map<String, dynamic> _buildRequestBodyFromPrompt(
    Prompt prompt,
    List<Tool>? tools,
    bool stream,
  ) {
    final chatMessages = <Map<String, dynamic>>[];

    if (config.systemPrompt != null && config.systemPrompt!.isNotEmpty) {
      chatMessages.add({'role': 'system', 'content': config.systemPrompt});
    }

    for (final message in prompt.messages) {
      chatMessages.addAll(_convertPromptMessage(message));
    }

    final body = <String, dynamic>{
      'model': config.model,
      'messages': chatMessages,
      'stream': stream,
    };

    final options = <String, dynamic>{};
    if (config.temperature != null) options['temperature'] = config.temperature;
    if (config.topP != null) options['top_p'] = config.topP;
    if (config.topK != null) options['top_k'] = config.topK;
    if (config.maxTokens != null) options['num_predict'] = config.maxTokens;
    if (config.numCtx != null) options['num_ctx'] = config.numCtx;
    if (config.numGpu != null) options['num_gpu'] = config.numGpu;
    if (config.numThread != null) options['num_thread'] = config.numThread;
    if (config.numa != null) options['numa'] = config.numa;
    if (config.numBatch != null) options['num_batch'] = config.numBatch;
    if (options.isNotEmpty) {
      body['options'] = options;
    }

    body['keep_alive'] = config.keepAlive ?? '5m';

    if (config.raw == true) {
      body['raw'] = true;
    }

    if (config.jsonSchema?.schema != null) {
      body['format'] = config.jsonSchema!.schema;
    }

    final effectiveTools = tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] = effectiveTools.map((t) => _convertTool(t)).toList();
    }

    if (config.reasoning != null) {
      body['think'] = config.reasoning;
    }

    return body;
  }

  /// Convert ChatMessage into one-or-more Ollama wire messages.
  ///
  /// Ollama represents tool results as separate `role=tool` messages, so a
  /// single `ToolResultMessage` may expand into multiple wire messages.
  List<Map<String, dynamic>> _convertChatMessage(ChatMessage message) {
    Map<String, dynamic> buildNormal({
      required String role,
      required String content,
      List<String>? images,
      List<Map<String, dynamic>>? toolCalls,
    }) {
      final m = <String, dynamic>{
        'role': role,
        'content': content,
      };
      if (message.name != null) {
        m['name'] = message.name;
      }
      if (images != null && images.isNotEmpty) {
        m['images'] = images;
      }
      if (toolCalls != null && toolCalls.isNotEmpty) {
        m['tool_calls'] = toolCalls;
      }
      return m;
    }

    switch (message.messageType) {
      case TextMessage():
        return [
          buildNormal(role: message.role.name, content: message.content),
        ];

      case ImageMessage(mime: final _, data: final data):
        final base64Image = base64Encode(data);
        return [
          buildNormal(
            role: message.role.name,
            content: message.content,
            images: [base64Image],
          ),
        ];

      case ImageUrlMessage(url: final url):
        client.logger
            .warning('Image URLs not directly supported by Ollama: $url');
        return [
          buildNormal(role: message.role.name, content: message.content),
        ];

      case ToolUseMessage(toolCalls: final toolCalls):
        final convertedToolCalls = <Map<String, dynamic>>[];
        for (final tc in toolCalls) {
          dynamic args;
          try {
            args = jsonDecode(tc.function.arguments);
          } catch (e) {
            throw InvalidRequestError(
              'Invalid JSON tool call arguments for tool "${tc.function.name}": $e',
            );
          }
          convertedToolCalls.add({
            'function': {
              'name': tc.function.name,
              'arguments': args,
            },
          });
        }
        return [
          buildNormal(
            role: message.role.name,
            content: message.content,
            toolCalls: convertedToolCalls,
          ),
        ];

      case ToolResultMessage(results: final results):
        final out = <Map<String, dynamic>>[];
        for (final result in results) {
          final toolContent = message.content.isNotEmpty
              ? '${message.content}\n${result.function.arguments}'
              : result.function.arguments;
          out.add({
            'role': 'tool',
            'content': toolContent,
            'tool_name': result.function.name,
          });
        }
        return out;

      default:
        return [
          buildNormal(role: message.role.name, content: message.content),
        ];
    }
  }

  List<Map<String, dynamic>> _convertPromptMessage(PromptMessage message) {
    final out = <Map<String, dynamic>>[];

    void addNormalMessage({
      required ChatRole role,
      required String content,
      List<String>? images,
      List<Map<String, dynamic>>? toolCalls,
    }) {
      out.add({
        'role': role.name,
        'content': content,
        if (message.name != null) 'name': message.name,
        if (images != null && images.isNotEmpty) 'images': images,
        if (toolCalls != null && toolCalls.isNotEmpty) 'tool_calls': toolCalls,
      });
    }

    if (message.parts.isEmpty) {
      addNormalMessage(role: message.role, content: '');
      return out;
    }

    ChatRole currentRole = message.role;
    final contentSegments = <String>[];
    final images = <String>[];
    final toolCalls = <Map<String, dynamic>>[];

    void flushIfNotEmpty() {
      if (contentSegments.isEmpty && images.isEmpty && toolCalls.isEmpty) {
        return;
      }
      addNormalMessage(
        role: currentRole,
        content: contentSegments.join('\n'),
        images: images.isEmpty ? null : List<String>.from(images),
        toolCalls: toolCalls.isEmpty
            ? null
            : List<Map<String, dynamic>>.from(toolCalls),
      );
      contentSegments.clear();
      images.clear();
      toolCalls.clear();
    }

    for (final part in message.parts) {
      switch (part) {
        case ToolResultPart(:final toolResult, :final overrideRole):
          final effectiveRole = overrideRole ?? message.role;
          if (effectiveRole != ChatRole.user) {
            throw const InvalidRequestError(
              'ToolResultPart must be emitted from a user message.',
            );
          }

          flushIfNotEmpty();

          out.add({
            'role': 'tool',
            'content': toolResult.function.arguments,
            'tool_name': toolResult.function.name,
          });
          break;

        case ToolCallPart(:final toolCall, :final overrideRole):
          final effectiveRole = overrideRole ?? message.role;
          if (effectiveRole != ChatRole.assistant) {
            throw const InvalidRequestError(
              'ToolCallPart must be emitted from an assistant message.',
            );
          }

          if (currentRole != ChatRole.assistant) {
            flushIfNotEmpty();
            currentRole = ChatRole.assistant;
          }

          dynamic args;
          try {
            args = jsonDecode(toolCall.function.arguments);
          } catch (e) {
            throw InvalidRequestError(
              'Invalid JSON tool call arguments for tool "${toolCall.function.name}": $e',
            );
          }

          toolCalls.add({
            'function': {
              'name': toolCall.function.name,
              'arguments': args,
            },
          });
          break;

        case TextPart(:final text):
          if (currentRole != message.role) {
            flushIfNotEmpty();
            currentRole = message.role;
          }
          contentSegments.add(text);
          break;

        case ImagePart(:final data, :final text):
          if (currentRole != message.role) {
            flushIfNotEmpty();
            currentRole = message.role;
          }
          if (text != null && text.isNotEmpty) {
            contentSegments.add(text);
          }
          images.add(base64Encode(data));
          break;

        case ImageUrlPart(:final url):
          throw InvalidRequestError(
            'ImageUrlPart is not supported by the Ollama Chat API. '
            'Download the image and send it as ImagePart (base64) instead. '
            'Got: "$url"',
          );

        case FilePart(:final mime):
          throw InvalidRequestError(
            'FilePart (${mime.mimeType}) is not supported by the Ollama Chat API.',
          );

        case FileUrlPart(:final mime, :final url):
          throw InvalidRequestError(
            'FileUrlPart (${mime.mimeType}) is not supported by the Ollama Chat API. '
            'Download the file and send it as FilePart (inline/base64) instead. '
            'Got: "$url"',
          );

        case FileIdPart(:final mime, :final id):
          throw InvalidRequestError(
            'FileIdPart (${mime.mimeType}) is not supported by the Ollama Chat API. '
            'Download the file and send it as FilePart (inline/base64) instead. '
            'Got id: "$id"',
          );
      }
    }

    flushIfNotEmpty();
    return out;
  }

  /// Convert Tool to Ollama format
  Map<String, dynamic> _convertTool(Tool tool) {
    // Convert properties to proper JSON format for Ollama
    final propertiesJson = <String, dynamic>{};
    for (final entry in tool.function.parameters.properties.entries) {
      propertiesJson[entry.key] = entry.value.toJson();
    }

    return {
      'type': 'function',
      'function': {
        'name': tool.function.name,
        'description': tool.function.description,
        'parameters': {
          'type': tool.function.parameters.schemaType,
          'properties': propertiesJson,
          'required': tool.function.parameters.required,
        },
      },
    };
  }
}

class _ToolCallAccum {
  final String name;
  final StringBuffer arguments = StringBuffer();

  _ToolCallAccum({required this.name});

  ToolCall toToolCall(String id) {
    return ToolCall(
      id: id,
      callType: 'function',
      function: FunctionCall(
        name: name,
        arguments: arguments.toString(),
      ),
    );
  }
}

Map<String, dynamic> _toOllamaToolCallJson(ToolCall toolCall) {
  dynamic args;
  try {
    args = jsonDecode(toolCall.function.arguments);
  } catch (_) {
    args = toolCall.function.arguments;
  }

  return {
    'function': {
      'name': toolCall.function.name,
      'arguments': args,
    },
  };
}

/// Ollama chat response implementation
class OllamaChatResponse implements ChatResponseWithFinishReason {
  final Map<String, dynamic> _rawResponse;

  OllamaChatResponse(this._rawResponse);

  @override
  String? get text {
    // Try different response formats
    final content = _rawResponse['content'] as String?;
    if (content != null && content.isNotEmpty) return content;

    final response = _rawResponse['response'] as String?;
    if (response != null && response.isNotEmpty) return response;

    final message = _rawResponse['message'] as Map<String, dynamic>?;
    if (message != null) {
      final messageContent = message['content'] as String?;
      if (messageContent != null && messageContent.isNotEmpty) {
        return messageContent;
      }
    }

    return null;
  }

  @override
  List<ToolCall>? get toolCalls {
    final message = _rawResponse['message'] as Map<String, dynamic>?;
    if (message == null) return null;

    final toolCalls = message['tool_calls'] as List?;
    if (toolCalls == null || toolCalls.isEmpty) return null;

    final functionCalls = <ToolCall>[];
    final nameCounts = <String, int>{};

    for (final tc in toolCalls) {
      final function = tc['function'] as Map<String, dynamic>;
      final name = function['name'] as String;
      final args = function['arguments'];

      final count = nameCounts[name] ?? 0;
      nameCounts[name] = count + 1;
      final id = count == 0 ? 'call_$name' : 'call_${name}_$count';

      functionCalls.add(
        ToolCall(
          id: id,
          callType: 'function',
          function: FunctionCall(
            name: name,
            arguments: args is String ? args : jsonEncode(args),
          ),
        ),
      );
    }

    return functionCalls;
  }

  @override
  UsageInfo? get usage {
    final promptEvalCount = _rawResponse['prompt_eval_count'];
    final evalCount = _rawResponse['eval_count'];
    if (promptEvalCount is! int || evalCount is! int) {
      return null;
    }
    return UsageInfo.fromProviderUsage({
      'prompt_eval_count': promptEvalCount,
      'eval_count': evalCount,
    });
  }

  @override
  LLMFinishReason? get finishReason {
    final calls = toolCalls;
    if (calls != null && calls.isNotEmpty) {
      return LLMFinishReason(
        unified: LLMUnifiedFinishReason.toolCalls,
        raw: _rawResponse['done_reason'] as String?,
      );
    }

    final raw = _rawResponse['done_reason'] as String?;
    if (raw == null || raw.trim().isEmpty) return null;

    final normalized = raw.trim().toLowerCase();
    final unified = switch (normalized) {
      'stop' => LLMUnifiedFinishReason.stop,
      'length' => LLMUnifiedFinishReason.length,
      'tool_calls' || 'tool-calls' => LLMUnifiedFinishReason.toolCalls,
      'content_filter' ||
      'content-filter' =>
        LLMUnifiedFinishReason.contentFilter,
      'error' => LLMUnifiedFinishReason.error,
      _ => LLMUnifiedFinishReason.other,
    };

    return LLMFinishReason(unified: unified, raw: raw);
  }

  @override
  String? get thinking {
    final message = _rawResponse['message'] as Map<String, dynamic>?;
    if (message != null) {
      final thinkingContent = message['thinking'] as String?;
      if (thinkingContent != null && thinkingContent.isNotEmpty) {
        return thinkingContent;
      }
    }

    final directThinking = _rawResponse['thinking'] as String?;
    if (directThinking != null && directThinking.isNotEmpty) {
      return directThinking;
    }

    return null;
  }

  @override
  Map<String, dynamic>? get providerMetadata {
    final model = _rawResponse['model'];
    final createdAt = _rawResponse['created_at'];
    final doneReason = _rawResponse['done_reason'];

    final totalDuration = _rawResponse['total_duration'];
    final loadDuration = _rawResponse['load_duration'];
    final promptEvalCount = _rawResponse['prompt_eval_count'];
    final promptEvalDuration = _rawResponse['prompt_eval_duration'];
    final evalCount = _rawResponse['eval_count'];
    final evalDuration = _rawResponse['eval_duration'];
    final context = _rawResponse['context'];

    if (model == null &&
        createdAt == null &&
        doneReason == null &&
        totalDuration == null &&
        loadDuration == null &&
        promptEvalCount == null &&
        promptEvalDuration == null &&
        evalCount == null &&
        evalDuration == null &&
        context == null) {
      return null;
    }

    final Map<String, dynamic>? usage;
    if (promptEvalCount is int && evalCount is int) {
      usage = {
        'promptTokens': promptEvalCount,
        'completionTokens': evalCount,
        'totalTokens': promptEvalCount + evalCount,
      };
    } else {
      usage = null;
    }

    final payload = {
      if (model != null) 'model': model,
      if (createdAt != null) 'createdAt': createdAt,
      if (doneReason != null) 'doneReason': doneReason,
      if (doneReason != null) 'finishReason': doneReason,
      if (usage != null) 'usage': usage,
      if (totalDuration != null) 'totalDuration': totalDuration,
      if (loadDuration != null) 'loadDuration': loadDuration,
      if (promptEvalCount != null) 'promptEvalCount': promptEvalCount,
      if (promptEvalDuration != null) 'promptEvalDuration': promptEvalDuration,
      if (evalCount != null) 'evalCount': evalCount,
      if (evalDuration != null) 'evalDuration': evalDuration,
      if (context != null) 'context': context,
    };

    return {
      'ollama': payload,
      'ollama.chat': payload,
    };
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
