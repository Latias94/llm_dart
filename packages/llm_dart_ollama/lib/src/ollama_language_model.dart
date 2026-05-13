import 'dart:async';
import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'ollama_api.dart';
import 'ollama_model_describer.dart';
import 'ollama_options.dart';

final class OllamaLanguageModel
    implements LanguageModel, CapabilityDescribedModel {
  final String? apiKey;
  final String baseUrl;
  final TransportClient transport;
  final OllamaChatModelSettings settings;

  @override
  final String modelId;

  OllamaLanguageModel({
    required this.modelId,
    required this.transport,
    String? apiKey,
    String? baseUrl,
    this.settings = const OllamaChatModelSettings(),
  })  : apiKey = normalizeOllamaApiKey(apiKey),
        baseUrl = normalizeOllamaBaseUrl(baseUrl);

  @override
  String get providerId => 'ollama';

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeOllamaChatModel(
      modelId,
      settings: settings,
    );
  }

  Uri get chatUri => resolveOllamaUri(baseUrl, '/api/chat');

  Map<String, String> get defaultHeaders => buildOllamaHeaders(
        apiKey: apiKey,
        contentType: 'application/json',
        headers: settings.headers,
      );

  @override
  Future<GenerateTextResult> doGenerate(GenerateTextRequest request) async {
    final preparedRequest = await _prepareRequest(request, stream: false);
    final response = await transport.send(
      TransportRequest(
        uri: chatUri,
        method: TransportMethod.post,
        headers: {
          ...defaultHeaders,
          if (request.callOptions.headers case final headers?) ...headers,
        },
        body: preparedRequest.body,
        timeout: request.callOptions.timeout,
        maxRetries: request.callOptions.maxRetries,
        cancellation: request.callOptions.cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return _decodeGenerateResponse(
      decodeOllamaJsonObject(
        response.body,
        responseName: 'chat response',
      ),
      warnings: preparedRequest.warnings,
    );
  }

  @override
  Stream<LanguageModelStreamEvent> doStream(
      GenerateTextRequest request) async* {
    final preparedRequest = await _prepareRequest(request, stream: true);
    yield StartEvent(warnings: preparedRequest.warnings);

    try {
      final response = await transport.sendStream(
        TransportRequest(
          uri: chatUri,
          method: TransportMethod.post,
          headers: {
            ...defaultHeaders,
            'accept': 'application/x-ndjson',
            if (request.callOptions.headers case final headers?) ...headers,
          },
          body: preparedRequest.body,
          timeout: request.callOptions.timeout,
          maxRetries: request.callOptions.maxRetries,
          cancellation: request.callOptions.cancellation,
        ),
      );

      final utf8Decoder = Utf8StreamDecoder();
      final state = _OllamaStreamState();
      await for (final chunk in response.stream) {
        final decoded = utf8Decoder.decode(chunk);
        if (decoded.isEmpty) continue;
        for (final event in _decodeStreamText(
          decoded,
          state,
          includeRawChunks: request.options.includeRawChunks,
        )) {
          yield event;
        }
      }

      final remaining = utf8Decoder.flush();
      if (remaining.isNotEmpty) {
        for (final event in _decodeStreamText(
          '$remaining\n',
          state,
          includeRawChunks: request.options.includeRawChunks,
        )) {
          yield event;
        }
      }

      final pendingLine = state.buffer.toString().trim();
      if (pendingLine.isNotEmpty) {
        state.buffer.clear();
        final json = decodeOllamaJsonObject(
          pendingLine,
          responseName: 'stream chunk',
        );
        if (request.options.includeRawChunks) {
          yield RawChunkEvent(json);
        }
        for (final event in _decodeStreamJsonChunk(json, state)) {
          yield event;
        }
      }
    } catch (error) {
      yield ErrorEvent(transportErrorToModelError(error));
    }
  }

  Future<_PreparedOllamaRequest> _prepareRequest(
    GenerateTextRequest request, {
    required bool stream,
  }) async {
    if (request.prompt.isEmpty) {
      throw ArgumentError(
          'Ollama requests require at least one prompt message.');
    }

    final warnings = <ModelWarning>[];
    final providerOptions = _resolveProviderOptions(request);
    final sharedReasoning = _resolveSharedReasoning(
      request.options.reasoning,
      warnings: warnings,
    );
    final effectiveReasoning = providerOptions?.reasoning ?? sharedReasoning;
    if (providerOptions?.reasoning != null && sharedReasoning != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'options.reasoning',
          message:
              'Ollama providerOptions.reasoning overrides shared options.reasoning.',
        ),
      );
    }
    _warnUnsupportedSharedOptions(
      request.options,
      warnings: warnings,
    );
    final responseFormat = _resolveResponseFormat(
      request.options.responseFormat,
      warnings: warnings,
    );
    final tools = _resolveTools(
      request.tools,
      toolChoice: request.toolChoice,
      warnings: warnings,
    );

    final binaryResolver = _resolveBinaryResolver(providerOptions);
    final messages = <Map<String, Object?>>[];
    for (final message in request.prompt) {
      messages.addAll(
        await _encodePromptMessage(
          message,
          warnings: warnings,
          binaryResolver: binaryResolver,
        ),
      );
    }

    final options = <String, Object?>{
      if (request.options.temperature != null)
        'temperature': request.options.temperature,
      if (request.options.topP != null) 'top_p': request.options.topP,
      if (request.options.topK != null) 'top_k': request.options.topK,
      if (request.options.maxOutputTokens != null)
        'num_predict': request.options.maxOutputTokens,
      if (request.options.seed != null) 'seed': request.options.seed,
      if (request.options.stopSequences case final stopSequences?
          when stopSequences.isNotEmpty)
        'stop': stopSequences,
      if (providerOptions?.numCtx != null) 'num_ctx': providerOptions!.numCtx,
      if (providerOptions?.numGpu != null) 'num_gpu': providerOptions!.numGpu,
      if (providerOptions?.numThread != null)
        'num_thread': providerOptions!.numThread,
      if (providerOptions?.numBatch != null)
        'num_batch': providerOptions!.numBatch,
      if (providerOptions?.numa != null) 'numa': providerOptions!.numa,
    };

    return _PreparedOllamaRequest(
      body: {
        'model': modelId,
        'messages': messages,
        'stream': stream,
        if (options.isNotEmpty) 'options': options,
        if (responseFormat != null) 'format': responseFormat,
        if (tools.isNotEmpty) 'tools': tools,
        if (providerOptions?.keepAlive case final keepAlive?)
          'keep_alive': keepAlive,
        if (providerOptions?.raw case final raw?) 'raw': raw,
        if (effectiveReasoning case final reasoning?) 'think': reasoning,
      },
      warnings: warnings,
    );
  }

  bool? _resolveSharedReasoning(
    GenerateTextReasoningOptions? reasoning, {
    required List<ModelWarning> warnings,
  }) {
    if (reasoning == null) {
      return null;
    }

    if (reasoning.effort != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'options.reasoning.effort',
          message:
              'Ollama reasoning is a provider toggle; shared reasoning.effort is ignored.',
        ),
      );
    }

    if (reasoning.budgetTokens != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'options.reasoning.budgetTokens',
          message:
              'Ollama reasoning is a provider toggle; shared reasoning.budgetTokens is ignored.',
        ),
      );
    }

    return reasoning.enabled;
  }

  void _warnUnsupportedSharedOptions(
    GenerateTextOptions options, {
    required List<ModelWarning> warnings,
  }) {
    if (options.frequencyPenalty != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'options.frequencyPenalty',
          message:
              'Ollama does not support shared frequencyPenalty; use provider-native sampling options when needed.',
        ),
      );
    }

    if (options.presencePenalty != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'options.presencePenalty',
          message:
              'Ollama does not support shared presencePenalty; use provider-native sampling options when needed.',
        ),
      );
    }
  }

  OllamaGenerateTextOptions? _resolveProviderOptions(
      GenerateTextRequest request) {
    return resolveProviderInvocationOptions<OllamaGenerateTextOptions>(
      request.callOptions.providerOptions,
      parameterName: 'request.callOptions.providerOptions',
      expectedTypeName: 'OllamaGenerateTextOptions',
      usageContext: 'Ollama language models',
    );
  }

  Object? _resolveResponseFormat(
    ResponseFormat? responseFormat, {
    required List<ModelWarning> warnings,
  }) {
    return switch (responseFormat) {
      null || TextResponseFormat() => null,
      JsonResponseFormat(
        schema: final schema,
        name: final name,
        description: final description,
        strict: final strict,
      ) =>
        () {
          if (name != null || description != null || strict != null) {
            warnings.add(
              const ModelWarning(
                type: ModelWarningType.compatibility,
                field: 'options.responseFormat',
                message:
                    'Ollama only supports the shared JSON schema body. responseFormat name, description, and strict are ignored.',
              ),
            );
          }
          return schema.toJson();
        }(),
    };
  }

  List<Map<String, Object?>> _resolveTools(
    List<FunctionToolDefinition> tools, {
    required ToolChoice? toolChoice,
    required List<ModelWarning> warnings,
  }) {
    final shouldIncludeTools = switch (toolChoice) {
      NoneToolChoice() => false,
      _ => true,
    };
    if (!shouldIncludeTools) return const [];

    if (toolChoice is RequiredToolChoice || toolChoice is SpecificToolChoice) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'toolChoice',
          message:
              'Ollama does not support explicit toolChoice control. Declared tools remain available for provider-side automatic selection.',
        ),
      );
    }

    return tools
        .map(
          (tool) => {
            'type': 'function',
            'function': {
              'name': tool.name,
              if (tool.description != null) 'description': tool.description,
              'parameters': tool.inputSchema.toJson(),
            },
          },
        )
        .toList(growable: false);
  }

  OllamaBinaryResolver? _resolveBinaryResolver(
    OllamaGenerateTextOptions? providerOptions,
  ) {
    return providerOptions?.binaryResolver ?? settings.binaryResolver;
  }

  Future<List<Map<String, Object?>>> _encodePromptMessage(
    PromptMessage message, {
    required List<ModelWarning> warnings,
    required OllamaBinaryResolver? binaryResolver,
  }) async {
    return switch (message) {
      SystemPromptMessage() => [
          {
            'role': 'system',
            'content': _collectTextParts(
              message.parts,
              messageRole: 'system',
              warnings: warnings,
            ),
          },
        ],
      UserPromptMessage() => [
          await _encodeUserMessage(
            message,
            warnings: warnings,
            binaryResolver: binaryResolver,
          ),
        ],
      AssistantPromptMessage() => [_encodeAssistantMessage(message)],
      ToolPromptMessage() => _encodeToolMessage(message, warnings: warnings),
    };
  }

  Future<Map<String, Object?>> _encodeUserMessage(
    UserPromptMessage message, {
    required List<ModelWarning> warnings,
    required OllamaBinaryResolver? binaryResolver,
  }) async {
    final textParts = <String>[];
    final images = <String>[];

    for (final part in message.parts) {
      switch (part) {
        case TextPromptPart(:final text):
          textParts.add(text);
        case ImagePromptPart(
            :final mediaType,
            :final uri,
            :final bytes,
          ):
          images.add(
            base64Encode(
              await _resolveBinaryPromptBytes(
                mediaType: mediaType,
                uri: uri,
                bytes: bytes,
                binaryResolver: binaryResolver,
                promptPartKind: 'image',
              ),
            ),
          );
        case FilePromptPart(
              mediaType: final mediaType,
              filename: final filename,
              uri: final uri,
              bytes: final bytes,
            )
            when mediaType.startsWith('image/'):
          images.add(
            base64Encode(
              await _resolveBinaryPromptBytes(
                mediaType: mediaType,
                filename: filename,
                uri: uri,
                bytes: bytes,
                binaryResolver: binaryResolver,
                promptPartKind: 'image file',
              ),
            ),
          );
        case FilePromptPart():
          throw UnsupportedError(
            'Ollama only supports image multimodal file prompt parts on the current modern chat path.',
          );
        case ReasoningPromptPart(:final text):
          warnings.add(
            ModelWarning(
              type: ModelWarningType.compatibility,
              field: 'prompt',
              message:
                  'Ollama does not have a dedicated user reasoning-input field. The reasoning text has been appended to the user content.',
            ),
          );
          textParts.add(text);
        default:
          throw UnsupportedError(
            'Ollama user prompt part ${part.runtimeType} is not supported yet.',
          );
      }
    }

    return {
      'role': 'user',
      'content': textParts.join('\n'),
      if (images.isNotEmpty) 'images': images,
    };
  }

  Map<String, Object?> _encodeAssistantMessage(AssistantPromptMessage message) {
    final textParts = <String>[];
    final reasoningParts = <String>[];
    final toolCalls = <Map<String, Object?>>[];

    for (final part in message.parts) {
      switch (part) {
        case TextPromptPart(:final text):
          textParts.add(text);
        case ReasoningPromptPart(:final text):
          reasoningParts.add(text);
        case ToolCallPromptPart(
            toolName: final toolName,
            input: final input,
          ):
          toolCalls.add({
            'type': 'function',
            'function': {
              'index': toolCalls.length,
              'name': toolName,
              'arguments': _normalizeToolInput(input),
            },
          });
        default:
          throw UnsupportedError(
            'Ollama assistant prompt part ${part.runtimeType} is not supported yet.',
          );
      }
    }

    return {
      'role': 'assistant',
      'content': textParts.join('\n'),
      if (reasoningParts.isNotEmpty) 'thinking': reasoningParts.join('\n'),
      if (toolCalls.isNotEmpty) 'tool_calls': toolCalls,
    };
  }

  List<Map<String, Object?>> _encodeToolMessage(
    ToolPromptMessage message, {
    required List<ModelWarning> warnings,
  }) {
    final encodedMessages = <Map<String, Object?>>[];

    for (final part in message.parts) {
      switch (part) {
        case ToolResultPromptPart(
            toolName: final toolName,
            toolOutput: final toolOutput,
          ):
          if (toolOutput.isError) {
            _addWarningOnce(
              warnings,
              const ModelWarning(
                type: ModelWarningType.compatibility,
                field: 'prompt',
                message:
                    'Ollama does not support replaying tool error state separately. The tool result has been sent as a plain tool content message.',
              ),
            );
          }
          encodedMessages.add({
            'role': 'tool',
            'tool_name': toolName,
            'content': _stringifyToolOutput(toolOutput),
          });
        default:
          throw UnsupportedError(
            'Ollama tool prompt part ${part.runtimeType} is not supported yet.',
          );
      }
    }

    return encodedMessages;
  }

  String _collectTextParts(
    List<PromptPart> parts, {
    required String messageRole,
    required List<ModelWarning> warnings,
  }) {
    final textParts = <String>[];

    for (final part in parts) {
      switch (part) {
        case TextPromptPart(:final text):
          textParts.add(text);
        case ReasoningPromptPart(:final text):
          warnings.add(
            ModelWarning(
              type: ModelWarningType.compatibility,
              field: 'prompt',
              message:
                  'Ollama does not support replaying $messageRole reasoning as a separate prompt field. The reasoning text has been appended to the message content.',
            ),
          );
          textParts.add(text);
        default:
          throw UnsupportedError(
            'Ollama $messageRole prompt part ${part.runtimeType} is not supported yet.',
          );
      }
    }

    return textParts.join('\n');
  }

  GenerateTextResult _decodeGenerateResponse(
    Map<String, Object?> json, {
    required List<ModelWarning> warnings,
  }) {
    final content = <ContentPart>[
      ..._decodeReasoningContent(json),
      ..._decodeTextContent(json),
      ..._decodeToolCallContent(json),
    ];

    return GenerateTextResult(
      content: content,
      finishReason: _decodeFinishReason(
        json,
        hasToolCalls: content.whereType<ToolCallContentPart>().isNotEmpty,
      ),
      rawFinishReason: _asString(json['done_reason']),
      responseModelId: _asString(json['model']) ?? modelId,
      responseTimestamp: _parseTimestamp(json['created_at']),
      usage: _decodeUsage(json),
      providerMetadata: _decodeProviderMetadata(json),
      warnings: warnings,
    );
  }

  Iterable<LanguageModelStreamEvent> _decodeStreamText(
    String chunk,
    _OllamaStreamState state, {
    required bool includeRawChunks,
  }) sync* {
    state.buffer.write(chunk);
    final buffered = state.buffer.toString();
    final lines = buffered.split('\n');
    state.buffer
      ..clear()
      ..write(lines.removeLast());

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final json = decodeOllamaJsonObject(
        trimmed,
        responseName: 'stream chunk',
      );
      if (includeRawChunks) {
        yield RawChunkEvent(json);
      }
      yield* _decodeStreamJsonChunk(json, state);
    }
  }

  Iterable<LanguageModelStreamEvent> _decodeStreamJsonChunk(
    Map<String, Object?> json,
    _OllamaStreamState state,
  ) sync* {
    if (!state.metadataEmitted) {
      state.metadataEmitted = true;
      yield ResponseMetadataEvent(
        modelId: _asString(json['model']) ?? modelId,
        timestamp: _parseTimestamp(json['created_at']),
        providerMetadata: _decodeProviderMetadata(json),
      );
    }

    final message = _asObject(json['message']);
    final thinking = _asString(message?['thinking']);
    if (thinking != null && thinking.isNotEmpty) {
      if (!state.reasoningStarted) {
        state.reasoningStarted = true;
        yield const ReasoningStartEvent(id: _ollamaReasoningPartId);
      }
      yield ReasoningDeltaEvent(id: _ollamaReasoningPartId, delta: thinking);
    }

    final text = _asString(message?['content']);
    if (text != null && text.isNotEmpty) {
      if (!state.textStarted) {
        state.textStarted = true;
        yield const TextStartEvent(id: _ollamaTextPartId);
      }
      yield TextDeltaEvent(id: _ollamaTextPartId, delta: text);
    }

    final toolCalls = _decodeToolCalls(message);
    for (final toolCall in toolCalls) {
      if (!state.emittedToolCallIds.add(toolCall.toolCallId)) continue;
      yield ToolCallEvent(toolCall: toolCall);
    }

    if (json['done'] != true) return;

    if (state.reasoningStarted && !state.reasoningEnded) {
      state.reasoningEnded = true;
      yield const ReasoningEndEvent(id: _ollamaReasoningPartId);
    }

    if (state.textStarted && !state.textEnded) {
      state.textEnded = true;
      yield const TextEndEvent(id: _ollamaTextPartId);
    }

    yield FinishEvent(
      finishReason: _decodeFinishReason(
        json,
        hasToolCalls: state.emittedToolCallIds.isNotEmpty,
      ),
      rawFinishReason: _asString(json['done_reason']),
      usage: _decodeUsage(json),
      providerMetadata: _decodeProviderMetadata(json),
    );
  }

  List<ContentPart> _decodeTextContent(Map<String, Object?> json) {
    final message = _asObject(json['message']);
    final text = _asString(message?['content']) ?? _asString(json['response']);
    if (text == null || text.isEmpty) return const [];
    return [TextContentPart(text)];
  }

  List<ContentPart> _decodeReasoningContent(Map<String, Object?> json) {
    final message = _asObject(json['message']);
    final text = _asString(message?['thinking']) ?? _asString(json['thinking']);
    if (text == null || text.isEmpty) return const [];
    return [ReasoningContentPart(text)];
  }

  List<ContentPart> _decodeToolCallContent(Map<String, Object?> json) {
    final toolCalls = _decodeToolCalls(_asObject(json['message']));
    if (toolCalls.isEmpty) return const [];
    return toolCalls
        .map((toolCall) => ToolCallContentPart(toolCall))
        .toList(growable: false);
  }

  List<ToolCallContent> _decodeToolCalls(Map<String, Object?>? message) {
    final toolCalls = message?['tool_calls'];
    if (toolCalls is! List || toolCalls.isEmpty) return const [];

    return toolCalls.asMap().entries.map((entry) {
      final item = entry.value;
      if (item is! Map) {
        throw StateError(
          'Expected Ollama tool_calls[${entry.key}] to be a JSON object.',
        );
      }

      final map = Map<String, Object?>.from(item);
      final function = _asObject(map['function']);
      if (function == null) {
        throw StateError(
          'Expected Ollama tool_calls[${entry.key}] to contain a function object.',
        );
      }

      final name = _asString(function['name']);
      if (name == null || name.isEmpty) {
        throw StateError(
          'Expected Ollama tool call ${entry.key} to contain a function name.',
        );
      }

      return ToolCallContent(
        toolCallId: _asString(map['id']) ?? 'ollama-tool-${entry.key}-$name',
        toolName: name,
        input: _normalizeDecodedToolArguments(function['arguments']),
      );
    }).toList(growable: false);
  }

  UsageStats? _decodeUsage(Map<String, Object?> json) {
    final inputTokens = _asInt(json['prompt_eval_count']);
    final outputTokens = _asInt(json['eval_count']);
    final usage = UsageStats(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: switch ((inputTokens, outputTokens)) {
        (final input?, final output?) => input + output,
        _ => null,
      },
    );
    return usage.isEmpty ? null : usage;
  }

  ProviderMetadata? _decodeProviderMetadata(Map<String, Object?> json) {
    final values = <String, Object?>{
      if (json['created_at'] != null) 'createdAt': json['created_at'],
      if (json['done_reason'] != null) 'doneReason': json['done_reason'],
      if (json['total_duration'] != null)
        'totalDurationNanos': json['total_duration'],
      if (json['load_duration'] != null)
        'loadDurationNanos': json['load_duration'],
      if (json['prompt_eval_duration'] != null)
        'promptEvalDurationNanos': json['prompt_eval_duration'],
      if (json['eval_duration'] != null)
        'evalDurationNanos': json['eval_duration'],
    };
    if (values.isEmpty) return null;
    return ProviderMetadata.forNamespace('ollama', values);
  }

  FinishReason _decodeFinishReason(
    Map<String, Object?> json, {
    required bool hasToolCalls,
  }) {
    if (hasToolCalls) return FinishReason.toolCalls;
    return switch (_asString(json['done_reason'])) {
      'stop' || null => FinishReason.stop,
      'length' => FinishReason.maxTokens,
      'abort' => FinishReason.aborted,
      'error' => FinishReason.error,
      _ => FinishReason.other,
    };
  }
}

const _ollamaTextPartId = 'ollama-text';
const _ollamaReasoningPartId = 'ollama-reasoning';

final class _PreparedOllamaRequest {
  final Map<String, Object?> body;
  final List<ModelWarning> warnings;

  _PreparedOllamaRequest({
    required Map<String, Object?> body,
    List<ModelWarning> warnings = const [],
  })  : body = Map.unmodifiable(body),
        warnings = List.unmodifiable(warnings);
}

final class _OllamaStreamState {
  final StringBuffer buffer = StringBuffer();
  final Set<String> emittedToolCallIds = <String>{};
  bool metadataEmitted = false;
  bool textStarted = false;
  bool textEnded = false;
  bool reasoningStarted = false;
  bool reasoningEnded = false;
}

Map<String, Object?>? _asObject(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  return null;
}

String? _asString(Object? value) => value is String ? value : null;

int? _asInt(Object? value) => value is num ? value.toInt() : null;

DateTime? _parseTimestamp(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

void _addWarningOnce(List<ModelWarning> warnings, ModelWarning warning) {
  if (warnings.contains(warning)) return;
  warnings.add(warning);
}

Object? _normalizeToolInput(Object? input) {
  return switch (input) {
    null || bool() || num() || String() || List() || Map() => input,
    _ => jsonDecode(jsonEncode(input)),
  };
}

Object? _normalizeDecodedToolArguments(Object? arguments) {
  if (arguments is String) {
    final trimmed = arguments.trim();
    if (trimmed.isEmpty) return null;
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return arguments;
    }
  }
  if (arguments is Map) return Map<String, Object?>.from(arguments);
  if (arguments is List) return List<Object?>.from(arguments);
  return arguments;
}

String _stringifyToolOutput(ToolOutput output) {
  if (output is ExecutionDeniedToolOutput) {
    return output.reason ?? 'Tool execution denied';
  }

  if (output is ContentToolOutput) {
    return jsonEncode(projectToolOutputContentPartsToJson(output.parts));
  }

  final value = output.value;
  if (value == null) {
    return output.isError ? 'Tool execution failed' : '';
  }

  return value is String ? value : jsonEncode(normalizeJsonValue(value));
}

Future<List<int>> _resolveBinaryPromptBytes({
  required String mediaType,
  required Uri? uri,
  required List<int>? bytes,
  required OllamaBinaryResolver? binaryResolver,
  required String promptPartKind,
  String? filename,
}) async {
  if (bytes != null && bytes.isNotEmpty) {
    return bytes;
  }

  if (uri == null) {
    throw UnsupportedError(
      'Ollama $promptPartKind prompt parts require bytes, a data URI, or a configured OllamaBinaryResolver.',
    );
  }

  final uriData = uri.data;
  if (uriData != null) {
    final resolved = uriData.contentAsBytes();
    if (resolved.isNotEmpty) {
      return resolved;
    }
  }

  final resolver = binaryResolver;
  if (resolver != null) {
    final resolved = await resolver(
      uri,
      mediaType: mediaType,
      filename: filename,
    );
    if (resolved != null && resolved.isNotEmpty) {
      return resolved;
    }
  }

  throw UnsupportedError(
    'Ollama $promptPartKind prompt parts cannot encode URI $uri without bytes, a data URI, or a configured OllamaBinaryResolver.',
  );
}
