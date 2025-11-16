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
    // TODO(ollama-native): migrate to native `/api/chat` endpoint when we drop
    // OpenAI-compatible gateways, and adjust the request/response format
    // accordingly.
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
    final promptMessages =
        messages.map((message) => message.toPromptMessage()).toList();

    final apiMessages = _buildOllamaMessagesFromPrompt(promptMessages);

    final body = <String, dynamic>{
      'model': config.model,
      'messages': apiMessages,
      'stream': stream,
    };

    // TODO(ollama-native): these top-level OpenAI-compatible sampling fields
    // are kept for backwards compatibility with chat/completions gateways.
    // Once we fully migrate to the native `/api/chat` endpoint, we should rely
    // on the `options` block instead and remove these.
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
    if (config.keepAlive != null) {
      options['keep_alive'] = config.keepAlive;
    }
    if (config.raw != null) {
      options['raw'] = config.raw;
    }
    if (options.isNotEmpty) {
      body['options'] = options;
    }

    // Thinking / reasoning flag for Ollama thinking models.
    if (config.reasoning == true) {
      body['think'] = true;
    }

    final effectiveTools = tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] = effectiveTools.map(_convertTool).toList();
    }

    // Structured output / JSON schema
    if (config.jsonSchema != null) {
      final schema = config.jsonSchema!;

      // TODO(ollama-native): response_format is OpenAI-style; keep while we
      // support OpenAI-compatible gateways, and prefer native `format` for
      // direct Ollama integrations.
      body['response_format'] = schema.toOpenAIResponseFormat();

      // Native Ollama-style format parameter for structured outputs.
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

    // System messages: Ollama has its own prompt field, but many servers
    // accept system in messages too; we keep only non-system messages here
    // and rely on config.systemPrompt for system behavior.
    for (final message in promptMessages) {
      if (message.role == ChatRole.system) continue;
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
        if (part is TextContentPart || part is ReasoningContentPart) {
          buffer.write((part as dynamic).text as String);
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

    final textParts =
        pureParts.whereType<TextContentPart>().toList(growable: false);
    final nonTextParts = pureParts.where((p) => p is! TextContentPart).toList();

    if (nonTextParts.isEmpty && textParts.length == 1) {
      return {
        'role': 'user',
        'content': textParts.first.text,
      };
    }

    final buffer = StringBuffer();
    for (final part in pureParts) {
      if (part is TextContentPart) {
        buffer.writeln(part.text);
      } else if (part is ReasoningContentPart) {
        buffer.writeln(part.text);
      } else if (part is UrlFileContentPart) {
        buffer.writeln('[image] ${part.url}');
      } else if (part is FileContentPart) {
        _appendFilePartForPrompt(part, buffer);
      }
    }

    return {
      'role': 'user',
      'content': buffer.toString().trim(),
    };
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
  UsageInfo? get usage {
    // Prefer OpenAI-style usage block when present (for compatible gateways).
    final rawUsage = _raw['usage'];
    if (rawUsage is Map) {
      final usageData = Map<String, dynamic>.from(rawUsage as Map);
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
  List<CallWarning> get warnings => const [];

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
