import 'dart:async';

import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/cancellation.dart';
import 'package:llm_dart_core/core/llm_error.dart';
import 'package:llm_dart_core/core/stream_parts.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';

class _FunctionCallAccum {
  String? name;
  String arguments = '';
}

/// xAI Responses API implementation (`POST /v1/responses`).
///
/// This mirrors the event stream shape used by the OpenAI Responses API
/// (`response.output_text.delta`, `response.reasoning_summary_text.delta`, etc),
/// but uses xAI's tool definition shapes (e.g. `tools: [{type: "web_search"}]`).
class XAIResponses implements ChatCapability, ChatStreamPartsCapability {
  final OpenAIClient client;
  final OpenAICompatibleConfig config;

  XAIResponses(this.client, this.config);

  String get responsesEndpoint => 'responses';

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
    final body = _buildRequestBody(
      messages: messages,
      tools: tools,
      stream: false,
    );
    final responseData = await client.postJson(
      responsesEndpoint,
      body,
      cancelToken: cancelToken,
    );
    return _parseResponse(responseData);
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    final prompt = 'Summarize in 2-3 sentences:\n'
        '${messages.map((m) => '${m.role.name}: ${m.content}').join('\n')}';
    final response = await chat([ChatMessage.user(prompt)]);
    final text = response.text;
    if (text == null) {
      throw const GenericError('no text in summary response');
    }
    return text;
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    await for (final part in chatStreamParts(
      messages,
      tools: tools,
      cancelToken: cancelToken,
    )) {
      switch (part) {
        case LLMTextDeltaPart(:final delta):
          yield TextDeltaEvent(delta);
        case LLMReasoningDeltaPart(:final delta):
          yield ThinkingDeltaEvent(delta);
        case LLMToolCallStartPart(:final toolCall):
          yield ToolCallDeltaEvent(toolCall);
        case LLMToolCallDeltaPart(:final toolCall):
          yield ToolCallDeltaEvent(toolCall);
        case LLMFinishPart(:final response):
          yield CompletionEvent(response);
        case LLMErrorPart(:final error):
          yield ErrorEvent(error);
          return;
        default:
          // Ignore structural parts for legacy event stream.
          break;
      }
    }
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    final body = _buildRequestBody(
      messages: messages,
      tools: tools,
      stream: true,
    );

    client.resetSSEBuffer();

    var inText = false;
    var inThinking = false;
    var endedText = false;
    var endedThinking = false;

    final fullText = StringBuffer();
    final fullThinking = StringBuffer();

    final toolAccums = <String, _FunctionCallAccum>{};
    final startedToolCalls = <String>{};
    final endedToolCalls = <String>{};

    Map<String, dynamic>? finalResponseObject;

    try {
      final stream = client.postStreamRaw(
        responsesEndpoint,
        body,
        cancelToken: cancelToken,
      );

      await for (final chunk in stream) {
        final jsonList = client.parseSSEChunk(chunk);
        if (jsonList.isEmpty) continue;

        for (final json in jsonList) {
          final eventType = json['type'] as String?;
          if (eventType == null || eventType.isEmpty) continue;

          if (eventType == 'response.reasoning_summary_part.added') {
            if (!inThinking) {
              inThinking = true;
              yield const LLMReasoningStartPart();
            }
            continue;
          }

          if (eventType == 'response.output_text.delta') {
            final delta = json['delta'] as String?;
            if (delta == null || delta.isEmpty) continue;

            if (!inText) {
              inText = true;
              yield const LLMTextStartPart();
            }
            fullText.write(delta);
            yield LLMTextDeltaPart(delta);
            continue;
          }

          if (eventType == 'response.reasoning_summary_text.delta') {
            final delta = json['delta'] as String?;
            if (delta == null || delta.isEmpty) continue;

            if (!inThinking) {
              inThinking = true;
              yield const LLMReasoningStartPart();
            }
            fullThinking.write(delta);
            yield LLMReasoningDeltaPart(delta);
            continue;
          }

          if (eventType == 'response.reasoning_summary_text.done') {
            final text = json['text'] as String?;
            if (text != null && text.isNotEmpty) {
              fullThinking
                ..clear()
                ..write(text);
            }

            if (inThinking && !endedThinking) {
              endedThinking = true;
              yield LLMReasoningEndPart(fullThinking.toString());
            }
            continue;
          }

          if (eventType == 'response.output_text.done') {
            final text = json['text'] as String?;
            if (text != null && text.isNotEmpty) {
              fullText
                ..clear()
                ..write(text);
            }

            if (inText && !endedText) {
              endedText = true;
              yield LLMTextEndPart(fullText.toString());
            }
            continue;
          }

          if (eventType == 'response.output_item.added' ||
              eventType == 'response.output_item.done') {
            final item = json['item'] as Map<String, dynamic>?;
            if (item == null) continue;

            if (item['type'] == 'function_call') {
              final callId =
                  (item['call_id'] as String?) ?? (item['id'] as String?);
              if (callId == null || callId.isEmpty) continue;

              final name = item['name'] as String? ?? '';
              final args = item['arguments'] as String? ?? '';

              final accum =
                  toolAccums.putIfAbsent(callId, () => _FunctionCallAccum());
              if (name.isNotEmpty) accum.name = name;
              if (args.isNotEmpty) accum.arguments = args;

              final toolCall = ToolCall(
                id: callId,
                callType: 'function',
                function: FunctionCall(
                  name: name.isNotEmpty ? name : (accum.name ?? ''),
                  arguments: args,
                ),
              );

              if (startedToolCalls.add(callId)) {
                yield LLMToolCallStartPart(toolCall);
              } else {
                yield LLMToolCallDeltaPart(toolCall);
              }

              if (eventType == 'response.output_item.done') {
                if (endedToolCalls.add(callId)) {
                  yield LLMToolCallEndPart(callId);
                }
              }
            }

            continue;
          }

          if (eventType == 'response.completed' ||
              eventType == 'response.done') {
            final rawResponse = json['response'];
            if (rawResponse is Map<String, dynamic>) {
              finalResponseObject = rawResponse;
            } else if (rawResponse is Map) {
              finalResponseObject = Map<String, dynamic>.from(rawResponse);
            }

            final parsed = finalResponseObject == null
                ? null
                : _parseResponse(finalResponseObject);

            final finishText = fullText.isNotEmpty
                ? fullText.toString()
                : (parsed?.text ?? '');
            final finishThinking = fullThinking.isNotEmpty
                ? fullThinking.toString()
                : (parsed?.thinking ?? '');

            if (inText && !endedText) {
              endedText = true;
              yield LLMTextEndPart(finishText);
            }
            if (inThinking && !endedThinking) {
              endedThinking = true;
              yield LLMReasoningEndPart(finishThinking);
            }

            for (final toolCallId in startedToolCalls) {
              if (endedToolCalls.add(toolCallId)) {
                yield LLMToolCallEndPart(toolCallId);
              }
            }

            final response = parsed ??
                XAIResponsesChatResponse(
                  providerId: config.providerId,
                  text: finishText,
                  thinking: finishThinking.isNotEmpty ? finishThinking : null,
                );

            final metadata = response.providerMetadata;
            if (metadata != null && metadata.isNotEmpty) {
              yield LLMProviderMetadataPart(metadata);
            }

            yield LLMFinishPart(response);
            return;
          }
        }
      }

      final response = XAIResponsesChatResponse(
        providerId: config.providerId,
        text: fullText.toString(),
        thinking: fullThinking.isNotEmpty ? fullThinking.toString() : null,
      );
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
      yield LLMErrorPart(GenericError('Stream error: $e'));
      return;
    } finally {
      client.resetSSEBuffer();
    }
  }

  Map<String, dynamic> _buildRequestBody({
    required List<ChatMessage> messages,
    required List<Tool>? tools,
    required bool stream,
  }) {
    final input = _buildInputMessages(messages);
    final effectiveTools = tools ?? config.tools;

    final body = <String, dynamic>{
      'model': config.model,
      'input': input,
      'stream': stream,
    };

    if (config.maxTokens != null) {
      body['max_output_tokens'] = config.maxTokens;
    }
    if (config.temperature != null) {
      body['temperature'] = config.temperature;
    }
    if (config.topP != null) body['top_p'] = config.topP;
    if (config.topK != null) body['top_k'] = config.topK;

    if (config.reasoningEffort != null) {
      body['reasoning'] = {'effort': config.reasoningEffort!.value};
    }

    final previousResponseId =
        config.getProviderOption<String>('previousResponseId') ??
            config.getProviderOption<String>('previous_response_id');
    if (previousResponseId != null && previousResponseId.isNotEmpty) {
      body['previous_response_id'] = previousResponseId;
    }

    final store = config.getProviderOption<bool>('store');
    if (store != null) {
      body['store'] = store;
    }

    final toolsJson = <Map<String, dynamic>>[];

    final providerTools = config.originalConfig?.providerTools;
    if (providerTools != null && providerTools.isNotEmpty) {
      toolsJson.addAll(providerTools.map(_convertProviderTool));
    }

    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      toolsJson.addAll(effectiveTools.map(_convertFunctionTool));
    }

    if (toolsJson.isNotEmpty) {
      body['tools'] = toolsJson;

      final toolChoice = config.toolChoice;
      if (toolChoice != null) {
        body['tool_choice'] = _convertToolChoice(toolChoice);
      }
    }

    final parallelToolCalls =
        config.getProviderOption<bool>('parallelToolCalls');
    if (parallelToolCalls != null) {
      body['parallel_tool_calls'] = parallelToolCalls;
    }

    final extraBodyFromConfig = config.extraBody;
    if (extraBodyFromConfig != null && extraBodyFromConfig.isNotEmpty) {
      body.addAll(extraBodyFromConfig);
    }

    return body;
  }

  List<Map<String, dynamic>> _buildInputMessages(List<ChatMessage> messages) {
    final input = <Map<String, dynamic>>[];
    var hasSystemMessage = false;

    for (final message in messages) {
      if (message.role == ChatRole.system) {
        hasSystemMessage = true;
      }

      switch (message.messageType) {
        case TextMessage():
          input.add({
            'role': switch (message.role) {
              ChatRole.system => 'system',
              ChatRole.user => 'user',
              ChatRole.assistant => 'assistant',
            },
            'content': message.content,
          });
          break;

        case ToolUseMessage(toolCalls: final calls):
          for (final call in calls) {
            input.add({
              'type': 'function_call',
              'id': call.id,
              'call_id': call.id,
              'name': call.function.name,
              'arguments': call.function.arguments,
              'status': 'completed',
            });
          }
          break;

        case ToolResultMessage(results: final results):
          for (final result in results) {
            input.add({
              'type': 'function_call_output',
              'call_id': result.id,
              'output': message.content.isNotEmpty
                  ? message.content
                  : (result.function.arguments.isNotEmpty
                      ? result.function.arguments
                      : 'Tool result'),
            });
          }
          break;

        default:
          throw UnsupportedError(
            'xAI Responses API does not support ${message.messageType.runtimeType} messages',
          );
      }
    }

    if (!hasSystemMessage && config.systemPrompt != null) {
      input.insert(0, {'role': 'system', 'content': config.systemPrompt});
    }

    return input;
  }

  Map<String, dynamic> _convertFunctionTool(Tool tool) {
    return {
      'type': 'function',
      'function': {
        'name': tool.function.name,
        'description': tool.function.description,
        'parameters': tool.function.parameters.toJson(),
      },
    };
  }

  Map<String, dynamic> _convertProviderTool(ProviderTool tool) {
    final rawId = tool.id;
    final id = rawId.startsWith('xai.') ? rawId.substring(4) : rawId;

    Map<String, dynamic> applyOptions(Map<String, dynamic> base) {
      if (tool.options.isEmpty) return base;
      return {
        ...base,
        ..._normalizeXaiToolOptions(tool.options),
      };
    }

    return switch (id) {
      'web_search' => applyOptions({'type': 'web_search'}),
      'x_search' => applyOptions({'type': 'x_search'}),
      'code_execution' => applyOptions({'type': 'code_interpreter'}),
      'view_image' => applyOptions({'type': 'view_image'}),
      'view_x_video' => applyOptions({'type': 'view_x_video'}),
      'file_search' => applyOptions({'type': 'file_search'}),
      'mcp' => applyOptions({'type': 'mcp'}),
      _ => applyOptions({'type': id}),
    };
  }

  Map<String, dynamic> _normalizeXaiToolOptions(Map<String, dynamic> options) {
    final out = <String, dynamic>{};

    void mapKey(String from, String to) {
      if (!options.containsKey(from)) return;
      out[to] = options[from];
    }

    mapKey('allowedDomains', 'allowed_domains');
    mapKey('excludedDomains', 'excluded_domains');
    mapKey('enableImageUnderstanding', 'enable_image_understanding');

    mapKey('allowedXHandles', 'allowed_x_handles');
    mapKey('excludedXHandles', 'excluded_x_handles');
    mapKey('fromDate', 'from_date');
    mapKey('toDate', 'to_date');
    mapKey('enableVideoUnderstanding', 'enable_video_understanding');

    // Pass through already-snake_case keys.
    for (final entry in options.entries) {
      final k = entry.key;
      if (!k.contains('_')) continue;
      out[k] = entry.value;
    }

    return out;
  }

  dynamic _convertToolChoice(ToolChoice choice) {
    return switch (choice) {
      AutoToolChoice() => 'auto',
      NoneToolChoice() => 'none',
      AnyToolChoice() => 'required',
      SpecificToolChoice(toolName: final name) => {
          'type': 'function',
          'name': name
        },
    };
  }

  ChatResponse _parseResponse(Map<String, dynamic> responseData) {
    final output = responseData['output'] as List?;

    final text = StringBuffer();
    final thinking = StringBuffer();
    final toolCalls = <ToolCall>[];

    final serverToolCalls = <Map<String, dynamic>>[];
    final sources = <Map<String, dynamic>>[];

    if (output != null) {
      for (final item in output) {
        if (item is! Map) continue;
        final type = item['type'];

        if (type == 'message') {
          final content = item['content'];
          if (content is List) {
            for (final part in content) {
              if (part is! Map) continue;
              if (part['type'] != 'output_text') continue;
              final t = part['text'];
              if (t is String) text.write(t);

              final annotations = part['annotations'];
              if (annotations is List) {
                for (final a in annotations) {
                  if (a is! Map) continue;
                  if (a['type'] != 'url_citation') continue;
                  final url = a['url'];
                  if (url is! String || url.isEmpty) continue;
                  final title = a['title'];
                  sources.add({
                    'type': 'url',
                    'url': url,
                    if (title is String && title.isNotEmpty) 'title': title,
                  });
                }
              }
            }
          }
          continue;
        }

        if (type == 'reasoning') {
          final summary = item['summary'];
          if (summary is List) {
            for (final part in summary) {
              if (part is! Map) continue;
              if (part['type'] != 'summary_text') continue;
              final t = part['text'];
              if (t is String) thinking.write(t);
            }
          }
          continue;
        }

        if (type == 'function_call') {
          final callId =
              (item['call_id'] as String?) ?? (item['id'] as String?);
          final name = item['name'] as String? ?? '';
          final args = item['arguments'] as String? ?? '';
          if (callId == null || callId.isEmpty || name.isEmpty) continue;

          toolCalls.add(
            ToolCall(
              id: callId,
              callType: 'function',
              function: FunctionCall(name: name, arguments: args),
            ),
          );
          continue;
        }

        if (type is String && type.endsWith('_call')) {
          final id = item['id'];
          final status = item['status'];
          final name = item['name'];
          final args = item['arguments'];
          final call = <String, dynamic>{
            'type': type,
            if (id != null) 'id': id,
            if (status != null) 'status': status,
            if (name != null) 'name': name,
            if (args != null) 'arguments': args,
          };
          serverToolCalls.add(call);
        }
      }
    }

    final usageRaw = responseData['usage'];
    UsageInfo? usage;
    if (usageRaw is Map) {
      final usageMap = usageRaw.cast<String, dynamic>();
      final inputTokens = usageMap['input_tokens'] as int?;
      final outputTokens = usageMap['output_tokens'] as int?;
      final totalTokens = usageMap['total_tokens'] as int? ??
          ((inputTokens ?? 0) + (outputTokens ?? 0));

      final outputDetails = usageMap['output_tokens_details'];
      final reasoningTokens = outputDetails is Map
          ? (outputDetails['reasoning_tokens'] as int?)
          : null;

      usage = UsageInfo(
        promptTokens: inputTokens,
        completionTokens: outputTokens,
        totalTokens: totalTokens,
        reasoningTokens: reasoningTokens,
      );
    }

    final id = responseData['id'] as String?;
    final model = responseData['model'] as String?;
    final status = responseData['status'] as String?;

    return XAIResponsesChatResponse(
      providerId: config.providerId,
      text: text.toString(),
      thinking: thinking.isNotEmpty ? thinking.toString() : null,
      toolCalls: toolCalls.isNotEmpty ? toolCalls : null,
      usage: usage,
      responseId: id,
      model: model,
      status: status,
      serverToolCalls: serverToolCalls.isNotEmpty ? serverToolCalls : null,
      sources: sources.isNotEmpty ? sources : null,
    );
  }
}

class XAIResponsesChatResponse implements ChatResponse {
  final String providerId;
  @override
  final String? text;
  @override
  final String? thinking;
  @override
  final List<ToolCall>? toolCalls;
  @override
  final UsageInfo? usage;

  final String? responseId;
  final String? model;
  final String? status;
  final List<Map<String, dynamic>>? serverToolCalls;
  final List<Map<String, dynamic>>? sources;

  XAIResponsesChatResponse({
    required this.providerId,
    required this.text,
    this.thinking,
    this.toolCalls,
    this.usage,
    this.responseId,
    this.model,
    this.status,
    this.serverToolCalls,
    this.sources,
  });

  @override
  Map<String, dynamic>? get providerMetadata => {
        providerId: {
          if (responseId != null) 'id': responseId,
          if (model != null) 'model': model,
          if (status != null) 'status': status,
          if (serverToolCalls != null) 'serverToolCalls': serverToolCalls,
          if (sources != null) 'sources': sources,
        },
      };
}
