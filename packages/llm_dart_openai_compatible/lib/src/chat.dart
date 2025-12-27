import 'dart:async';

import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/cancellation.dart';
import 'package:llm_dart_core/core/stream_parts.dart';
import 'package:llm_dart_core/core/llm_error.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';
import 'package:llm_dart_provider_utils/utils/reasoning_utils.dart';
import 'client.dart';
import 'openai_request_config.dart';
import 'request_builder.dart';

/// OpenAI Chat capability implementation
///
/// This module handles all chat-related functionality for OpenAI providers,
/// including streaming, tool calling, and reasoning model support.
class OpenAIChat implements ChatCapability, ChatStreamPartsCapability {
  final OpenAIClient client;
  final OpenAIRequestConfig config;
  final OpenAIRequestBuilder _requestBuilder;

  // State tracking for stream processing
  bool _hasReasoningContent = false;
  String _lastChunk = '';
  final StringBuffer _thinkingBuffer = StringBuffer();
  final Map<int, String> _toolCallIds = {};

  OpenAIChat(this.client, this.config)
      : _requestBuilder = OpenAIRequestBuilder(config);

  String get chatEndpoint => 'chat/completions';

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    final requestBody = _requestBuilder.buildChatCompletionsRequestBody(
      client,
      messages: messages,
      tools: tools,
      stream: false,
    );
    final responseData = await client.postJson(
      chatEndpoint,
      requestBody,
      cancelToken: cancelToken,
    );
    return _parseResponse(responseData);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    final effectiveTools = tools ?? config.tools;
    final requestBody = _requestBuilder.buildChatCompletionsRequestBody(
      client,
      messages: messages,
      tools: effectiveTools,
      stream: true,
    );

    client.resetSSEBuffer();
    _resetStreamState();

    final fullText = StringBuffer();
    final fullThinking = StringBuffer();

    final toolAccums = <String, _ToolCallAccum>{};
    final startedToolCalls = <String>{};

    String? id;
    String? model;
    String? systemFingerprint;
    Map<String, dynamic>? usage;

    String? finishReason;

    try {
      final stream = client.postStreamRaw(
        chatEndpoint,
        requestBody,
        cancelToken: cancelToken,
      );

      await for (final chunk in stream) {
        final jsonList = client.parseSSEChunk(chunk);
        if (jsonList.isEmpty) continue;

        for (final json in jsonList) {
          id ??= json['id'] as String?;
          model ??= json['model'] as String?;
          systemFingerprint ??= json['system_fingerprint'] as String?;

          final rawUsage = json['usage'];
          if (rawUsage is Map<String, dynamic>) {
            usage = {...?usage, ...rawUsage};
          } else if (rawUsage is Map) {
            usage = {...?usage, ...Map<String, dynamic>.from(rawUsage)};
          }

          final choices = json['choices'] as List?;
          if (choices == null || choices.isEmpty) continue;

          final choice = choices.first as Map<String, dynamic>;
          final delta = choice['delta'] as Map<String, dynamic>?;

          if (finishReason != null) {
            continue; // ignore any post-finish deltas (best-effort)
          }

          // Reasoning/thinking content (provider-specific fields).
          final reasoningContent =
              ReasoningUtils.extractReasoningContent(delta);
          if (reasoningContent != null && reasoningContent.isNotEmpty) {
            fullThinking.write(reasoningContent);
            yield ThinkingDeltaEvent(reasoningContent);
          }

          // Text content (may include <think> tags).
          final content = delta?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            _lastChunk = content;

            if (ReasoningUtils.containsThinkingTags(content)) {
              final thinkMatch = RegExp(
                r'<think>(.*?)</think>',
                dotAll: true,
              ).firstMatch(content);
              final thinkingText = thinkMatch?.group(1)?.trim();
              if (thinkingText != null && thinkingText.isNotEmpty) {
                fullThinking.write(thinkingText);
                yield ThinkingDeltaEvent(thinkingText);
              }
            } else {
              final reasoningResult = ReasoningUtils.checkReasoningStatus(
                delta: delta,
                hasReasoningContent: _hasReasoningContent,
                lastChunk: _lastChunk,
              );
              _hasReasoningContent = reasoningResult.hasReasoningContent;

              fullText.write(content);
              yield TextDeltaEvent(content);
            }
          }

          // Tool calls (client-side function tools).
          final toolCalls = delta?['tool_calls'] as List?;
          if (toolCalls != null && toolCalls.isNotEmpty) {
            for (final rawCall in toolCalls) {
              if (rawCall is! Map<String, dynamic>) continue;

              final index = rawCall['index'] as int?;
              if (index != null) {
                final callId = rawCall['id'] as String?;
                if (callId != null && callId.isNotEmpty) {
                  _toolCallIds[index] = callId;
                }

                final stableId = _toolCallIds[index];
                if (stableId == null || stableId.isEmpty) continue;

                final functionMap =
                    rawCall['function'] as Map<String, dynamic>?;
                if (functionMap == null) continue;

                final name = functionMap['name'] as String? ?? '';
                final args = functionMap['arguments'] as String? ?? '';
                if (name.isEmpty && args.isEmpty) continue;

                final accum =
                    toolAccums.putIfAbsent(stableId, () => _ToolCallAccum());
                if (name.isNotEmpty) {
                  accum.name = name;
                }
                if (args.isNotEmpty) {
                  accum.arguments.write(args);
                }

                final toolCall = ToolCall(
                  id: stableId,
                  callType: 'function',
                  function: FunctionCall(
                    name: name.isNotEmpty ? name : (accum.name ?? ''),
                    arguments: args,
                  ),
                );

                startedToolCalls.add(stableId);
                yield ToolCallDeltaEvent(toolCall);
              } else if (rawCall.containsKey('id') &&
                  rawCall.containsKey('function')) {
                try {
                  final toolCall = ToolCall.fromJson(rawCall);
                  final accum = toolAccums.putIfAbsent(
                    toolCall.id,
                    () => _ToolCallAccum(),
                  );
                  if (toolCall.function.name.isNotEmpty) {
                    accum.name = toolCall.function.name;
                  }
                  if (toolCall.function.arguments.isNotEmpty) {
                    accum.arguments.write(toolCall.function.arguments);
                  }

                  startedToolCalls.add(toolCall.id);
                  yield ToolCallDeltaEvent(toolCall);
                } catch (_) {
                  // Ignore malformed tool calls.
                }
              }
            }
          }

          final fr = choice['finish_reason'] as String?;
          if (fr != null) {
            finishReason = fr;
          }
        }
      }

      final completedToolCalls = toolAccums.entries
          .map((e) => e.value.toToolCall(e.key))
          .toList(growable: false);

      final response = OpenAIChatResponse(
        {
          if (id != null) 'id': id,
          if (model != null) 'model': model,
          if (systemFingerprint != null)
            'system_fingerprint': systemFingerprint,
          'choices': [
            {
              if (finishReason != null) 'finish_reason': finishReason,
              'message': {
                'role': 'assistant',
                'content': fullText.toString(),
                if (completedToolCalls.isNotEmpty)
                  'tool_calls':
                      completedToolCalls.map((c) => c.toJson()).toList(),
              },
            },
          ],
          if (usage != null) 'usage': usage,
        },
        fullThinking.isNotEmpty ? fullThinking.toString() : null,
        config.providerId,
      );

      yield CompletionEvent(response);
    } catch (e) {
      if (e is LLMError) {
        yield ErrorEvent(e);
        return;
      }
      yield ErrorEvent(GenericError('Stream error: $e'));
      return;
    } finally {
      client.resetSSEBuffer();
      _resetStreamState();
    }
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    final effectiveTools = tools ?? config.tools;
    final requestBody = _requestBuilder.buildChatCompletionsRequestBody(
      client,
      messages: messages,
      tools: effectiveTools,
      stream: true,
    );

    client.resetSSEBuffer();
    _resetStreamState();

    var inText = false;
    var inThinking = false;

    final fullText = StringBuffer();
    final fullThinking = StringBuffer();

    final toolAccums = <String, _ToolCallAccum>{};
    final startedToolCalls = <String>{};
    final endedToolCalls = <String>{};

    String? id;
    String? model;
    String? systemFingerprint;
    Map<String, dynamic>? usage;

    var didEmitTerminalParts = false;
    String? finishReason;

    try {
      final stream = client.postStreamRaw(
        chatEndpoint,
        requestBody,
        cancelToken: cancelToken,
      );

      await for (final chunk in stream) {
        final jsonList = client.parseSSEChunk(chunk);
        if (jsonList.isEmpty) continue;

        for (final json in jsonList) {
          id ??= json['id'] as String?;
          model ??= json['model'] as String?;
          systemFingerprint ??= json['system_fingerprint'] as String?;

          final rawUsage = json['usage'];
          if (rawUsage is Map<String, dynamic>) {
            usage = {...?usage, ...rawUsage};
          } else if (rawUsage is Map) {
            usage = {...?usage, ...Map<String, dynamic>.from(rawUsage)};
          }

          final choices = json['choices'] as List?;
          if (choices == null || choices.isEmpty) continue;

          final choice = choices.first as Map<String, dynamic>;
          final delta = choice['delta'] as Map<String, dynamic>?;

          // After a finish_reason has been observed, some providers (e.g. Azure)
          // may still stream trailing chunks containing `usage` with empty
          // `choices`. Ignore any post-finish deltas.
          if (finishReason != null) {
            continue;
          }

          // Reasoning/thinking content (provider-specific fields).
          final reasoningContent =
              ReasoningUtils.extractReasoningContent(delta);
          if (reasoningContent != null && reasoningContent.isNotEmpty) {
            if (!inThinking) {
              inThinking = true;
              yield const LLMReasoningStartPart();
            }
            fullThinking.write(reasoningContent);
            yield LLMReasoningDeltaPart(reasoningContent);
          }

          // Text content (may include <think> tags).
          final content = delta?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            _lastChunk = content;

            if (ReasoningUtils.containsThinkingTags(content)) {
              final thinkMatch = RegExp(
                r'<think>(.*?)</think>',
                dotAll: true,
              ).firstMatch(content);
              final thinkingText = thinkMatch?.group(1)?.trim();
              if (thinkingText != null && thinkingText.isNotEmpty) {
                if (!inThinking) {
                  inThinking = true;
                  yield const LLMReasoningStartPart();
                }
                fullThinking.write(thinkingText);
                yield LLMReasoningDeltaPart(thinkingText);
              }
            } else {
              final reasoningResult = ReasoningUtils.checkReasoningStatus(
                delta: delta,
                hasReasoningContent: _hasReasoningContent,
                lastChunk: _lastChunk,
              );
              _hasReasoningContent = reasoningResult.hasReasoningContent;

              if (!inText) {
                inText = true;
                yield const LLMTextStartPart();
              }
              fullText.write(content);
              yield LLMTextDeltaPart(content);
            }
          }

          // Tool calls (client-side function tools).
          final toolCalls = delta?['tool_calls'] as List?;
          if (toolCalls != null && toolCalls.isNotEmpty) {
            for (final rawCall in toolCalls) {
              if (rawCall is! Map<String, dynamic>) continue;

              final index = rawCall['index'] as int?;
              if (index != null) {
                final callId = rawCall['id'] as String?;
                if (callId != null && callId.isNotEmpty) {
                  _toolCallIds[index] = callId;
                }

                final stableId = _toolCallIds[index];
                if (stableId == null || stableId.isEmpty) continue;

                final functionMap =
                    rawCall['function'] as Map<String, dynamic>?;
                if (functionMap == null) continue;

                final name = functionMap['name'] as String? ?? '';
                final args = functionMap['arguments'] as String? ?? '';
                if (name.isEmpty && args.isEmpty) continue;

                final accum =
                    toolAccums.putIfAbsent(stableId, () => _ToolCallAccum());
                if (name.isNotEmpty) {
                  accum.name = name;
                }
                if (args.isNotEmpty) {
                  accum.arguments.write(args);
                }

                final toolCall = ToolCall(
                  id: stableId,
                  callType: 'function',
                  function: FunctionCall(
                    name: name.isNotEmpty ? name : (accum.name ?? ''),
                    arguments: args,
                  ),
                );

                if (startedToolCalls.add(stableId)) {
                  yield LLMToolCallStartPart(toolCall);
                } else {
                  yield LLMToolCallDeltaPart(toolCall);
                }
              } else if (rawCall.containsKey('id') &&
                  rawCall.containsKey('function')) {
                try {
                  final toolCall = ToolCall.fromJson(rawCall);
                  final accum = toolAccums.putIfAbsent(
                    toolCall.id,
                    () => _ToolCallAccum(),
                  );
                  if (toolCall.function.name.isNotEmpty) {
                    accum.name = toolCall.function.name;
                  }
                  if (toolCall.function.arguments.isNotEmpty) {
                    accum.arguments.write(toolCall.function.arguments);
                  }

                  if (startedToolCalls.add(toolCall.id)) {
                    yield LLMToolCallStartPart(toolCall);
                  } else {
                    yield LLMToolCallDeltaPart(toolCall);
                  }
                } catch (_) {
                  // Ignore malformed tool calls.
                }
              }
            }
          }

          // Finish.
          final fr = choice['finish_reason'] as String?;
          if (fr != null) {
            finishReason = fr;

            if (!didEmitTerminalParts) {
              didEmitTerminalParts = true;

              if (inText) {
                yield LLMTextEndPart(fullText.toString());
              }
              if (inThinking) {
                yield LLMReasoningEndPart(fullThinking.toString());
              }
              for (final toolCallId in startedToolCalls) {
                if (endedToolCalls.add(toolCallId)) {
                  yield LLMToolCallEndPart(toolCallId);
                }
              }
            }
          }
        }
      }

      final completedToolCalls = toolAccums.entries
          .map((e) => e.value.toToolCall(e.key))
          .toList(growable: false);

      if (finishReason != null) {
        final response = OpenAIChatResponse(
          {
            if (id != null) 'id': id,
            if (model != null) 'model': model,
            if (systemFingerprint != null)
              'system_fingerprint': systemFingerprint,
            'choices': [
              {
                'finish_reason': finishReason,
                'message': {
                  'role': 'assistant',
                  'content': fullText.toString(),
                  if (completedToolCalls.isNotEmpty)
                    'tool_calls':
                        completedToolCalls.map((c) => c.toJson()).toList(),
                },
              },
            ],
            if (usage != null) 'usage': usage,
          },
          fullThinking.isNotEmpty ? fullThinking.toString() : null,
          config.providerId,
        );

        final metadata = response.providerMetadata;
        if (metadata != null && metadata.isNotEmpty) {
          yield LLMProviderMetadataPart(metadata);
        }

        yield LLMFinishPart(response);
        return;
      }

      // Best-effort finish if stream ends without a finish_reason chunk.
      if (finishReason == null) {
        if (inText) {
          yield LLMTextEndPart(fullText.toString());
        }
        if (inThinking) {
          yield LLMReasoningEndPart(fullThinking.toString());
        }
        for (final toolCallId in startedToolCalls) {
          if (endedToolCalls.add(toolCallId)) {
            yield LLMToolCallEndPart(toolCallId);
          }
        }

        final response = OpenAIChatResponse(
          {
            if (id != null) 'id': id,
            if (model != null) 'model': model,
            if (systemFingerprint != null)
              'system_fingerprint': systemFingerprint,
            'choices': [
              {
                'message': {
                  'role': 'assistant',
                  'content': fullText.toString(),
                  if (completedToolCalls.isNotEmpty)
                    'tool_calls':
                        completedToolCalls.map((c) => c.toJson()).toList(),
                },
              },
            ],
            if (usage != null) 'usage': usage,
          },
          fullThinking.isNotEmpty ? fullThinking.toString() : null,
          config.providerId,
        );

        final metadata = response.providerMetadata;
        if (metadata != null && metadata.isNotEmpty) {
          yield LLMProviderMetadataPart(metadata);
        }
        yield LLMFinishPart(response);
      }
    } catch (e) {
      if (e is LLMError) {
        yield LLMErrorPart(e);
        return;
      }
      yield LLMErrorPart(GenericError('Stream error: $e'));
      return;
    } finally {
      client.resetSSEBuffer();
      _resetStreamState();
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

    // Filter out thinking content for reasoning models
    return ReasoningUtils.filterThinkingContent(text);
  }

  /// Parse non-streaming response
  ChatResponse _parseResponse(Map<String, dynamic> responseData) {
    // Extract thinking/reasoning content from non-streaming response
    String? thinkingContent;

    final choices = responseData['choices'] as List?;
    if (choices != null && choices.isNotEmpty) {
      final choice = choices.first as Map<String, dynamic>;
      final message = choice['message'] as Map<String, dynamic>?;

      if (message != null) {
        // Check for reasoning content in various possible fields
        thinkingContent = message['reasoning'] as String? ??
            message['thinking'] as String? ??
            message['reasoning_content'] as String?;

        // For models that use <think> tags, extract thinking content
        final content = message['content'] as String?;
        if (content != null && ReasoningUtils.containsThinkingTags(content)) {
          final thinkMatch = RegExp(
            r'<think>(.*?)</think>',
            dotAll: true,
          ).firstMatch(content);
          if (thinkMatch != null) {
            thinkingContent = thinkMatch.group(1)?.trim();
            // Update the message content to remove thinking tags
            message['content'] = ReasoningUtils.filterThinkingContent(content);
          }
        }

        // Some OpenRouter responses may include reasoning at the top-level.
        if (thinkingContent == null && config.model.contains('deepseek-r1')) {
          final reasoning = responseData['reasoning'] as String?;
          if (reasoning != null && reasoning.isNotEmpty) {
            thinkingContent = reasoning;
          }
        }
      }
    }

    return OpenAIChatResponse(responseData, thinkingContent, config.providerId);
  }

  /// Parse streaming events
  List<ChatStreamEvent> _parseStreamEvents(String chunk) {
    final events = <ChatStreamEvent>[];

    // Parse SSE chunk - now returns a list of JSON objects
    final jsonList = client.parseSSEChunk(chunk);
    if (jsonList.isEmpty) return events;

    // Process each JSON object in the chunk
    for (final json in jsonList) {
      // Use existing stream parsing logic with proper state tracking
      final parsedEvents = _parseStreamEventWithReasoning(
        json,
        _hasReasoningContent,
        _lastChunk,
        _thinkingBuffer,
      );

      events.addAll(parsedEvents);
    }

    return events;
  }

  /// Reset stream state (call this when starting a new stream)
  void _resetStreamState() {
    _hasReasoningContent = false;
    _lastChunk = '';
    _thinkingBuffer.clear();
    _toolCallIds.clear();
  }

  /// Parse stream events with reasoning support
  List<ChatStreamEvent> _parseStreamEventWithReasoning(
    Map<String, dynamic> json,
    bool hasReasoningContent,
    String lastChunk,
    StringBuffer thinkingBuffer,
  ) {
    final events = <ChatStreamEvent>[];
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) return events;

    final choice = choices.first as Map<String, dynamic>;
    final delta = choice['delta'] as Map<String, dynamic>?;
    if (delta == null) return events;

    // Handle reasoning content using reasoning utils
    final reasoningContent = ReasoningUtils.extractReasoningContent(delta);

    if (reasoningContent != null && reasoningContent.isNotEmpty) {
      thinkingBuffer.write(reasoningContent);
      _hasReasoningContent = true; // Update state
      events.add(ThinkingDeltaEvent(reasoningContent));
      return events;
    }

    // Handle regular content
    final content = delta['content'] as String?;
    if (content != null && content.isNotEmpty) {
      // Update last chunk for reasoning detection
      _lastChunk = content;

      // Check reasoning status using utils
      final reasoningResult = ReasoningUtils.checkReasoningStatus(
        delta: delta,
        hasReasoningContent: _hasReasoningContent,
        lastChunk: lastChunk,
      );

      // Update state based on reasoning detection
      _hasReasoningContent = reasoningResult.hasReasoningContent;

      // Filter out thinking tags for models that use <think> tags
      if (ReasoningUtils.containsThinkingTags(content)) {
        // Extract thinking content and add to buffer
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
        // Don't emit content that contains thinking tags
        return events;
      }

      events.add(TextDeltaEvent(content));
    }

    // Handle tool calls
    final toolCalls = delta['tool_calls'] as List?;
    if (toolCalls != null && toolCalls.isNotEmpty) {
      final toolCallMap = toolCalls.first as Map<String, dynamic>;
      final index = toolCallMap['index'] as int?;

      if (index != null) {
        // If ID is present, store it
        if (toolCallMap.containsKey('id')) {
          final id = toolCallMap['id'] as String;
          _toolCallIds[index] = id;
        }

        // If we have an ID for this index (either just stored or from before), emit event
        if (_toolCallIds.containsKey(index)) {
          final id = _toolCallIds[index]!;

          // Construct a valid ToolCall delta even if ID is missing in this chunk
          final functionMap = toolCallMap['function'] as Map<String, dynamic>?;
          if (functionMap != null) {
            final name = functionMap['name'] as String? ?? '';
            final args = functionMap['arguments'] as String? ?? '';

            // Only emit if we have something to update
            if (name.isNotEmpty || args.isNotEmpty) {
              final toolCall = ToolCall(
                id: id,
                callType: 'function',
                function: FunctionCall(
                  name: name,
                  arguments: args,
                ),
              );
              events.add(ToolCallDeltaEvent(toolCall));
            }
          }
        }
      } else if (toolCallMap.containsKey('id') &&
          toolCallMap.containsKey('function')) {
        // Fallback for non-indexed tool calls (rare in streams but possible)
        try {
          events.add(ToolCallDeltaEvent(ToolCall.fromJson(toolCallMap)));
        } catch (e) {
          client.logger.warning('Failed to parse tool call: $e');
        }
      }
    }

    // Check for finish reason
    final finishReason = choice['finish_reason'] as String?;
    if (finishReason != null) {
      final usage = json['usage'] as Map<String, dynamic>?;
      final thinkingContent =
          thinkingBuffer.isNotEmpty ? thinkingBuffer.toString() : null;

      final response = OpenAIChatResponse({
        'choices': [
          {
            'message': {'content': '', 'role': 'assistant'},
          },
        ],
        if (usage != null) 'usage': usage,
      }, thinkingContent, config.providerId);

      events.add(CompletionEvent(response));

      // Reset state after completion
      _resetStreamState();
    }

    return events;
  }
}

class _ToolCallAccum {
  String? name;
  final StringBuffer arguments = StringBuffer();

  ToolCall toToolCall(String id) {
    return ToolCall(
      id: id,
      callType: 'function',
      function: FunctionCall(
        name: name ?? '',
        arguments: arguments.toString(),
      ),
    );
  }
}

/// OpenAI chat response implementation
class OpenAIChatResponse implements ChatResponse {
  final Map<String, dynamic> _rawResponse;
  final String? _thinkingContent;
  final String? _providerId;

  OpenAIChatResponse(this._rawResponse,
      [this._thinkingContent, this._providerId]);

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

    // Safely convert Map<dynamic, dynamic> to Map<String, dynamic>
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
  Map<String, dynamic>? get providerMetadata {
    final id = _rawResponse['id'];
    final model = _rawResponse['model'];
    final systemFingerprint = _rawResponse['system_fingerprint'];
    final choices = _rawResponse['choices'] as List?;
    final finishReason = (choices != null &&
            choices.isNotEmpty &&
            choices.first is Map &&
            (choices.first as Map).containsKey('finish_reason'))
        ? (choices.first as Map)['finish_reason'] as String?
        : null;

    if (id == null &&
        model == null &&
        systemFingerprint == null &&
        finishReason == null) {
      return null;
    }

    final providerId = _providerId ?? 'openai';
    return {
      providerId: {
        if (id != null) 'id': id,
        if (model != null) 'model': model,
        if (systemFingerprint != null) 'systemFingerprint': systemFingerprint,
        if (finishReason != null) 'finishReason': finishReason,
      },
    };
  }

  @override
  String toString() {
    final textContent = text;
    final calls = toolCalls;

    if (textContent != null && calls != null) {
      return '${calls.map((c) => c.toString()).join('\n')}\n$textContent';
    } else if (textContent != null) {
      return textContent;
    } else if (calls != null) {
      return calls.map((c) => c.toString()).join('\n');
    } else {
      return '';
    }
  }
}
