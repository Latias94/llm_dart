import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/capability.dart';
import '../../core/llm_error.dart';
import '../../models/chat_models.dart';
import '../../models/tool_models.dart';
import 'client.dart';
import 'config.dart';

/// Ollama Chat capability implementation
///
/// This module handles all chat-related functionality for Ollama providers,
/// including streaming and tool calling. Ollama is designed for local deployment.
class OllamaChat implements ChatCapability {
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

      // Create JSON stream
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
    } catch (e) {
      yield ErrorEvent(GenericError('Unexpected error: $e'));
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
  List<ChatStreamEvent> _parseStreamEvents(String chunk) {
    final events = <ChatStreamEvent>[];
    final lines = chunk.split('\n');

    for (final line in lines) {
      if (line.trim().isNotEmpty) {
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          final event = _parseStreamEvent(json);
          if (event != null) {
            events.add(event);
          }
        } catch (e) {
          // Skip malformed JSON chunks
          client.logger
              .warning('Failed to parse stream JSON: $line, error: $e');
          continue;
        }
      }
    }

    return events;
  }

  /// Parse individual stream event
  ChatStreamEvent? _parseStreamEvent(Map<String, dynamic> json) {
    final message = json['message'] as Map<String, dynamic>?;
    if (message != null) {
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

    return toolCalls.map((tc) {
      final function = tc['function'] as Map<String, dynamic>;
      return ToolCall(
        id: 'call_${function['name']}',
        callType: 'function',
        function: FunctionCall(
          name: function['name'] as String,
          arguments: jsonEncode(function['arguments']),
        ),
      );
    }).toList();
  }

  @override
  UsageInfo? get usage => null; // Ollama doesn't provide usage info

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
