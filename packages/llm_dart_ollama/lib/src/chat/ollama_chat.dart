import 'dart:convert';

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
    final response =
        await client.postJson('/api/chat', body, cancelToken: cancelToken);
    return _parseResponse(response);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    final body = _buildRequestBody(messages, tools, true);
    final stream =
        client.postStreamRaw('/api/chat', body, cancelToken: cancelToken);

    // Ollama streams NDJSON (one JSON object per line). We need to
    // buffer across chunks to avoid splitting JSON lines.
    final buffer = StringBuffer();

    await for (final chunk in stream) {
      buffer.write(chunk);
      var content = buffer.toString();

      while (true) {
        final newlineIndex = content.indexOf('\n');
        if (newlineIndex == -1) {
          break;
        }

        final line = content.substring(0, newlineIndex).trim();
        content = content.substring(newlineIndex + 1);

        if (line.isEmpty) {
          continue;
        }

        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          final events = _parseStreamEvents(json);
          for (final event in events) {
            yield event;
          }
        } catch (_) {
          // Ignore malformed lines and continue streaming.
        }
      }

      buffer
        ..clear()
        ..write(content);
    }

    final remaining = buffer.toString().trim();
    if (remaining.isNotEmpty) {
      try {
        final json = jsonDecode(remaining) as Map<String, dynamic>;
        final events = _parseStreamEvents(json);
        for (final event in events) {
          yield event;
        }
      } catch (_) {
        // Ignore trailing partial JSON.
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
    final promptMessages = messages
        .map((message) => message.toPromptMessage())
        .toList(growable: false);

    final apiMessages = _buildOllamaMessagesFromPrompt(promptMessages);

    final body = <String, dynamic>{
      'model': config.model,
      'messages': apiMessages,
      'stream': stream,
    };

    // Ollama-style options block for advanced parameters.
    final options = <String, dynamic>{};
    if (config.temperature != null) {
      options['temperature'] = config.temperature;
    }
    if (config.maxTokens != null) {
      // Map maxTokens to num_predict for native Ollama.
      options['num_predict'] = config.maxTokens;
    }
    if (config.topP != null) {
      options['top_p'] = config.topP;
    }
    if (config.topK != null) {
      options['top_k'] = config.topK;
    }
    if (config.numCtx != null) {
      options['num_ctx'] = config.numCtx;
    }
    if (config.numGpu != null) {
      options['num_gpu'] = config.numGpu;
    }
    if (config.numThread != null) {
      options['num_thread'] = config.numThread;
    }
    if (config.numBatch != null) {
      options['num_batch'] = config.numBatch;
    }
    if (config.numa != null) {
      options['numa'] = config.numa;
    }
    if (options.isNotEmpty) {
      body['options'] = options;
    }

    // Top-level advanced parameters aligned with Ollama docs.
    if (config.keepAlive != null) {
      body['keep_alive'] = config.keepAlive;
    }
    if (config.raw != null) {
      body['raw'] = config.raw;
    }

    // Thinking / reasoning flag for Ollama thinking models.
    if (config.reasoning == true) {
      body['think'] = true;
    }

    final effectiveTools = tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] = effectiveTools.map(_convertTool).toList();
    }

    // Structured output / JSON schema using native `format` parameter.
    if (config.jsonSchema != null) {
      final schema = config.jsonSchema!;

      if (schema.schema != null) {
        body['format'] = schema.schema;
      } else {
        body['format'] = 'json';
      }
    }

    return body;
  }

  /// Build Ollama-style chat messages from structured prompt messages.
  List<Map<String, dynamic>> _buildOllamaMessagesFromPrompt(
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

    if (role == 'assistant') {
      final buffer = StringBuffer();

      for (final part in message.parts) {
        if (part is TextContentPart) {
          buffer.write(part.text);
        } else if (part is ReasoningContentPart) {
          buffer.write(part.text);
        }
      }

      return {
        'role': 'assistant',
        'content': buffer.toString(),
      };
    }

    // user
    final pureParts =
        message.parts.where((part) => part is! ToolResultContentPart).toList();

    final buffer = StringBuffer();
    final images = <String>[];

    for (final part in pureParts) {
      if (part is TextContentPart) {
        buffer.writeln(part.text);
      } else if (part is ReasoningContentPart) {
        buffer.writeln(part.text);
      } else if (part is UrlFileContentPart) {
        // For URL-based media we currently fall back to a textual
        // placeholder. Native Ollama images require base64-encoded
        // image data, which is available only for FileContentPart.
        buffer.writeln('[image] ${part.url}');
      } else if (part is FileContentPart) {
        final mime = part.mime.mimeType;
        if (mime.startsWith('image/')) {
          // Encode inline image bytes for native Ollama multimodal support.
          final base64Data = base64Encode(part.data);
          images.add(base64Data);
        } else {
          _appendFilePartForPrompt(part, buffer);
        }
      }
    }

    final result = <String, dynamic>{
      'role': 'user',
      'content': buffer.toString().trim(),
    };

    if (images.isNotEmpty) {
      result['images'] = images;
    }

    return result;
  }

  void _appendFilePartForPrompt(
    FileContentPart part,
    StringBuffer buffer,
  ) {
    final mime = part.mime;
    if (mime.mimeType.startsWith('image/')) {
      buffer.writeln('[inline image ${mime.mimeType}]');
    } else {
      buffer.writeln('[file ${mime.mimeType}]');
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
        // For native Ollama, tool_name informs the model about which tool
        // produced this output. We still embed the full content so that
        // OpenAI-compatible gateways can forward it unchanged.
        'tool_name': part.toolName,
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

  /// Parse a single Ollama chat stream JSON object into zero or more
  /// [ChatStreamEvent]s.
  List<ChatStreamEvent> _parseStreamEvents(Map<String, dynamic> json) {
    final events = <ChatStreamEvent>[];

    final done = json['done'] as bool? ?? false;
    final message = json['message'] as Map<String, dynamic>?;

    if (message != null) {
      // Thinking content for reasoning models.
      final thinking = message['thinking'] as String?;
      if (thinking != null && thinking.isNotEmpty) {
        events.add(ThinkingDeltaEvent(thinking));
      }

      // Tool call deltas.
      final toolCalls = message['tool_calls'] as List?;
      if (toolCalls != null && toolCalls.isNotEmpty) {
        for (final tc in toolCalls.whereType<Map<String, dynamic>>()) {
          final function = tc['function'] as Map<String, dynamic>?;
          if (function == null) continue;

          final name = function['name'] as String?;
          final arguments = function['arguments'];

          if (name == null || arguments == null) continue;

          events.add(
            ToolCallDeltaEvent(
              ToolCall(
                id: 'call_$name',
                callType: 'function',
                function: FunctionCall(
                  name: name,
                  arguments: jsonEncode(arguments),
                ),
              ),
            ),
          );
        }
      }

      // Text deltas.
      final content = message['content'] as String?;
      if (content != null && content.isNotEmpty) {
        events.add(TextDeltaEvent(content));
      }
    }

    // Final completion event with usage/metadata.
    if (done) {
      events.add(CompletionEvent(OllamaChatResponse(json)));
    }

    return events;
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
  UsageInfo? get usage {
    // Prefer OpenAI-style usage block when present (for compatible gateways).
    final rawUsage = _raw['usage'];
    if (rawUsage is Map) {
      final usageData = Map<String, dynamic>.from(rawUsage);
      return UsageInfo.fromJson(usageData);
    }

    // Fallback to native Ollama-style top-level metrics.
    final promptTokens =
        (_raw['prompt_eval_count'] as int?) ?? _raw['prompt_tokens'] as int?;
    final completionTokens =
        (_raw['eval_count'] as int?) ?? _raw['completion_tokens'] as int?;
    int? totalTokens = _raw['total_tokens'] as int?;
    if (totalTokens == null &&
        promptTokens != null &&
        completionTokens != null) {
      totalTokens = promptTokens + completionTokens;
    }

    if (promptTokens == null &&
        completionTokens == null &&
        totalTokens == null) {
      return null;
    }

    return UsageInfo(
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: totalTokens,
      reasoningTokens: null,
    );
  }

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
  List<CallWarning> get warnings {
    final warnings = <CallWarning>[];

    // Surface a warning when the response was truncated by length/num_predict.
    final doneReason = _raw['done_reason'] as String?;
    if (doneReason == 'length') {
      warnings.add(
        CallWarning(
          code: 'output_truncated',
          message:
              'Ollama response was truncated due to max token or length limit.',
          details: {
            'provider': 'ollama',
            'doneReason': doneReason,
            'numPredict': _raw['num_predict'],
            'evalCount': _raw['eval_count'],
          },
        ),
      );
    }

    return warnings;
  }

  @override
  Map<String, dynamic>? get metadata {
    final model = _raw['model'] as String?;
    final doneReason = _raw['done_reason'] as String?;
    final context = _raw['context'];
    final totalDuration = _raw['total_duration'] as int?;
    final loadDuration = _raw['load_duration'] as int?;
    final promptEvalCount = _raw['prompt_eval_count'] as int?;
    final evalCount = _raw['eval_count'] as int?;

    final hasContext = context != null;

    return {
      'provider': 'ollama',
      if (model != null) 'model': model,
      if (doneReason != null) 'doneReason': doneReason,
      'hasContext': hasContext,
      if (totalDuration != null) 'totalDuration': totalDuration,
      if (loadDuration != null) 'loadDuration': loadDuration,
      if (promptEvalCount != null) 'promptEvalCount': promptEvalCount,
      if (evalCount != null) 'evalCount': evalCount,
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
