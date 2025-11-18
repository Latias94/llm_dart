import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

import '../client/xai_client.dart';
import '../config/xai_config.dart';

class XAIChat implements ChatCapability {
  final XAIClient client;
  final XAIConfig config;

  XAIChat(this.client, this.config);

  String get chatEndpoint => 'chat/completions';

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing xAI API key');
    }

    final body = _buildRequestBody(messages, tools, false);
    final response =
        await client.postJson(chatEndpoint, body, cancelToken: cancelToken);
    return XAIChatResponse(response);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    if (config.apiKey.isEmpty) {
      yield ErrorEvent(const AuthError('Missing xAI API key'));
      return;
    }

    try {
      final effectiveTools = tools ?? config.tools;
      final body = _buildRequestBody(messages, effectiveTools, true);

      final stream =
          client.postStreamRaw(chatEndpoint, body, cancelToken: cancelToken);

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
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    final prompt =
        'Summarize in 2-3 sentences:\n${messages.map((m) => '${m.role.name}: ${m.content}').join('\n')}';
    final response = await chat([ChatMessage.user(prompt)]);
    final text = response.text;
    if (text == null) {
      throw const GenericError('no text in summary response');
    }
    return text;
  }

  Map<String, dynamic> _buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
  ) {
    final promptMessages =
        messages.map((message) => message.toPromptMessage()).toList();

    final apiMessages = _buildXaiMessagesFromPrompt(promptMessages);

    // Prefer explicit system messages over config.systemPrompt
    final hasSystemMessage =
        promptMessages.any((m) => m.role == ChatRole.system);

    if (!hasSystemMessage && config.systemPrompt != null) {
      apiMessages.insert(0, {
        'role': 'system',
        'content': config.systemPrompt,
      });
    }

    final body = <String, dynamic>{
      'model': config.model,
      'messages': apiMessages,
      'stream': stream,
    };

    if (config.temperature != null) {
      body['temperature'] = config.temperature;
    }
    if (config.maxTokens != null) {
      body['max_tokens'] = config.maxTokens;
    }
    if (config.topP != null) {
      body['top_p'] = config.topP;
    }
    if (config.topK != null) {
      body['top_k'] = config.topK;
    }

    final effectiveTools = tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] = effectiveTools.map(_convertTool).toList();

      final effectiveToolChoice = config.toolChoice;
      if (effectiveToolChoice != null) {
        body['tool_choice'] = effectiveToolChoice.toJson();
      }
    }

    if (config.searchParameters != null) {
      // Align with xAI API: search_parameters
      body['search_parameters'] = config.searchParameters!.toJson();
    }

    // Structured output / JSON schema support
    if (config.jsonSchema != null) {
      body['response_format'] = config.jsonSchema!.toOpenAIResponseFormat();
    }

    return body;
  }

  /// Build XAI chat messages from the structured ChatPromptMessage model.
  List<Map<String, dynamic>> _buildXaiMessagesFromPrompt(
    List<ChatPromptMessage> promptMessages,
  ) {
    final apiMessages = <Map<String, dynamic>>[];

    for (final message in promptMessages) {
      final hasToolResult =
          message.parts.any((part) => part is ToolResultContentPart);

      if (hasToolResult) {
        _appendToolResultMessagesFromPrompt(message, apiMessages);
      } else {
        apiMessages.add(_convertPromptMessage(message));
      }
    }

    return apiMessages;
  }

  Map<String, dynamic> _convertPromptMessage(ChatPromptMessage message) {
    final role = switch (message.role) {
      ChatRole.system => 'system',
      ChatRole.user => 'user',
      ChatRole.assistant => 'assistant',
    };

    // System messages: concatenate text and reasoning content.
    if (role == 'system') {
      final buffer = StringBuffer();
      for (final part in message.parts) {
        if (part is TextContentPart) {
          if (buffer.isNotEmpty) buffer.writeln();
          buffer.write(part.text);
        } else if (part is ReasoningContentPart) {
          if (buffer.isNotEmpty) buffer.writeln();
          buffer.write(part.text);
        }
      }

      return {
        'role': 'system',
        'content': buffer.isNotEmpty ? buffer.toString() : '',
      };
    }

    // Assistant messages with optional tool calls.
    if (role == 'assistant') {
      final buffer = StringBuffer();
      final toolCalls = <Map<String, dynamic>>[];

      for (final part in message.parts) {
        if (part is TextContentPart) {
          buffer.write(part.text);
        } else if (part is ReasoningContentPart) {
          buffer.write(part.text);
        } else if (part is ToolCallContentPart) {
          toolCalls.add({
            'id': part.toolCallId ?? 'call_${toolCalls.length}',
            'type': 'function',
            'function': {
              'name': part.toolName,
              'arguments': part.argumentsJson,
            },
          });
        }
      }

      final result = <String, dynamic>{
        'role': 'assistant',
        'content': buffer.toString(),
      };

      if (toolCalls.isNotEmpty) {
        result['tool_calls'] = toolCalls;
      }

      return result;
    }

    // User messages: support pure text and multi-modal (text + images).
    if (role == 'user') {
      final pureParts = message.parts
          .where((part) => part is! ToolResultContentPart)
          .toList();
      final textParts =
          pureParts.whereType<TextContentPart>().toList(growable: false);
      final nonTextParts =
          pureParts.where((p) => p is! TextContentPart).toList();

      // Pure text message
      if (nonTextParts.isEmpty && textParts.length == 1) {
        return {
          'role': 'user',
          'content': textParts.first.text,
        };
      }

      // Multi-part or multi-modal message
      final contentArray = <Map<String, dynamic>>[];

      for (final part in pureParts) {
        if (part is TextContentPart) {
          if (part.text.isEmpty) continue;
          contentArray.add({'type': 'text', 'text': part.text});
        } else if (part is ReasoningContentPart) {
          if (part.text.isEmpty) continue;
          contentArray.add({'type': 'text', 'text': part.text});
        } else if (part is UrlFileContentPart) {
          contentArray.add({
            'type': 'image_url',
            'image_url': {'url': part.url},
          });
        } else if (part is FileContentPart) {
          _appendFilePartForPrompt(part, contentArray);
        }
      }

      return {
        'role': 'user',
        'content': contentArray,
      };
    }

    // Fallback (should not reach here)
    return {
      'role': role,
      'content': '',
    };
  }

  void _appendFilePartForPrompt(
    FileContentPart part,
    List<Map<String, dynamic>> contentArray,
  ) {
    final mime = part.mime;
    final data = part.data;

    if (mime.mimeType.startsWith('image/')) {
      final base64Data = base64Encode(data);
      final imageDataUrl = 'data:${mime.mimeType};base64,$base64Data';

      contentArray.add({
        'type': 'image_url',
        'image_url': {'url': imageDataUrl},
      });
    } else {
      // For non-image files, fall back to a textual notice to avoid errors.
      contentArray.add({
        'type': 'text',
        'text':
            '[Unsupported file type for xAI: ${mime.mimeType}. Only image/* is supported as image_url.]',
      });
    }
  }

  void _appendToolResultMessagesFromPrompt(
    ChatPromptMessage message,
    List<Map<String, dynamic>> apiMessages,
  ) {
    final fallbackText = message.parts
        .whereType<TextContentPart>()
        .map((p) => p.text)
        .join('\n');

    for (final part in message.parts) {
      if (part is! ToolResultContentPart) continue;

      String content;
      final payload = part.payload;
      if (payload is ToolResultTextPayload) {
        content = payload.value.isNotEmpty ? payload.value : fallbackText;
      } else if (payload is ToolResultJsonPayload) {
        content = jsonEncode(payload.value);
      } else if (payload is ToolResultErrorPayload) {
        content = payload.message;
      } else if (payload is ToolResultContentPayload) {
        final texts = <String>[];
        for (final nested in payload.parts) {
          if (nested is TextContentPart) {
            texts.add(nested.text);
          }
        }
        content = texts.join('\n');
      } else {
        content = fallbackText.isNotEmpty ? fallbackText : 'Tool result';
      }

      apiMessages.add({
        'role': 'tool',
        'tool_call_id': part.toolCallId,
        'content': content,
      });
    }
  }

  Map<String, dynamic> _convertTool(Tool tool) {
    return {
      'type': 'function',
      'function': {
        'name': tool.function.name,
        'description': tool.function.description.isNotEmpty
            ? tool.function.description
            : null,
        'parameters': tool.function.parameters.toJson(),
      },
    };
  }

  List<ChatStreamEvent> _parseStreamEvents(String chunk) {
    final events = <ChatStreamEvent>[];
    final lines = chunk.split('\n');

    for (final line in lines) {
      if (!line.startsWith('data: ')) continue;
      final data = line.substring(6).trim();
      if (data == '[DONE]') break;

      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        final event = _parseStreamEvent(json);
        if (event != null) {
          events.add(event);
        }
      } catch (_) {
        continue;
      }
    }

    return events;
  }

  ChatStreamEvent? _parseStreamEvent(Map<String, dynamic> json) {
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) return null;
    final delta = choices.first['delta'] as Map<String, dynamic>?;
    if (delta == null) return null;

    // Reasoning content (chain-of-thought style)
    final reasoningContent = delta['reasoning_content'] as String?;
    if (reasoningContent != null && reasoningContent.isNotEmpty) {
      return ThinkingDeltaEvent(reasoningContent);
    }

    // Regular text content
    final content = delta['content'] as String?;
    if (content != null && content.isNotEmpty) {
      return TextDeltaEvent(content);
    }

    // Tool calls
    final toolCalls = delta['tool_calls'] as List?;
    if (toolCalls != null && toolCalls.isNotEmpty) {
      final toolCall = toolCalls.first as Map<String, dynamic>;
      final function = toolCall['function'] as Map<String, dynamic>? ?? {};
      final name = function['name'] as String?;
      final arguments = function['arguments'] as String? ?? '';

      if (name != null && name.isNotEmpty) {
        return ToolCallDeltaEvent(
          ToolCall(
            id: toolCall['id'] as String? ?? 'call_${name}',
            callType: toolCall['type'] as String? ?? 'function',
            function: FunctionCall(
              name: name,
              arguments: arguments,
            ),
          ),
        );
      }
    }

    return null;
  }
}

class XAIChatResponse implements ChatResponse {
  final Map<String, dynamic> _rawResponse;

  XAIChatResponse(this._rawResponse);

  @override
  String? get text {
    final choices = _rawResponse['choices'] as List?;
    if (choices == null || choices.isEmpty) return null;

    final choice = choices.first as Map<String, dynamic>?;
    final message = choice?['message'] as Map<String, dynamic>?;
    return message?['content'] as String?;
  }

  @override
  String? get thinking {
    final choices = _rawResponse['choices'] as List?;
    if (choices == null || choices.isEmpty) return null;

    final choice = choices.first as Map<String, dynamic>?;
    final message = choice?['message'] as Map<String, dynamic>?;
    final reasoning = message?['reasoning_content'] as String?;

    return (reasoning != null && reasoning.isNotEmpty) ? reasoning : null;
  }

  @override
  List<ToolCall>? get toolCalls {
    final choices = _rawResponse['choices'] as List?;
    if (choices == null || choices.isEmpty) return null;

    final choice = choices.first as Map<String, dynamic>?;
    final message = choice?['message'] as Map<String, dynamic>?;
    final rawToolCalls = message?['tool_calls'] as List?;
    if (rawToolCalls == null || rawToolCalls.isEmpty) return null;

    final result = <ToolCall>[];
    for (final raw in rawToolCalls) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw as Map);
      final function = map['function'] as Map<String, dynamic>? ?? {};
      final name = function['name'] as String?;
      final arguments = function['arguments'] as String? ?? '';
      if (name == null || name.isEmpty) continue;

      result.add(
        ToolCall(
          id: map['id'] as String? ?? 'call_$name',
          callType: map['type'] as String? ?? 'function',
          function: FunctionCall(name: name, arguments: arguments),
        ),
      );
    }

    return result.isEmpty ? null : result;
  }

  @override
  UsageInfo? get usage {
    final rawUsage = _rawResponse['usage'];
    if (rawUsage == null) return null;

    final Map<String, dynamic> usageData;
    if (rawUsage is Map<String, dynamic>) {
      usageData = rawUsage;
    } else if (rawUsage is Map) {
      usageData = Map<String, dynamic>.from(rawUsage);
    } else {
      return null;
    }

    final promptTokens = usageData['prompt_tokens'] as int?;
    final completionTokens = usageData['completion_tokens'] as int?;
    final totalTokens = usageData['total_tokens'] as int?;

    int? reasoningTokens;
    final completionDetails =
        usageData['completion_tokens_details'] as Map<String, dynamic>?;
    if (completionDetails != null) {
      reasoningTokens = completionDetails['reasoning_tokens'] as int?;
    }

    return UsageInfo(
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: totalTokens,
      reasoningTokens: reasoningTokens,
    );
  }

  @override
  List<CallWarning> get warnings => const [];

  @override
  Map<String, dynamic>? get metadata {
    final id = _rawResponse['id'] as String?;
    final model = _rawResponse['model'] as String?;
    final citations = _rawResponse['citations'] as List?;

    final hasThinkingContent = thinking != null;
    final hasCitations =
        citations != null && citations is List && citations.isNotEmpty;

    return {
      'provider': 'xai',
      if (id != null) 'id': id,
      if (model != null) 'model': model,
      'hasThinking': hasThinkingContent,
      'hasCitations': hasCitations,
      if (hasCitations) 'citations': citations,
    };
  }

  @override
  CallMetadata? get callMetadata {
    final data = metadata;
    if (data == null) return null;
    return CallMetadata.fromJson(data);
  }
}
