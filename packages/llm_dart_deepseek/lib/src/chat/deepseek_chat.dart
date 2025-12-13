// DeepSeek chat capability implementation (prompt-first).

import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../client/deepseek_client.dart';
import '../config/deepseek_config.dart';

/// DeepSeek Chat capability implementation.
///
/// This module handles all chat-related functionality for DeepSeek providers,
/// including streaming, tool calling, and reasoning model support.
class DeepSeekChat implements ChatCapability {
  final DeepSeekClient client;
  final DeepSeekConfig config;

  bool _hasReasoningContent = false;
  String _lastChunk = '';
  final StringBuffer _thinkingBuffer = StringBuffer();
  // Track tool call streaming state for DeepSeek.
  // DeepSeek streams tool_calls in an OpenAI-compatible way: the first chunk
  // usually carries id + index, while subsequent chunks only contain index and
  // incremental arguments. We delegate index → id mapping to
  // [ToolCallStreamState].
  final ToolCallStreamState _toolCallStreamState = ToolCallStreamState();

  DeepSeekChat(this.client, this.config);

  String get chatEndpoint => 'chat/completions';

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    final warnings = <CallWarning>[];
    final requestBody = _buildRequestBody(
      messages,
      tools,
      true,
      options,
      warnings,
    );

    _resetStreamState();

    final stream = client.postStreamRaw(
      chatEndpoint,
      requestBody,
      cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
    );

    await for (final chunk in stream) {
      final events = _parseStreamEvents(chunk, warnings);
      for (final event in events) {
        yield event;
      }
    }
  }

  @override
  Future<ChatResponse> chat(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    final warnings = <CallWarning>[];
    final requestBody = _buildRequestBody(
      messages,
      tools,
      false,
      options,
      warnings,
    );
    final responseData = await client.postJson(
      chatEndpoint,
      requestBody,
      cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
    );
    return _parseResponse(responseData, warnings);
  }

  void _resetStreamState() {
    _hasReasoningContent = false;
    _lastChunk = '';
    _thinkingBuffer.clear();
    _toolCallStreamState.reset();
  }

  DeepSeekChatResponse _parseResponse(
    Map<String, dynamic> responseData,
    List<CallWarning> warnings,
  ) {
    String? thinkingContent;
    bool hasThinking = false;

    final choices = responseData['choices'] as List?;
    if (choices != null && choices.isNotEmpty) {
      final message = choices.first['message'] as Map<String, dynamic>?;
      if (message != null) {
        thinkingContent = message['reasoning_content'] as String?;
      }
    }

    if (thinkingContent != null && thinkingContent.trim().isNotEmpty) {
      hasThinking = true;
    }

    return DeepSeekChatResponse(
      responseData,
      thinkingContent,
      warnings,
      {
        'provider': 'deepseek',
        'model': config.model,
        'reasonerModel': config.supportsReasoning,
        'hasThinking': hasThinking,
      },
    );
  }

  List<ChatStreamEvent> _parseStreamEvents(
    String chunk,
    List<CallWarning> warnings,
  ) {
    final events = <ChatStreamEvent>[];
    final lines = chunk.split('\n');

    for (final line in lines) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6).trim();

        if (data == '[DONE]') {
          if (_thinkingBuffer.isNotEmpty) {
            final response = DeepSeekChatResponse(
              {
                'choices': [
                  {
                    'message': {'content': '', 'role': 'assistant'},
                  },
                ],
              },
              _thinkingBuffer.toString(),
              List<CallWarning>.unmodifiable(warnings),
              {
                'provider': 'deepseek',
                'model': config.model,
                'reasonerModel': config.supportsReasoning,
                'hasThinking': true,
              },
            );
            events.add(CompletionEvent(response));
            _resetStreamState();
          }
          continue;
        }

        if (data.isEmpty) {
          continue;
        }

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final streamEvents = _parseStreamEventWithReasoning(
            json,
            _hasReasoningContent,
            _lastChunk,
            _thinkingBuffer,
            warnings,
          );

          final delta = _getDelta(json);
          if (delta != null) {
            final reasoningResult = ReasoningUtils.checkReasoningStatus(
              delta: delta,
              hasReasoningContent: _hasReasoningContent,
              lastChunk: _lastChunk,
            );
            _hasReasoningContent = reasoningResult.hasReasoningContent;
            _lastChunk = reasoningResult.updatedLastChunk;
          }

          events.addAll(streamEvents);
        } catch (e) {
          client.logger
              .warning('Failed to parse stream JSON: $data, error: $e');
          continue;
        }
      }
    }

    return events;
  }

  List<ChatStreamEvent> _parseStreamEventWithReasoning(
    Map<String, dynamic> json,
    bool hasReasoningContent,
    String lastChunk,
    StringBuffer thinkingBuffer,
    List<CallWarning> warnings,
  ) {
    final events = <ChatStreamEvent>[];
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) return events;

    final choice = choices.first as Map<String, dynamic>;
    final delta = choice['delta'] as Map<String, dynamic>?;
    if (delta == null) return events;

    if (config.supportsReasoning) {
      final reasoningContent = ReasoningUtils.extractReasoningContent(delta);

      if (reasoningContent != null && reasoningContent.isNotEmpty) {
        thinkingBuffer.write(reasoningContent);
        _hasReasoningContent = true;
        events.add(ThinkingDeltaEvent(reasoningContent));
        return events;
      }
    }

    final content = delta['content'] as String?;
    if (content != null && content.isNotEmpty) {
      _lastChunk = content;

      if (config.supportsReasoning) {
        final reasoningResult = ReasoningUtils.checkReasoningStatus(
          delta: delta,
          hasReasoningContent: _hasReasoningContent,
          lastChunk: lastChunk,
        );

        _hasReasoningContent = reasoningResult.hasReasoningContent;

        if (reasoningResult.isReasoningJustDone) {
          client.logger
              .fine('Reasoning phase completed, starting response phase');
        }
      }

      if (ReasoningUtils.containsThinkingTags(content)) {
        final thinkMatch = RegExp(
          r'<think>(.*?)</think>',
          dotAll: true,
        ).firstMatch(content);
        if (thinkMatch != null) {
          final thinkingText = thinkMatch.group(1)?.trim();
          if (thinkingText != null && thinkingText.isNotEmpty) {
            thinkingBuffer.write(thinkingText);
            events.add(ThinkingDeltaEvent(thinkingText));
          }
        }
        return events;
      }

      events.add(TextDeltaEvent(content));
    }

    final toolCalls = delta['tool_calls'] as List?;
    if (toolCalls != null && toolCalls.isNotEmpty) {
      final toolCallMap = toolCalls.first as Map<String, dynamic>;
      final toolCall = _toolCallStreamState.processDelta(toolCallMap);
      if (toolCall != null) {
        events.add(ToolCallDeltaEvent(toolCall));
      }
    }

    final finishReason = choice['finish_reason'] as String?;
    if (finishReason != null) {
      final rawUsage = json['usage'];
      final Map<String, dynamic>? usage;
      if (rawUsage == null) {
        usage = null;
      } else if (rawUsage is Map<String, dynamic>) {
        usage = rawUsage;
      } else if (rawUsage is Map) {
        usage = Map<String, dynamic>.from(rawUsage);
      } else {
        usage = null;
      }

      final thinkingContent =
          thinkingBuffer.isNotEmpty ? thinkingBuffer.toString() : null;

      final hasThinking =
          thinkingContent != null && thinkingContent.trim().isNotEmpty;

      final response = DeepSeekChatResponse(
        {
          'choices': [
            {
              'message': {'content': '', 'role': 'assistant'},
            },
          ],
          if (usage != null) 'usage': usage,
        },
        thinkingContent,
        List<CallWarning>.unmodifiable(warnings),
        {
          'provider': 'deepseek',
          'model': config.model,
          'reasonerModel': config.supportsReasoning,
          'hasThinking': hasThinking,
          'finishReason': finishReason,
        },
      );

      events.add(CompletionEvent(response));

      _resetStreamState();
    }

    return events;
  }

  Map<String, dynamic>? _getDelta(Map<String, dynamic> json) {
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) return null;

    final choice = choices.first as Map<String, dynamic>;
    return choice['delta'] as Map<String, dynamic>?;
  }

  Map<String, dynamic> _buildRequestBody(
    List<ModelMessage> promptMessages,
    List<Tool>? tools,
    bool stream,
    LanguageModelCallOptions? options,
    List<CallWarning> warnings,
  ) {
    final apiMessages = <Map<String, dynamic>>[];

    if (config.systemPrompt != null && config.systemPrompt!.isNotEmpty) {
      apiMessages.add({'role': 'system', 'content': config.systemPrompt});
    }

    for (final message in promptMessages) {
      apiMessages.add(_convertPromptMessage(message));
    }

    final body = <String, dynamic>{
      'model': config.model,
      'messages': apiMessages,
      'stream': stream,
    };

    final effectiveMaxTokens = options?.maxTokens ?? config.maxTokens;
    final effectiveTemperature = options?.temperature ?? config.temperature;
    final effectiveTopP = options?.topP ?? config.topP;
    final effectiveTopK = options?.topK ?? config.topK;

    if (effectiveMaxTokens != null) {
      body['max_tokens'] = effectiveMaxTokens;
    }
    if (effectiveTemperature != null) {
      body['temperature'] = effectiveTemperature;
    }
    if (effectiveTopP != null) {
      body['top_p'] = effectiveTopP;
    }
    if (effectiveTopK != null) {
      body['top_k'] = effectiveTopK;
    }

    // Forward advanced sampling parameters directly regardless of whether the
    // model is a reasoning variant. DeepSeek will surface any validation
    // errors or ignore unsupported parameters.
    if (config.logprobs != null) {
      body['logprobs'] = config.logprobs;
    }
    if (config.topLogprobs != null) {
      body['top_logprobs'] = config.topLogprobs;
    }
    if (config.frequencyPenalty != null) {
      body['frequency_penalty'] = config.frequencyPenalty;
    }
    if (config.presencePenalty != null) {
      body['presence_penalty'] = config.presencePenalty;
    }

    if (config.responseFormat != null) {
      body['response_format'] = config.responseFormat;
    }

    final effectiveTools = options?.tools ?? tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] = effectiveTools.map((t) => t.toJson()).toList();

      final effectiveToolChoice = options?.toolChoice ?? config.toolChoice;
      if (effectiveToolChoice != null) {
        body['tool_choice'] = effectiveToolChoice.toJson();
      }
    }

    return body;
  }

  Map<String, dynamic> _convertPromptMessage(ModelMessage message) {
    final role = switch (message.role) {
      ChatRole.system => 'system',
      ChatRole.user => 'user',
      ChatRole.assistant => 'assistant',
    };

    final result = <String, dynamic>{'role': role};

    final buffer = StringBuffer();
    final toolCalls = <Map<String, dynamic>>[];

    for (final part in message.parts) {
      if (part is TextContentPart) {
        buffer.write(part.text);
      } else if (part is ReasoningContentPart) {
        buffer.write(part.text);
      } else if (part is ToolCallContentPart &&
          message.role == ChatRole.assistant) {
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

    result['content'] = buffer.toString();
    if (toolCalls.isNotEmpty) {
      result['tool_calls'] = toolCalls;
    }

    // DeepSeek-specific: remove any reasoning_content field if present.
    result.remove('reasoning_content');

    return result;
  }

}

/// DeepSeek chat response implementation.
class DeepSeekChatResponse implements ChatResponse {
  final Map<String, dynamic> _rawResponse;
  final String? _thinkingContent;
  final List<CallWarning> _warnings;
  final Map<String, dynamic>? _metadata;

  DeepSeekChatResponse(this._rawResponse,
      [this._thinkingContent,
      List<CallWarning> warnings = const [],
      Map<String, dynamic>? metadata])
      : _warnings = warnings,
        _metadata = metadata;

  @override
  String? get text {
    final choices = _rawResponse['choices'] as List?;
    if (choices == null || choices.isEmpty) return null;

    final message = choices.first['message'] as Map<String, dynamic>?;
    return message?['content'] as String?;
  }

  @override
  List<ToolCall>? get toolCalls {
    final choices = _rawResponse['choices'] as List?;
    if (choices == null || choices.isEmpty) return null;

    final message = choices.first['message'] as Map<String, dynamic>?;
    final toolCalls = message?['tool_calls'] as List?;

    if (toolCalls == null) return null;

    return toolCalls
        .map((tc) => ToolCall.fromJson(tc as Map<String, dynamic>))
        .toList();
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

    return UsageInfo.fromJson(usageData);
  }

  @override
  String? get thinking => _thinkingContent;

  @override
  List<CallWarning> get warnings => _warnings;

  @override
  Map<String, dynamic>? get metadata => _metadata;

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
