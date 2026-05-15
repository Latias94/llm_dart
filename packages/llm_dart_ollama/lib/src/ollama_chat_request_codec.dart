import 'dart:async';
import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'ollama_options.dart';
import 'ollama_tool_codec.dart';

final class OllamaPreparedChatRequest {
  final Map<String, Object?> body;
  final List<ModelWarning> warnings;

  OllamaPreparedChatRequest({
    required Map<String, Object?> body,
    List<ModelWarning> warnings = const [],
  })  : body = Map.unmodifiable(body),
        warnings = List.unmodifiable(warnings);
}

final class OllamaChatRequestCodec {
  final String modelId;
  final OllamaChatModelSettings settings;
  final OllamaToolCodec toolCodec;

  const OllamaChatRequestCodec({
    required this.modelId,
    required this.settings,
    this.toolCodec = const OllamaToolCodec(),
  });

  Future<OllamaPreparedChatRequest> encode({
    required GenerateTextRequest request,
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
    final tools = toolCodec.encodeToolDefinitions(
      tools: request.tools,
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

    return OllamaPreparedChatRequest(
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
          toolCalls.add(
            toolCodec.encodeAssistantToolCall(
              index: toolCalls.length,
              toolName: toolName,
              input: input,
            ),
          );
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
            'content': toolCodec.stringifyToolOutput(toolOutput),
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

  void _addWarningOnce(List<ModelWarning> warnings, ModelWarning warning) {
    if (warnings.contains(warning)) return;
    warnings.add(warning);
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
}
