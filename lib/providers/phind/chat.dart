import 'package:dio/dio.dart';

import 'dart:convert';

import 'package:logging/logging.dart';

import '../../core/capability.dart';
import '../../core/llm_error.dart';
import '../../models/chat_models.dart';
import '../../models/tool_models.dart';
import 'client.dart';
import 'config.dart';

/// Phind Chat capability implementation
///
/// This module handles all chat-related functionality for Phind providers.
/// Phind is specialized for coding tasks and has a unique API format.
class PhindChat implements ChatCapability {
  final PhindClient client;
  final PhindConfig config;

  PhindChat(this.client, this.config);

  String get chatEndpoint => '';

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    try {
      // Note: Phind doesn't support tools yet
      final requestBody = _buildRequestBody(messages, tools, false);

      if (client.logger.isLoggable(Level.FINE)) {
        client.logger.fine('Phind request payload: ${jsonEncode(requestBody)}');
      }

      final responseData = await client.postJson(
        chatEndpoint,
        requestBody,
        cancelToken: cancelToken,
      );
      return _parseResponse(responseData);
    } catch (e) {
      if (e is LLMError) {
        rethrow;
      } else {
        throw GenericError('Unexpected error: $e');
      }
    }
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    try {
      final requestBody = _buildRequestBody(messages, tools, true);

      if (client.logger.isLoggable(Level.FINE)) {
        client.logger
            .fine('Phind stream request payload: ${jsonEncode(requestBody)}');
      }

      // Create SSE stream
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
      if (e is LLMError) {
        yield ErrorEvent(e);
      } else {
        yield ErrorEvent(GenericError('Unexpected error: $e'));
      }
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

  /// Parse response from Phind API
  PhindChatResponse _parseResponse(Map<String, dynamic> responseData) {
    // Extract content from the mock response structure created by client
    final choices = responseData['choices'] as List?;
    if (choices != null && choices.isNotEmpty) {
      final message = choices.first['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;
      if (content != null) {
        return PhindChatResponse.fromContent(content);
      }
    }
    return PhindChatResponse.fromContent('');
  }

  /// Parse stream events from SSE chunks
  List<ChatStreamEvent> _parseStreamEvents(String chunk) {
    final events = <ChatStreamEvent>[];
    final lines = chunk.split('\n');

    for (final line in lines) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6).trim();
        if (data == '[DONE]') {
          break;
        }

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final event = _parseStreamEvent(json);
          if (event != null) {
            events.add(event);
          }
        } catch (e) {
          // Skip malformed JSON chunks
          client.logger
              .warning('Failed to parse stream JSON: $data, error: $e');
          continue;
        }
      }
    }

    return events;
  }

  /// Parse individual stream event
  ChatStreamEvent? _parseStreamEvent(Map<String, dynamic> json) {
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) return null;

    final delta = choices.first['delta'] as Map<String, dynamic>?;
    if (delta == null) return null;

    final content = delta['content'] as String?;
    if (content != null) {
      return TextDeltaEvent(content);
    }

    return null;
  }

  /// Build request body for Phind API
  Map<String, dynamic> _buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
  ) {
    final messageHistory = <Map<String, dynamic>>[];

    // Convert messages to Phind format
    for (final message in messages) {
      final roleStr = message.role == ChatRole.user ? 'user' : 'assistant';
      messageHistory.add({'content': message.content, 'role': roleStr});
    }

    // Add system message if configured
    if (config.systemPrompt != null) {
      messageHistory.insert(0, {
        'content': config.systemPrompt,
        'role': 'system',
      });
    }

    // Find the last user message for user_input field
    final lastUserMessage =
        messages.where((m) => m.role == ChatRole.user).lastOrNull;

    return {
      'additional_extension_context': '',
      'allow_magic_buttons': true,
      'is_vscode_extension': true,
      'message_history': messageHistory,
      'requested_model': config.model,
      'user_input': lastUserMessage?.content ?? '',
    };
  }
}

/// Phind chat response implementation for parsed streaming responses
class PhindChatResponse implements ChatResponse {
  final String _content;

  PhindChatResponse.fromContent(this._content);

  @override
  String? get text => _content;

  @override
  List<ToolCall>? get toolCalls {
    // Phind doesn't support tool calls
    return null;
  }

  @override
  UsageInfo? get usage {
    // Phind doesn't provide usage info
    return null;
  }

  @override
  String? get thinking =>
      null; // Phind doesn't support thinking/reasoning content

  @override
  String toString() => _content;
}
