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
    final apiMessages = messages.map((m) {
      return {
        'role': m.role == ChatRole.user ? 'user' : 'assistant',
        'content': m.content,
      };
    }).toList();

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
      body['tools'] = effectiveTools
          .map((t) => t.function.parameters.toJson()
            ..['name'] = t.function.name
            ..['description'] = t.function.description)
          .toList();
    }

    if (config.searchParameters != null) {
      body['search'] = {
        if (config.searchParameters!.mode != null)
          'mode': config.searchParameters!.mode,
        if (config.searchParameters!.sources != null)
          'sources':
              config.searchParameters!.sources!.map((s) => s.toJson()).toList(),
        if (config.searchParameters!.maxSearchResults != null)
          'max_results': config.searchParameters!.maxSearchResults,
        if (config.searchParameters!.fromDate != null)
          'from': config.searchParameters!.fromDate,
        if (config.searchParameters!.toDate != null)
          'to': config.searchParameters!.toDate,
      };
    }

    return body;
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
    final content = delta['content'] as String?;
    if (content == null || content.isEmpty) return null;
    return TextDeltaEvent(content);
  }
}

class XAIChatResponse implements ChatResponse {
  final Map<String, dynamic> _rawResponse;

  XAIChatResponse(this._rawResponse);

  @override
  String? get text {
    final choices = _rawResponse['choices'] as List?;
    if (choices == null || choices.isEmpty) return null;
    final message = choices.first['message'] as Map<String, dynamic>?;
    return message?['content'] as String?;
  }

  @override
  List<ToolCall>? get toolCalls => null;

  @override
  UsageInfo? get usage => null;

  @override
  String? get thinking => null;

  @override
  List<CallWarning> get warnings => const [];

  @override
  Map<String, dynamic>? get metadata => null;
}
