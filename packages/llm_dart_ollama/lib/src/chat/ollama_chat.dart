import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

import '../client/ollama_client.dart';
import '../config/ollama_config.dart';

class OllamaChat implements ChatCapability {
  final OllamaClient client;
  final OllamaConfig config;

  OllamaChat(this.client, this.config);

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) async {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    final body = _buildRequestBody(messages, tools, false);
    final response = await client.postJson('/v1/chat/completions', body,
        cancelToken: cancelToken);
    return _parseResponse(response);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    final body = _buildRequestBody(messages, tools, true);
    final stream = client.postStreamRaw('/v1/chat/completions', body,
        cancelToken: cancelToken);

    await for (final chunk in stream) {
      final lines = LineSplitter.split(chunk);
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final json = jsonDecode(line) as Map<String, dynamic>;
        final event = _parseStreamEvent(json);
        if (event != null) {
          yield event;
        }
      }
    }
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    final summaryPrompt =
        'Summarize in 2-3 sentences:\n${messages.map((m) => '${m.role.name}: ${m.content}').join('\n')}';
    final response = await chat([ChatMessage.user(summaryPrompt)]);
    return response.text ?? '';
  }

  Map<String, dynamic> _buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
  ) {
    final apiMessages = messages
        .where((m) => m.role != ChatRole.system)
        .map((m) => <String, dynamic>{
              'role': m.role.name,
              'content': m.content,
            })
        .toList();

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
    if (tools != null && tools.isNotEmpty) {
      body['tools'] = tools
          .map((t) => t.function.parameters.toJson()
            ..['name'] = t.function.name
            ..['description'] = t.function.description)
          .toList();
    }

    return body;
  }

  ChatStreamEvent? _parseStreamEvent(Map<String, dynamic> json) {
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) return null;

    final delta = choices.first['delta'] as Map<String, dynamic>?;
    if (delta == null) return null;

    final content = delta['content'] as String?;
    if (content != null && content.isNotEmpty) {
      return TextDeltaEvent(content);
    }

    return null;
  }

  ChatResponse _parseResponse(Map<String, dynamic> json) {
    return OllamaChatResponse(json);
  }
}

/// Ollama chat response implementation for the sub-package.
class OllamaChatResponse implements ChatResponse {
  final Map<String, dynamic> _raw;

  OllamaChatResponse(this._raw);

  @override
  String? get text {
    final content = _raw['content'] as String?;
    if (content != null && content.isNotEmpty) return content;

    final response = _raw['response'] as String?;
    if (response != null && response.isNotEmpty) return response;

    final message = _raw['message'] as Map<String, dynamic>?;
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
    final message = _raw['message'] as Map<String, dynamic>?;
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
  UsageInfo? get usage => null;

  @override
  String? get thinking {
    final message = _raw['message'] as Map<String, dynamic>?;
    if (message != null) {
      final thinkingContent = message['thinking'] as String?;
      if (thinkingContent != null && thinkingContent.isNotEmpty) {
        return thinkingContent;
      }
    }

    final directThinking = _raw['thinking'] as String?;
    if (directThinking != null && directThinking.isNotEmpty) {
      return directThinking;
    }

    return null;
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
