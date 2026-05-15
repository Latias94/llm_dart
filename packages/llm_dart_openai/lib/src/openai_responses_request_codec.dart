import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_model_capabilities.dart';
import 'openai_native_tools.dart';
import 'openai_options.dart';
import 'openai_response_format.dart';
import 'openai_tool_output_encoding.dart';

final class OpenAIResponsesRequest {
  final Map<String, Object?> body;
  final List<ModelWarning> warnings;

  OpenAIResponsesRequest({
    required Map<String, Object?> body,
    List<ModelWarning> warnings = const [],
  })  : body = Map.unmodifiable(body),
        warnings = List.unmodifiable(warnings);
}

final class OpenAIResponsesRequestCodec {
  const OpenAIResponsesRequestCodec();

  OpenAIResponsesRequest encodeRequest({
    required String modelId,
    required List<PromptMessage> prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required GenerateTextOptions options,
    required OpenAIGenerateTextOptions providerOptions,
    required bool stream,
  }) {
    final warnings = <ModelWarning>[];
    final input = <Object?>[];
    final capabilities = getOpenAIModelCapabilities(modelId);
    final isReasoningModel =
        providerOptions.forceReasoning ?? capabilities.isReasoningModel;
    final store = providerOptions.store ?? true;
    final hasConversation = providerOptions.conversation != null;
    final systemMessageMode = providerOptions.systemMessageMode ??
        (isReasoningModel
            ? OpenAISystemMessageMode.developer
            : capabilities.systemMessageMode);

    if (hasConversation && providerOptions.previousResponseId != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'conversation',
          message:
              'conversation and previousResponseId cannot be used together',
        ),
      );
    }

    for (final message in prompt) {
      input.addAll(
        _encodePromptMessage(
          message,
          warnings,
          systemMessageMode: systemMessageMode,
          store: store,
          hasConversation: hasConversation,
        ),
      );
    }

    final include = _resolveInclude(
      providerOptions,
      isReasoningModel: isReasoningModel,
      store: store,
    );
    final topLogProbs = _encodeResponsesTopLogProbs(providerOptions.logprobs);
    final sharedReasoningEffort = mapSharedOpenAIReasoningEffort(
      options.reasoning,
      warnings: warnings,
    );
    final effectiveReasoningEffort =
        providerOptions.reasoningEffort ?? sharedReasoningEffort;
    if (providerOptions.reasoningEffort != null &&
        sharedReasoningEffort != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'options.reasoning',
          message:
              'OpenAI providerOptions.reasoningEffort overrides shared options.reasoning.',
        ),
      );
    }
    _warnUnsupportedResponsesSharedOptions(
      options,
      warnings: warnings,
    );

    final body = <String, Object?>{
      'model': modelId,
      'input': input,
      'stream': stream,
      if (options.maxOutputTokens != null)
        'max_output_tokens': options.maxOutputTokens,
      if (options.temperature != null) 'temperature': options.temperature,
      if (options.stopSequences != null && options.stopSequences!.isNotEmpty)
        'stop': options.stopSequences,
      if (options.topP != null) 'top_p': options.topP,
      if (options.topK != null) 'top_k': options.topK,
      if (providerOptions.previousResponseId != null)
        'previous_response_id': providerOptions.previousResponseId,
      if (providerOptions.conversation != null)
        'conversation': providerOptions.conversation,
      if (providerOptions.store != null) 'store': providerOptions.store,
      if (providerOptions.parallelToolCalls != null)
        'parallel_tool_calls': providerOptions.parallelToolCalls,
      if (providerOptions.serviceTier != null)
        'service_tier': providerOptions.serviceTier,
      if (providerOptions.instructions != null)
        'instructions': providerOptions.instructions,
      if (providerOptions.maxToolCalls != null)
        'max_tool_calls': providerOptions.maxToolCalls,
      if (providerOptions.metadata != null)
        'metadata': providerOptions.metadata,
      if (providerOptions.truncation != null)
        'truncation': providerOptions.truncation!.value,
      if (providerOptions.user != null) 'user': providerOptions.user,
      if (include != null) 'include': include,
      if (providerOptions.promptCacheKey != null)
        'prompt_cache_key': providerOptions.promptCacheKey,
      if (providerOptions.promptCacheRetention != null)
        'prompt_cache_retention': providerOptions.promptCacheRetention!.value,
      if (providerOptions.safetyIdentifier != null)
        'safety_identifier': providerOptions.safetyIdentifier,
      if (topLogProbs != null) 'top_logprobs': topLogProbs,
      if (isReasoningModel && effectiveReasoningEffort != null)
        'reasoning': <String, Object?>{
          'effort': effectiveReasoningEffort.value,
        },
    };

    _applyOpenAIReasoningCompatibility(
      reasoningEffort: effectiveReasoningEffort,
      body: body,
      warnings: warnings,
      isReasoningModel: isReasoningModel,
      capabilities: capabilities,
    );
    _applyOpenAIServiceTierCompatibility(
      body: body,
      warnings: warnings,
      capabilities: capabilities,
    );

    final encodedTools = _encodeTools(
      tools: tools,
      builtInTools: providerOptions.builtInTools,
    );
    if (encodedTools.isNotEmpty) {
      body['tools'] = encodedTools;
      final encodedToolChoice = _encodeToolChoice(
        toolChoice,
        hasFunctionTools: tools.isNotEmpty,
      );
      if (encodedToolChoice != null) {
        body['tool_choice'] = encodedToolChoice;
      }
    }

    if (providerOptions.verbosity != null) {
      body['text'] = <String, Object?>{
        'verbosity': providerOptions.verbosity,
      };
    }

    if (providerOptions.responseFormat case final responseFormat?) {
      body['response_format'] = _encodeResponseFormat(responseFormat);
    }

    return OpenAIResponsesRequest(
      body: body,
      warnings: warnings,
    );
  }

  List<Object?> _encodePromptMessage(
    PromptMessage message,
    List<ModelWarning> warnings, {
    required OpenAISystemMessageMode systemMessageMode,
    required bool store,
    required bool hasConversation,
  }) {
    if (message is SystemPromptMessage) {
      if (systemMessageMode == OpenAISystemMessageMode.remove) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.other,
            field: 'prompt.system',
            message: 'system messages are removed for this model',
          ),
        );
        return const [];
      }

      return [
        {
          'role': systemMessageMode.value,
          'content': _joinTextParts(
            role: 'system',
            parts: message.parts,
          ),
        },
      ];
    }

    if (message is UserPromptMessage) {
      return [
        {
          'role': 'user',
          'content': [
            for (var index = 0; index < message.parts.length; index++)
              _encodeUserPart(message.parts[index], index: index),
          ],
        },
      ];
    }

    if (message is AssistantPromptMessage) {
      return _encodeAssistantMessage(
        message,
        warnings,
        store: store,
        hasConversation: hasConversation,
      );
    }

    if (message is ToolPromptMessage) {
      return _encodeToolMessage(
        message,
        store: store,
      );
    }

    throw UnsupportedError(
      'Unsupported prompt message type: ${message.runtimeType}',
    );
  }

  List<Object?> _encodeAssistantMessage(
    AssistantPromptMessage message,
    List<ModelWarning> warnings, {
    required bool store,
    required bool hasConversation,
  }) {
    final items = <Object?>[];
    final textContent = <Object?>[];
    final reasoningItemsById = <String, Map<String, Object?>>{};
    final referencedReasoningIds = <String>{};
    String? textItemId;
    String? textPhase;

    void flushTextContent() {
      if (textContent.isEmpty) {
        return;
      }

      items.add({
        'role': 'assistant',
        'content': List<Object?>.from(textContent),
        if (textItemId != null) 'id': textItemId,
        if (textPhase != null) 'phase': textPhase,
      });
      textContent.clear();
      textItemId = null;
      textPhase = null;
    }

    for (final part in message.parts) {
      if (part is TextPromptPart) {
        final metadata = _promptPartProviderMetadata(part)?.namespace('openai');
        final partItemId = _asString(metadata?['itemId']);
        final partPhase = _asString(metadata?['phase']);

        if (hasConversation && partItemId != null) {
          flushTextContent();
          continue;
        }

        if (store && partItemId != null) {
          flushTextContent();
          items.add(_encodeItemReference(partItemId));
          continue;
        }

        if (textContent.isNotEmpty &&
            (partItemId != textItemId || partPhase != textPhase)) {
          flushTextContent();
        }

        if (textContent.isEmpty) {
          textItemId = partItemId;
          textPhase = partPhase;
        }

        textContent.add({
          'type': 'output_text',
          'text': part.text,
        });
        continue;
      }

      if (part is ReasoningPromptPart) {
        flushTextContent();

        final metadata = _promptPartProviderMetadata(part)?.namespace('openai');
        final reasoningId = _asString(metadata?['itemId']);
        final encryptedContent =
            _asString(metadata?['reasoningEncryptedContent']) ??
                _asString(metadata?['encryptedContent']);
        final summaryPart = part.text.isEmpty
            ? null
            : <String, Object?>{
                'type': 'summary_text',
                'text': part.text,
              };

        if (hasConversation && reasoningId != null) {
          continue;
        }

        if (store && reasoningId != null) {
          if (referencedReasoningIds.add(reasoningId)) {
            items.add(_encodeItemReference(reasoningId));
          }
          continue;
        }

        if (reasoningId != null) {
          final existingItem = reasoningItemsById[reasoningId];
          if (existingItem == null) {
            final reasoningItem = <String, Object?>{
              'type': 'reasoning',
              'id': reasoningId,
              if (encryptedContent != null)
                'encrypted_content': encryptedContent,
              'summary': <Object?>[
                if (summaryPart != null) summaryPart,
              ],
            };
            reasoningItemsById[reasoningId] = reasoningItem;
            items.add(reasoningItem);
          } else {
            final summary = existingItem['summary'];
            if (summaryPart != null && summary is List<Object?>) {
              summary.add(summaryPart);
            } else if (summaryPart == null) {
              warnings.add(
                ModelWarning(
                  type: ModelWarningType.other,
                  field: 'prompt.assistant.reasoning',
                  message:
                      'Cannot append empty reasoning part to existing reasoning sequence. Skipping reasoning part with itemId "$reasoningId".',
                ),
              );
            }
            if (encryptedContent != null) {
              existingItem['encrypted_content'] = encryptedContent;
            }
          }
          continue;
        }

        if (encryptedContent == null) {
          warnings.add(
            const ModelWarning(
              type: ModelWarningType.other,
              field: 'prompt.assistant.reasoning',
              message:
                  'Non-OpenAI reasoning parts without itemId or encryptedContent are not sent to the OpenAI Responses API',
            ),
          );
          continue;
        }

        items.add({
          'type': 'reasoning',
          'encrypted_content': encryptedContent,
          'summary': <Object?>[
            if (summaryPart != null) summaryPart,
          ],
        });
        continue;
      }

      flushTextContent();

      if (part is ToolCallPromptPart) {
        final metadata = _promptPartProviderMetadata(part)?.namespace('openai');
        final itemId = _asString(metadata?['itemId']);

        if (hasConversation && itemId != null) {
          continue;
        }

        if (store && itemId != null) {
          items.add(_encodeItemReference(itemId));
          continue;
        }

        if (part.providerExecuted) {
          continue;
        }

        items.add({
          'type': 'function_call',
          'call_id': part.toolCallId,
          if (itemId != null) 'id': itemId,
          'name': part.toolName,
          'arguments': _encodeJsonString(part.input),
        });
        continue;
      }

      if (part is ToolApprovalRequestPromptPart) {
        continue;
      }

      if (part is FilePromptPart ||
          part is ReasoningFilePromptPart ||
          part is CustomPromptPart) {
        if (part is CustomPromptPart && part.kind == 'openai.compaction') {
          final compactionItem = _encodeOpenAICompactionItem(
            part,
            store: store,
            hasConversation: hasConversation,
          );
          if (compactionItem != null) {
            items.add(compactionItem);
          }
        }
        continue;
      }

      if (part is ToolResultPromptPart) {
        if (hasConversation) {
          continue;
        }

        final metadata = _promptPartProviderMetadata(part)?.namespace('openai');
        final itemId = _asString(metadata?['itemId']) ?? part.toolCallId;

        if (store) {
          items.add(_encodeItemReference(itemId));
          continue;
        }

        warnings.add(
          ModelWarning(
            type: ModelWarningType.other,
            field: 'prompt.assistant.toolResult',
            message:
                'Results for OpenAI tool ${part.toolName} are not sent to the API when store is false',
          ),
        );
        continue;
      }

      throw UnsupportedError(
        'Assistant prompt part ${part.runtimeType} is not supported by the migrated Responses codec yet.',
      );
    }

    flushTextContent();
    if (!store) {
      var removedUnsupportedReasoning = false;
      items.removeWhere((item) {
        final map = _asMap(item);
        final shouldRemove = map != null &&
            _asString(map['type']) == 'reasoning' &&
            !map.containsKey('encrypted_content');
        if (shouldRemove) {
          removedUnsupportedReasoning = true;
        }
        return shouldRemove;
      });

      if (removedUnsupportedReasoning) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.other,
            field: 'prompt.assistant.reasoning',
            message:
                'Reasoning parts without encrypted content are not supported when store is false. Skipping reasoning parts.',
          ),
        );
      }
    }
    return items;
  }

  List<Object?> _encodeToolMessage(
    ToolPromptMessage message, {
    required bool store,
  }) {
    final items = <Object?>[];

    for (final part in message.parts) {
      if (part is ToolApprovalResponsePromptPart) {
        if (store) {
          items.add(_encodeItemReference(part.approvalId));
        }
        items.add({
          'type': 'mcp_approval_response',
          'approval_request_id': part.approvalId,
          'approve': part.approved,
        });
        continue;
      }

      if (part is! ToolResultPromptPart) {
        throw UnsupportedError(
          'Tool prompt part ${part.runtimeType} is not supported by the migrated Responses codec yet.',
        );
      }

      items.add({
        'type': 'function_call_output',
        'call_id': part.toolCallId,
        'output': _encodeToolOutput(part.toolOutput),
      });
    }

    return items;
  }

  Object _encodeUserPart(
    PromptPart part, {
    required int index,
  }) {
    if (part is TextPromptPart) {
      return {
        'type': 'input_text',
        'text': part.text,
      };
    }

    if (part is ImagePromptPart) {
      final imageDetail = _openAIImageDetail(
        part.providerOptions,
        path: 'user.image.providerOptions',
      );
      if (_openAIFileId(
        data: part.data,
      )
          case final fileId?) {
        return {
          'type': 'input_image',
          'file_id': fileId,
          if (imageDetail != null) 'detail': imageDetail,
        };
      }

      final imageUrl = part.uri?.toString() ??
          (part.bytes == null
              ? null
              : 'data:${_normalizeImageMediaTypeForDataUrl(part.mediaType)};base64,'
                  '${base64Encode(part.bytes!)}');
      if (imageUrl == null) {
        throw UnsupportedError(
          'User image prompt parts need either a URI or bytes.',
        );
      }

      return {
        'type': 'input_image',
        'image_url': imageUrl,
        if (imageDetail != null) 'detail': imageDetail,
      };
    }

    if (part is FilePromptPart) {
      if (part.mediaType.startsWith('image/')) {
        final imageDetail = _openAIImageDetail(
          part.providerOptions,
          path: 'user.file.providerOptions',
        );
        if (_openAIFileId(
          data: part.data,
        )
            case final fileId?) {
          return {
            'type': 'input_image',
            'file_id': fileId,
            if (imageDetail != null) 'detail': imageDetail,
          };
        }

        final imageUrl = part.uri?.toString() ??
            (part.bytes == null
                ? null
                : 'data:${_normalizeImageMediaTypeForDataUrl(part.mediaType)};base64,'
                    '${base64Encode(part.bytes!)}');
        if (imageUrl == null) {
          throw UnsupportedError(
            'User image file prompt parts need either a URI or bytes.',
          );
        }

        return {
          'type': 'input_image',
          'image_url': imageUrl,
          if (imageDetail != null) 'detail': imageDetail,
        };
      }

      if (part.mediaType == 'application/pdf') {
        if (_openAIFileId(
          data: part.data,
        )
            case final fileId?) {
          return {
            'type': 'input_file',
            'file_id': fileId,
          };
        }

        if (part.uri != null) {
          return {
            'type': 'input_file',
            'file_url': part.uri!.toString(),
          };
        }

        if (part.bytes == null) {
          throw UnsupportedError(
            'User PDF file prompt parts need bytes, a URI, or an OpenAI provider reference on the migrated Responses path.',
          );
        }

        return {
          'type': 'input_file',
          'filename': part.filename ?? 'part-$index.pdf',
          'file_data':
              'data:application/pdf;base64,${base64Encode(part.bytes!)}',
        };
      }

      if (part.uri != null) {
        throw UnsupportedError(
          'User file prompt parts need bytes on the migrated OpenAI Responses path.',
        );
      }

      if (part.bytes == null) {
        throw UnsupportedError(
          'User file prompt parts need bytes on the migrated OpenAI Responses path.',
        );
      }

      return {
        'type': 'input_file',
        'file_data': base64Encode(part.bytes!),
      };
    }

    throw UnsupportedError(
      'User prompt part ${part.runtimeType} is not supported by the migrated Responses codec yet.',
    );
  }

  String _joinTextParts({
    required String role,
    required List<PromptPart> parts,
  }) {
    final buffer = <String>[];

    for (final part in parts) {
      if (part is! TextPromptPart) {
        throw UnsupportedError(
          '$role prompt part ${part.runtimeType} is not supported by the migrated Responses codec yet.',
        );
      }

      buffer.add(part.text);
    }

    return buffer.join('\n\n');
  }

  void _warnUnsupportedResponsesSharedOptions(
    GenerateTextOptions options, {
    required List<ModelWarning> warnings,
  }) {
    if (options.frequencyPenalty != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'options.frequencyPenalty',
          message:
              'OpenAI Responses does not support shared frequencyPenalty; use Chat Completions-compatible models when this knob is required.',
        ),
      );
    }

    if (options.presencePenalty != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'options.presencePenalty',
          message:
              'OpenAI Responses does not support shared presencePenalty; use Chat Completions-compatible models when this knob is required.',
        ),
      );
    }

    if (options.seed != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'options.seed',
          message:
              'OpenAI Responses does not support shared seed; use Chat Completions-compatible models when deterministic sampling is required.',
        ),
      );
    }
  }

  void _applyOpenAIReasoningCompatibility({
    required OpenAIReasoningEffort? reasoningEffort,
    required Map<String, Object?> body,
    required List<ModelWarning> warnings,
    required bool isReasoningModel,
    required OpenAIModelCapabilities capabilities,
  }) {
    if (isReasoningModel) {
      final supportsNonReasoningParameters =
          reasoningEffort == OpenAIReasoningEffort.none &&
              capabilities.supportsNonReasoningParameters;

      if (!supportsNonReasoningParameters) {
        _removeBodyFieldWithWarning(
          body,
          'temperature',
          warnings,
          warning: const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'temperature',
            message: 'temperature is not supported for reasoning models',
          ),
        );
        _removeBodyFieldWithWarning(
          body,
          'top_p',
          warnings,
          warning: const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'topP',
            message: 'topP is not supported for reasoning models',
          ),
        );
      }

      return;
    }

    if (reasoningEffort != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'reasoningEffort',
          message: 'reasoningEffort is not supported for non-reasoning models',
        ),
      );
    }
  }

  void _applyOpenAIServiceTierCompatibility({
    required Map<String, Object?> body,
    required List<ModelWarning> warnings,
    required OpenAIModelCapabilities capabilities,
  }) {
    final serviceTier = body['service_tier'];
    if (serviceTier == 'flex' && !capabilities.supportsFlexProcessing) {
      body.remove('service_tier');
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'serviceTier',
          message:
              'flex processing is only available for o3, o4-mini, and gpt-5 models',
        ),
      );
    }

    if (serviceTier == 'priority' && !capabilities.supportsPriorityProcessing) {
      body.remove('service_tier');
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'serviceTier',
          message:
              'priority processing is only available for supported models (gpt-4, gpt-5, gpt-5-mini, o3, o4-mini) and requires Enterprise access. gpt-5-nano is not supported',
        ),
      );
    }
  }

  void _removeBodyFieldWithWarning(
    Map<String, Object?> body,
    String key,
    List<ModelWarning> warnings, {
    required ModelWarning warning,
  }) {
    if (!body.containsKey(key)) {
      return;
    }

    body.remove(key);
    warnings.add(warning);
  }

  List<String>? _resolveInclude(
    OpenAIGenerateTextOptions providerOptions, {
    required bool isReasoningModel,
    required bool store,
  }) {
    final values = <String>{};

    if (providerOptions.include case final include?) {
      for (final item in include) {
        values.add(item.value);
      }
    }

    if (providerOptions.logprobs != null) {
      values.add(OpenAIResponsesInclude.messageOutputTextLogprobs.value);
    }

    if (!store && isReasoningModel) {
      values.add(OpenAIResponsesInclude.reasoningEncryptedContent.value);
    }

    if (values.isEmpty) {
      return null;
    }

    return values.toList(growable: false);
  }

  int? _encodeResponsesTopLogProbs(OpenAILogProbs? logprobs) {
    if (logprobs == null) {
      return null;
    }

    return logprobs.topLogProbs ?? OpenAILogProbs.responsesMaxTopLogProbs;
  }

  Map<String, Object?>? _encodeOpenAICompactionItem(
    CustomPromptPart part, {
    required bool store,
    required bool hasConversation,
  }) {
    final data = part.data is Map
        ? Map<String, Object?>.from(part.data as Map)
        : const <String, Object?>{};
    final metadata = _promptPartProviderMetadata(part)?.namespace('openai');
    final id = _asString(metadata?['itemId']) ?? _asString(data['id']);
    final encryptedContent = _asString(metadata?['encryptedContent']) ??
        _asString(data['encrypted_content']) ??
        _asString(data['encryptedContent']);

    if (hasConversation && id != null) {
      return null;
    }

    if (store && id != null) {
      return _encodeItemReference(id);
    }

    if (id == null || encryptedContent == null) {
      return null;
    }

    final item = <String, Object?>{
      'type': 'compaction',
      'id': id,
      'encrypted_content': encryptedContent,
    };

    for (final entry in data.entries) {
      if (entry.key == 'type' ||
          entry.key == 'id' ||
          entry.key == 'encrypted_content' ||
          entry.key == 'encryptedContent') {
        continue;
      }
      item[entry.key] = entry.value;
    }

    return item;
  }

  Map<String, Object?> _encodeItemReference(String id) {
    return {
      'type': 'item_reference',
      'id': id,
    };
  }

  ProviderMetadata? _promptPartProviderMetadata(PromptPart part) {
    return mergeProviderReplayMetadata(
      providerOptions: part.providerOptions,
    );
  }

  String? _openAIImageDetail(
    ProviderPromptPartOptions? providerOptions, {
    required String path,
  }) {
    final options = resolveProviderPromptPartOptions<OpenAIPromptPartOptions>(
      providerOptions,
      parameterName: path,
      expectedTypeName: 'OpenAIPromptPartOptions',
      usageContext: 'OpenAI-family image prompt parts',
    );
    return options?.imageDetail;
  }

  String _encodeJsonString(Object? value) {
    if (value == null) {
      return '{}';
    }

    if (value is String) {
      return value;
    }

    return jsonEncode(value);
  }

  List<Map<String, Object?>> _encodeTools({
    required List<FunctionToolDefinition> tools,
    required List<OpenAIBuiltInTool>? builtInTools,
  }) {
    final encoded = <Map<String, Object?>>[
      for (final tool in tools)
        {
          'type': 'function',
          'name': tool.name,
          if (tool.description != null) 'description': tool.description,
          'parameters': tool.inputSchema.toJson(),
          if (tool.strict != null) 'strict': tool.strict,
        },
    ];

    if (builtInTools != null) {
      encoded.addAll(
        builtInTools.map((tool) => tool.toJson()),
      );
    }

    return encoded;
  }

  Map<String, Object?>? _encodeToolChoice(
    ToolChoice? toolChoice, {
    required bool hasFunctionTools,
  }) {
    if (!hasFunctionTools || toolChoice == null) {
      return null;
    }

    return switch (toolChoice) {
      AutoToolChoice() => const {'type': 'auto'},
      RequiredToolChoice() => const {'type': 'required'},
      NoneToolChoice() => const {'type': 'none'},
      SpecificToolChoice(toolName: final toolName) => {
          'type': 'function',
          'function': {
            'name': toolName,
          },
        },
    };
  }

  Map<String, Object?> _encodeResponseFormat(
    OpenAIJsonSchemaResponseFormat responseFormat,
  ) {
    return {
      'type': 'json_schema',
      'json_schema': {
        'name': responseFormat.name,
        if (responseFormat.description != null)
          'description': responseFormat.description,
        if (responseFormat.schema != null)
          'schema': _ensureOpenAIJsonSchemaObject(responseFormat.schema!),
        if (responseFormat.strict != null) 'strict': responseFormat.strict,
      },
    };
  }

  Map<String, Object?> _ensureOpenAIJsonSchemaObject(
    Map<String, Object?> schema,
  ) {
    final normalized = Map<String, Object?>.from(schema);
    if (!normalized.containsKey('additionalProperties')) {
      normalized['additionalProperties'] = false;
    }
    return normalized;
  }

  Object? _encodeToolOutput(ToolOutput output) {
    if (output is ContentToolOutput) {
      return _encodeContentToolOutput(output.parts);
    }

    return encodeOpenAIToolOutputAsText(output);
  }

  List<Object?> _encodeContentToolOutput(List<ToolOutputContentPart> parts) {
    return [
      for (final part in parts) _encodeContentToolOutputPart(part),
    ];
  }

  Object _encodeContentToolOutputPart(ToolOutputContentPart part) {
    return switch (part) {
      TextToolOutputContentPart(:final text) => {
          'type': 'input_text',
          'text': text,
        },
      JsonToolOutputContentPart(:final value) => {
          'type': 'input_text',
          'text': jsonEncode(normalizeJsonValue(value)),
        },
      FileToolOutputContentPart(
        :final mediaType,
        :final filename,
        :final data,
        :final providerOptions,
      ) =>
        _encodeContentToolOutputFilePart(
          mediaType: mediaType,
          filename: filename,
          data: data,
          providerOptions: providerOptions,
        ),
      CustomToolOutputContentPart(:final kind, :final data) => {
          'type': 'input_text',
          'text': jsonEncode(
            normalizeJsonValue({
              'type': 'custom',
              'kind': kind,
              if (data != null) 'data': data,
            }),
          ),
        },
    };
  }

  Map<String, Object?> _encodeContentToolOutputFilePart({
    required String mediaType,
    required String? filename,
    required FileData data,
    required ProviderPromptPartOptions? providerOptions,
  }) {
    final imageDetail = _openAIImageDetail(
      providerOptions,
      path: 'toolOutput.file.providerOptions',
    );
    final isImage = mediaType == 'image/*' || mediaType.startsWith('image/');
    final reference = data.providerReference;

    if (reference?.containsProvider('openai') == true) {
      final fileId = reference!.requireProvider(
        'openai',
        context: 'OpenAI Responses tool output file part',
      );
      return {
        'type': isImage ? 'input_image' : 'input_file',
        'file_id': fileId,
        if (isImage && imageDetail != null) 'detail': imageDetail,
      };
    }

    final uri = data.uri;
    if (uri != null) {
      return {
        'type': isImage ? 'input_image' : 'input_file',
        if (isImage)
          'image_url': uri.toString()
        else
          'file_url': uri.toString(),
        if (isImage && imageDetail != null) 'detail': imageDetail,
      };
    }

    final bytes = data.bytes;
    if (bytes != null) {
      final normalizedMediaType =
          isImage ? _normalizeImageMediaTypeForDataUrl(mediaType) : mediaType;
      return {
        'type': isImage ? 'input_image' : 'input_file',
        if (isImage)
          'image_url': 'data:$normalizedMediaType;base64,${base64Encode(bytes)}'
        else
          'filename': filename ?? 'data',
        if (!isImage)
          'file_data':
              'data:$normalizedMediaType;base64,${base64Encode(bytes)}',
        if (isImage && imageDetail != null) 'detail': imageDetail,
      };
    }

    final text = data.text;
    if (text != null) {
      if (isImage) {
        throw UnsupportedError(
          'OpenAI Responses tool output image parts require in-memory bytes, a URI, or an OpenAI provider reference.',
        );
      }

      final normalizedMediaType = _normalizeImageMediaTypeForDataUrl(mediaType);
      final encodedText = base64Encode(utf8.encode(text));
      return {
        'type': 'input_file',
        'filename': filename ?? 'data',
        'file_data': 'data:$normalizedMediaType;base64,$encodedText',
      };
    }

    throw UnsupportedError(
      'OpenAI Responses tool output file part requires in-memory bytes, text, a URI, or an OpenAI provider reference.',
    );
  }

  String? _openAIFileId({
    required FileData data,
  }) {
    return data.providerReference?.requireProvider(
      'openai',
      context: 'OpenAI file prompt part',
    );
  }

  Map<String, Object?>? _asMap(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }

    if (value is Map) {
      return Map<String, Object?>.from(value);
    }

    return null;
  }

  String? _asString(Object? value) {
    return value is String ? value : null;
  }

  String _normalizeImageMediaTypeForDataUrl(String mediaType) {
    if (mediaType == 'image/*') {
      return 'image/jpeg';
    }

    return mediaType;
  }
}
