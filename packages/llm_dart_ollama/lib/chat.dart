import 'dart:convert';

import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/cancellation.dart';
import 'package:llm_dart_core/core/stream_parts.dart';
import 'package:llm_dart_core/core/llm_error.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'client.dart';
import 'config.dart';

/// Ollama Chat capability implementation
///
/// This module handles all chat-related functionality for Ollama providers,
/// including streaming and tool calling. Ollama is designed for local deployment.
class OllamaChat implements ChatCapability, ChatStreamPartsCapability {
  final OllamaClient client;
  final OllamaConfig config;

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
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    if (config.baseUrl.isEmpty) {
      yield ErrorEvent(const InvalidRequestError('Missing Ollama base URL'));
      return;
    }

    try {
      final effectiveTools = tools ?? config.tools;
      final requestBody = _buildRequestBody(messages, effectiveTools, true);
      final jsonlParser = JsonlChunkParser();

      // Create JSON stream
      final stream = client.postStreamRaw(
        chatEndpoint,
        requestBody,
        cancelToken: cancelToken,
      );

      await for (final chunk in stream) {
        final events = _parseStreamEvents(chunk, jsonlParser);
        for (final event in events) {
          yield event;
        }
      }
    } catch (e) {
      yield ErrorEvent(GenericError('Unexpected error: $e'));
    }
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

    final effectiveTools = tools ?? config.tools;
    final requestBody = _buildRequestBody(messages, effectiveTools, true);
    final jsonlParser = JsonlChunkParser();

    var inText = false;
    var inThinking = false;

    final fullText = StringBuffer();
    final fullThinking = StringBuffer();

    final startedToolCalls = <String>{};
    final endedToolCalls = <String>{};
    final toolAccums = <String, _ToolCallAccum>{};

    String nextToolCallId(String name, int index) {
      if (index == 0) return 'call_$name';
      return 'call_${name}_$index';
    }

    try {
      final stream = client.postStreamRaw(
        chatEndpoint,
        requestBody,
        cancelToken: cancelToken,
      );

      await for (final chunk in stream) {
        for (final json in jsonlParser.parseObjects(chunk)) {
          final message = json['message'] as Map<String, dynamic>?;
          if (message != null) {
            final thinking = message['thinking'] as String?;
            if (thinking != null && thinking.isNotEmpty) {
              if (!inThinking) {
                inThinking = true;
                yield const LLMReasoningStartPart();
              }
              fullThinking.write(thinking);
              yield LLMReasoningDeltaPart(thinking);
            }

            final content = message['content'] as String?;
            if (content != null && content.isNotEmpty) {
              if (!inText) {
                inText = true;
                yield const LLMTextStartPart();
              }
              fullText.write(content);
              yield LLMTextDeltaPart(content);
            }

            final toolCalls = message['tool_calls'] as List?;
            if (toolCalls != null && toolCalls.isNotEmpty) {
              var i = 0;
              for (final rawCall in toolCalls) {
                if (rawCall is! Map<String, dynamic>) {
                  i++;
                  continue;
                }

                final function =
                    rawCall['function'] as Map<String, dynamic>? ?? {};
                final name = function['name'] as String? ?? '';
                final args = function['arguments'];
                if (name.isEmpty) {
                  i++;
                  continue;
                }

                final id = nextToolCallId(name, i);
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

                i++;
              }
            }
          }

          final done = json['done'] as bool?;
          if (done == true) {
            if (inText) {
              yield LLMTextEndPart(fullText.toString());
            }
            if (inThinking) {
              yield LLMReasoningEndPart(fullThinking.toString());
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
            yield LLMFinishPart(response);
            return;
          }
        }
      }

      // Best-effort finish if stream ends unexpectedly.
      if (inText) {
        yield LLMTextEndPart(fullText.toString());
      }
      if (inThinking) {
        yield LLMReasoningEndPart(fullThinking.toString());
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
      yield LLMFinishPart(response);
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

  /// Parse stream events from JSON chunks
  List<ChatStreamEvent> _parseStreamEvents(
    String chunk,
    JsonlChunkParser jsonlParser,
  ) {
    final events = <ChatStreamEvent>[];
    for (final json in jsonlParser.parseObjects(chunk)) {
      final event = _parseStreamEvent(json);
      if (event != null) {
        events.add(event);
      }
    }

    return events;
  }

  /// Parse individual stream event
  ChatStreamEvent? _parseStreamEvent(Map<String, dynamic> json) {
    final message = json['message'] as Map<String, dynamic>?;
    if (message != null) {
      final toolCalls = message['tool_calls'] as List?;
      if (toolCalls != null && toolCalls.isNotEmpty) {
        try {
          final tc = toolCalls.first;
          if (tc is Map<String, dynamic>) {
            final function = tc['function'] as Map<String, dynamic>?;
            final name = function?['name'] as String?;
            if (name != null && name.isNotEmpty) {
              return ToolCallDeltaEvent(
                ToolCall(
                  id: 'call_$name',
                  callType: 'function',
                  function: FunctionCall(
                    name: name,
                    arguments: jsonEncode(function?['arguments']),
                  ),
                ),
              );
            }
          }
        } catch (_) {
          // Ignore malformed tool calls in the legacy stream surface.
        }
      }

      // Check for thinking content in stream
      final thinking = message['thinking'] as String?;
      if (thinking != null && thinking.isNotEmpty) {
        return ThinkingDeltaEvent(thinking);
      }

      final content = message['content'] as String?;
      if (content != null && content.isNotEmpty) {
        return TextDeltaEvent(content);
      }
    }

    // Check if this is the final message
    final done = json['done'] as bool?;
    if (done == true) {
      final response = OllamaChatResponse(json);
      return CompletionEvent(response);
    }

    return null;
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
      chatMessages.add(_convertMessage(message));
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

  /// Convert ChatMessage to Ollama format
  Map<String, dynamic> _convertMessage(ChatMessage message) {
    final result = <String, dynamic>{
      'role': message.role.name,
    };

    // Add name field if present
    if (message.name != null) {
      result['name'] = message.name;
    }

    // Handle different message types
    switch (message.messageType) {
      case TextMessage():
        result['content'] = message.content;
        break;
      case ImageMessage(mime: final _, data: final data):
        // Convert image data to base64 for Ollama
        final base64Image = base64Encode(data);
        result['content'] = message.content;
        result['images'] = [base64Image];
        break;
      case ImageUrlMessage(url: final url):
        // Ollama doesn't support image URLs directly, would need to download
        result['content'] = message.content;
        client.logger
            .warning('Image URLs not directly supported by Ollama: $url');
        break;
      case ToolUseMessage(toolCalls: final toolCalls):
        result['content'] = message.content;
        result['tool_calls'] = toolCalls
            .map((tc) => {
                  'function': {
                    'name': tc.function.name,
                    'arguments': jsonDecode(tc.function.arguments),
                  }
                })
            .toList();
        break;
      case ToolResultMessage():
        // Tool results are handled as separate messages in Ollama
        result['content'] = message.content;
        break;
      default:
        result['content'] = message.content;
    }

    return result;
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
class OllamaChatResponse implements ChatResponse {
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
    return UsageInfo(
      promptTokens: promptEvalCount,
      completionTokens: evalCount,
      totalTokens: promptEvalCount + evalCount,
      reasoningTokens: null,
    );
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

    return {
      'ollama': {
        if (model != null) 'model': model,
        if (createdAt != null) 'createdAt': createdAt,
        if (doneReason != null) 'doneReason': doneReason,
        if (doneReason != null) 'finishReason': doneReason,
        if (usage != null) 'usage': usage,
        if (totalDuration != null) 'totalDuration': totalDuration,
        if (loadDuration != null) 'loadDuration': loadDuration,
        if (promptEvalCount != null) 'promptEvalCount': promptEvalCount,
        if (promptEvalDuration != null)
          'promptEvalDuration': promptEvalDuration,
        if (evalCount != null) 'evalCount': evalCount,
        if (evalDuration != null) 'evalDuration': evalDuration,
        if (context != null) 'context': context,
      },
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
