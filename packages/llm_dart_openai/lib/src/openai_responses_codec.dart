import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'openai_options.dart';

final class OpenAIResponsesRequest {
  final Map<String, Object?> body;
  final List<ModelWarning> warnings;

  OpenAIResponsesRequest({
    required Map<String, Object?> body,
    List<ModelWarning> warnings = const [],
  })  : body = Map.unmodifiable(body),
        warnings = List.unmodifiable(warnings);
}

final class OpenAIResponsesStreamState {
  final Map<int, _OpenAIToolCallState> _toolCallsByIndex = {};
  final Set<String> startedTextIds = {};
  final Set<String> endedTextIds = {};
  final Set<String> startedReasoningIds = {};
  final Set<String> endedReasoningIds = {};

  String? responseId;
  String? serviceTier;
  String? rawFinishReason;
  UsageStats? usage;
  bool hasToolCalls = false;
  bool hasResponseMetadata = false;
}

final class OpenAIResponsesCodec {
  const OpenAIResponsesCodec();

  OpenAIResponsesRequest encodeRequest({
    required String modelId,
    required List<PromptMessage> prompt,
    required GenerateTextOptions options,
    required OpenAIGenerateTextOptions providerOptions,
    required bool stream,
  }) {
    final input = <Object?>[];

    for (final message in prompt) {
      input.addAll(_encodePromptMessage(message));
    }

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
      if (providerOptions.parallelToolCalls != null)
        'parallel_tool_calls': providerOptions.parallelToolCalls,
      if (providerOptions.serviceTier != null)
        'service_tier': providerOptions.serviceTier,
    };

    if (providerOptions.verbosity != null) {
      body['text'] = <String, Object?>{
        'verbosity': providerOptions.verbosity,
      };
    }

    return OpenAIResponsesRequest(body: body);
  }

  GenerateTextResult decodeGenerateResponse(
    Map<String, Object?> response, {
    List<ModelWarning> warnings = const [],
  }) {
    _throwIfError(response);

    final content = <ContentPart>[];
    var hasToolCalls = false;

    for (final item in _outputItems(response)) {
      final type = _asString(item['type']);
      if (type == 'message') {
        content.addAll(_decodeMessageOutput(item));
        continue;
      }

      if (type == 'reasoning') {
        content.addAll(_decodeReasoningOutput(item));
        continue;
      }

      if (type == 'function_call') {
        hasToolCalls = true;
        final toolCall = _decodeFunctionCallOutput(item);
        if (toolCall != null) {
          content.add(toolCall);
        }
        continue;
      }

      if (type == 'mcp_approval_request') {
        hasToolCalls = true;
        content.addAll(_decodeMcpApprovalRequestOutput(item));
        continue;
      }

      if (type == 'mcp_call') {
        hasToolCalls = true;
        content.addAll(_decodeMcpCallOutput(item));
        continue;
      }

      final customPart = _decodeCustomOutput(item);
      if (customPart != null) {
        content.add(customPart);
      }
    }

    return GenerateTextResult(
      content: content,
      finishReason: _mapFinishReason(
        rawReason: _responseFinishReason(response),
        hasToolCalls: hasToolCalls,
        status: _asString(response['status']),
      ),
      rawFinishReason: _responseFinishReason(response),
      responseId: _asString(response['id']),
      responseTimestamp: _decodeResponseTimestamp(response),
      responseModelId: _asString(response['model']),
      usage: _decodeUsage(_asMap(response['usage'])),
      providerMetadata: _responseMetadata(response),
      warnings: warnings,
    );
  }

  Iterable<TextStreamEvent> decodeStreamChunk(
    Map<String, Object?> chunk,
    OpenAIResponsesStreamState state,
  ) sync* {
    final chunkType = _asString(chunk['type']);
    if (chunkType == null) {
      return;
    }

    if (chunkType == 'response.created') {
      final response = _asMap(chunk['response']);
      if (response != null) {
        state.responseId = _asString(response['id']);
        state.serviceTier = _asString(response['service_tier']);
        state.hasResponseMetadata = true;
        yield ResponseMetadataEvent(
          responseId: _asString(response['id']),
          timestamp: _decodeResponseTimestamp(response),
          modelId: _asString(response['model']),
          providerMetadata: _responseMetadata(response),
        );
      }
      return;
    }

    if (chunkType == 'response.output_item.added') {
      final item = _asMap(chunk['item']);
      if (item == null) {
        return;
      }

      final itemType = _asString(item['type']);
      final providerMetadata = _streamItemMetadata(
        state,
        chunk: chunk,
        item: item,
      );

      if (itemType == 'message') {
        final textId = _resolveTextId(chunk, item);
        if (state.startedTextIds.add(textId)) {
          yield TextStartEvent(
            id: textId,
            providerMetadata: providerMetadata,
          );
        }
        return;
      }

      if (itemType == 'function_call') {
        final outputIndex = _asInt(chunk['output_index']);
        final toolState = _resolveToolCallState(
          state: state,
          chunk: chunk,
          item: item,
          outputIndex: outputIndex,
        );
        if (!toolState.startEmitted) {
          toolState.startEmitted = true;
          yield ToolInputStartEvent(
            toolCallId: toolState.toolCallId,
            toolName: toolState.toolName,
            providerExecuted: false,
            isDynamic: false,
            title: _asString(item['title']),
            providerMetadata: providerMetadata,
          );
        }
      }

      return;
    }

    if (chunkType == 'response.output_text.delta') {
      final textId = _resolveTextId(chunk, null);
      final providerMetadata = _streamItemMetadata(
        state,
        chunk: chunk,
        item: null,
      );

      if (state.startedTextIds.add(textId)) {
        yield TextStartEvent(
          id: textId,
          providerMetadata: providerMetadata,
        );
      }

      final delta = _asString(chunk['delta']);
      if (delta != null && delta.isNotEmpty) {
        yield TextDeltaEvent(
          id: textId,
          delta: delta,
          providerMetadata: providerMetadata,
        );
      }
      return;
    }

    if (chunkType == 'response.output_text.done') {
      final textId = _resolveTextId(chunk, null);
      if (state.endedTextIds.add(textId)) {
        yield TextEndEvent(
          id: textId,
          providerMetadata: _streamItemMetadata(
            state,
            chunk: chunk,
            item: null,
          ),
        );
      }
      return;
    }

    if (chunkType == 'response.reasoning_summary_part.added') {
      final reasoningId = _resolveReasoningId(chunk);
      if (state.startedReasoningIds.add(reasoningId)) {
        yield ReasoningStartEvent(
          id: reasoningId,
          providerMetadata: _streamItemMetadata(
            state,
            chunk: chunk,
            item: null,
          ),
        );
      }
      return;
    }

    if (chunkType == 'response.reasoning_summary_text.delta') {
      final reasoningId = _resolveReasoningId(chunk);
      final delta = _asString(chunk['delta']);
      if (delta != null && delta.isNotEmpty) {
        yield ReasoningDeltaEvent(
          id: reasoningId,
          delta: delta,
          providerMetadata: _streamItemMetadata(
            state,
            chunk: chunk,
            item: null,
          ),
        );
      }
      return;
    }

    if (chunkType == 'response.reasoning_summary_part.done') {
      final reasoningId = _resolveReasoningId(chunk);
      if (state.endedReasoningIds.add(reasoningId)) {
        yield ReasoningEndEvent(
          id: reasoningId,
          providerMetadata: _streamItemMetadata(
            state,
            chunk: chunk,
            item: null,
          ),
        );
      }
      return;
    }

    if (chunkType == 'response.function_call_arguments.delta') {
      final outputIndex = _asInt(chunk['output_index']);
      final toolState = _resolveToolCallState(
        state: state,
        chunk: chunk,
        item: null,
        outputIndex: outputIndex,
      );
      final providerMetadata = _streamItemMetadata(
        state,
        chunk: chunk,
        item: null,
      );

      if (!toolState.startEmitted) {
        toolState.startEmitted = true;
        yield ToolInputStartEvent(
          toolCallId: toolState.toolCallId,
          toolName: toolState.toolName,
          providerExecuted: false,
          isDynamic: false,
          providerMetadata: providerMetadata,
        );
      }

      final delta = _asString(chunk['delta']);
      if (delta != null && delta.isNotEmpty) {
        toolState.arguments.write(delta);
        yield ToolInputDeltaEvent(
          toolCallId: toolState.toolCallId,
          delta: delta,
          providerMetadata: providerMetadata,
        );
      }
      return;
    }

    if (chunkType == 'response.output_text.annotation.added') {
      final annotation = _asMap(chunk['annotation']);
      final source = _decodeSourceAnnotation(annotation);
      if (source != null) {
        yield SourceEvent(source);
      }
      return;
    }

    if (chunkType == 'response.output_item.done') {
      final item = _asMap(chunk['item']);
      if (item == null) {
        return;
      }

      final itemType = _asString(item['type']);
      final providerMetadata = _streamItemMetadata(
        state,
        chunk: chunk,
        item: item,
      );

      if (itemType == 'message') {
        final textId = _resolveTextId(chunk, item);
        if (state.endedTextIds.add(textId)) {
          yield TextEndEvent(
            id: textId,
            providerMetadata: providerMetadata,
          );
        }
        return;
      }

      if (itemType == 'function_call') {
        final outputIndex = _asInt(chunk['output_index']);
        var toolState = outputIndex == null
            ? null
            : state._toolCallsByIndex.remove(outputIndex);

        toolState ??= _resolveToolCallState(
          state: state,
          chunk: chunk,
          item: item,
          outputIndex: outputIndex,
        );

        if (!toolState.startEmitted) {
          toolState.startEmitted = true;
          yield ToolInputStartEvent(
            toolCallId: toolState.toolCallId,
            toolName: toolState.toolName,
            providerExecuted: false,
            isDynamic: false,
            title: _asString(item['title']),
            providerMetadata: providerMetadata,
          );
        }

        if (!toolState.endEmitted) {
          toolState.endEmitted = true;
          yield ToolInputEndEvent(
            toolCallId: toolState.toolCallId,
            providerMetadata: providerMetadata,
          );
        }

        final toolCallPart = _decodeFunctionCallOutput(
          item,
          fallbackToolCallId: toolState.toolCallId,
          fallbackArguments: toolState.arguments.toString(),
          fallbackToolName: toolState.toolName,
        );
        if (toolCallPart != null) {
          yield ToolCallEvent(
            toolCall: toolCallPart.toolCall,
            providerMetadata: toolCallPart.providerMetadata,
          );
        }
        return;
      }

      if (itemType == 'mcp_approval_request') {
        final approvalId =
            _asString(item['approval_request_id']) ?? _asString(item['id']);
        final toolName = _asString(item['name']);
        if (approvalId == null || toolName == null) {
          return;
        }

        state.hasToolCalls = true;
        final providerMetadata = _itemMetadata(
          item,
          extra: {
            'approvalRequestId': approvalId,
            'serverLabel': _asString(item['server_label']),
          },
        );
        final qualifiedToolName = 'mcp.$toolName';

        yield ToolCallEvent(
          toolCall: ToolCallContent(
            toolCallId: approvalId,
            toolName: qualifiedToolName,
            input: _decodeJsonValue(_asString(item['arguments']) ?? '{}'),
            providerExecuted: true,
            isDynamic: true,
            title: _asString(item['server_label']),
          ),
          providerMetadata: providerMetadata,
        );
        yield ToolApprovalRequestEvent(
          approvalId: approvalId,
          toolCallId: approvalId,
          providerMetadata: providerMetadata,
        );
        return;
      }

      if (itemType == 'mcp_call') {
        final toolCallId =
            _asString(item['approval_request_id']) ?? _asString(item['id']);
        final toolName = _asString(item['name']);
        if (toolCallId == null || toolName == null) {
          return;
        }

        state.hasToolCalls = true;
        final providerMetadata = _itemMetadata(
          item,
          extra: {
            'approvalRequestId': _asString(item['approval_request_id']),
            'serverLabel': _asString(item['server_label']),
          },
        );
        final qualifiedToolName = 'mcp.$toolName';
        final arguments =
            _decodeJsonValue(_asString(item['arguments']) ?? '{}');

        yield ToolCallEvent(
          toolCall: ToolCallContent(
            toolCallId: toolCallId,
            toolName: qualifiedToolName,
            input: arguments,
            providerExecuted: true,
            isDynamic: true,
            title: _asString(item['server_label']),
          ),
          providerMetadata: providerMetadata,
        );
        yield ToolResultEvent(
          toolResult: ToolResultContent(
            toolCallId: toolCallId,
            toolName: qualifiedToolName,
            output: {
              'type': 'mcp_call',
              'serverLabel': _asString(item['server_label']),
              'name': toolName,
              'arguments': arguments,
              if (item['output'] != null) 'output': item['output'],
              if (item['error'] != null) 'error': item['error'],
            },
            isError: item['error'] != null,
            isDynamic: true,
          ),
          providerMetadata: providerMetadata,
        );
        return;
      }

      if (itemType != 'reasoning' && itemType != null) {
        yield CustomEvent(
          kind: 'openai.$itemType',
          data: item,
          providerMetadata: providerMetadata,
        );
      }
      return;
    }

    if (chunkType == 'response.completed' ||
        chunkType == 'response.incomplete' ||
        chunkType == 'response.failed') {
      final response = _asMap(chunk['response']);
      if (response == null) {
        return;
      }

      state.responseId = _asString(response['id']) ?? state.responseId;
      state.serviceTier =
          _asString(response['service_tier']) ?? state.serviceTier;
      state.rawFinishReason = _responseFinishReason(response);
      state.usage = _decodeUsage(_asMap(response['usage']));

      if (!state.hasResponseMetadata) {
        state.hasResponseMetadata = true;
        yield ResponseMetadataEvent(
          responseId: _asString(response['id']),
          timestamp: _decodeResponseTimestamp(response),
          modelId: _asString(response['model']),
          providerMetadata: _responseMetadata(response),
        );
      }

      if (chunkType == 'response.failed') {
        final error = response['error'];
        if (error != null) {
          yield ErrorEvent(error);
        }
      }

      yield FinishEvent(
        finishReason: _mapFinishReason(
          rawReason: state.rawFinishReason,
          hasToolCalls: state.hasToolCalls,
          status: chunkType == 'response.failed'
              ? 'failed'
              : _asString(response['status']),
        ),
        rawFinishReason: state.rawFinishReason,
        usage: state.usage,
        providerMetadata: _responseMetadata(response),
      );
      return;
    }

    if (chunkType == 'error') {
      yield ErrorEvent(chunk['error'] ?? chunk);
    }
  }

  List<Object?> _encodePromptMessage(PromptMessage message) {
    if (message is SystemPromptMessage) {
      return [
        {
          'role': 'system',
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
            for (final part in message.parts) _encodeUserPart(part),
          ],
        },
      ];
    }

    if (message is AssistantPromptMessage) {
      return _encodeAssistantMessage(message);
    }

    if (message is ToolPromptMessage) {
      return _encodeToolMessage(message);
    }

    throw UnsupportedError(
      'Unsupported prompt message type: ${message.runtimeType}',
    );
  }

  List<Object?> _encodeAssistantMessage(AssistantPromptMessage message) {
    final items = <Object?>[];
    final textContent = <Object?>[];

    void flushTextContent() {
      if (textContent.isEmpty) {
        return;
      }

      items.add({
        'role': 'assistant',
        'content': List<Object?>.from(textContent),
      });
      textContent.clear();
    }

    for (final part in message.parts) {
      if (part is TextPromptPart) {
        textContent.add({
          'type': 'output_text',
          'text': part.text,
        });
        continue;
      }

      flushTextContent();

      if (part is ToolCallPromptPart) {
        if (part.providerExecuted) {
          continue;
        }

        items.add({
          'type': 'function_call',
          'call_id': part.toolCallId,
          'name': part.toolName,
          'arguments': _encodeJsonString(part.input),
        });
        continue;
      }

      if (part is ToolApprovalRequestPromptPart) {
        continue;
      }

      if (part is ToolResultPromptPart) {
        items.add({
          'type': 'function_call_output',
          'call_id': part.toolCallId,
          'output': _encodeToolOutput(
            output: part.output,
            isError: part.isError,
          ),
        });
        continue;
      }

      throw UnsupportedError(
        'Assistant prompt part ${part.runtimeType} is not supported by the migrated Responses codec yet.',
      );
    }

    flushTextContent();
    return items;
  }

  List<Object?> _encodeToolMessage(ToolPromptMessage message) {
    final items = <Object?>[];

    for (final part in message.parts) {
      if (part is ToolApprovalResponsePromptPart) {
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
        'output': _encodeToolOutput(
          output: part.output,
          isError: part.isError,
        ),
      });
    }

    return items;
  }

  Object _encodeUserPart(PromptPart part) {
    if (part is TextPromptPart) {
      return {
        'type': 'input_text',
        'text': part.text,
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

  List<ContentPart> _decodeMessageOutput(Map<String, Object?> item) {
    final parts = <ContentPart>[];
    final content = _asList(item['content']);

    for (final rawContentPart in content) {
      final contentPart = _asMap(rawContentPart);
      if (contentPart == null) {
        continue;
      }

      final contentType = _asString(contentPart['type']);
      if (contentType == 'output_text') {
        parts.add(
          TextContentPart(
            _asString(contentPart['text']) ?? '',
            providerMetadata: _itemMetadata(
              item,
              extra: {
                'contentType': contentType,
              },
            ),
          ),
        );

        for (final annotation in _asList(contentPart['annotations'])) {
          final source = _decodeSourceAnnotation(_asMap(annotation));
          if (source != null) {
            parts.add(SourceContentPart(source));
          }
        }
        continue;
      }

      if (contentType != null) {
        parts.add(
          CustomContentPart(
            kind: 'openai.message.$contentType',
            data: contentPart,
            providerMetadata: _itemMetadata(item),
          ),
        );
      }
    }

    return parts;
  }

  List<ContentPart> _decodeReasoningOutput(Map<String, Object?> item) {
    final parts = <ContentPart>[];
    final summaries = _asList(item['summary']);

    for (var index = 0; index < summaries.length; index++) {
      final summary = _asMap(summaries[index]);
      if (summary == null) {
        continue;
      }

      final text = _asString(summary['text']);
      if (text == null || text.isEmpty) {
        continue;
      }

      parts.add(
        ReasoningContentPart(
          text,
          providerMetadata: _itemMetadata(
            item,
            extra: {
              'summaryIndex': index,
              'encryptedContent': item['encrypted_content'],
            },
          ),
        ),
      );
    }

    return parts;
  }

  ToolCallContentPart? _decodeFunctionCallOutput(
    Map<String, Object?> item, {
    String? fallbackToolCallId,
    String? fallbackArguments,
    String? fallbackToolName,
  }) {
    final toolCallId = _asString(item['call_id']) ??
        fallbackToolCallId ??
        _asString(item['id']);
    final toolName = _asString(item['name']) ?? fallbackToolName;
    if (toolCallId == null || toolName == null) {
      return null;
    }

    final encodedArguments =
        _asString(item['arguments']) ?? fallbackArguments ?? '{}';

    return ToolCallContentPart(
      ToolCallContent(
        toolCallId: toolCallId,
        toolName: toolName,
        input: _decodeJsonValue(encodedArguments),
        providerExecuted: false,
        isDynamic: false,
        title: _asString(item['title']),
      ),
      providerMetadata: _itemMetadata(
        item,
        extra: {
          'callId': toolCallId,
        },
      ),
    );
  }

  List<ContentPart> _decodeMcpApprovalRequestOutput(Map<String, Object?> item) {
    final approvalId =
        _asString(item['approval_request_id']) ?? _asString(item['id']);
    final toolName = _asString(item['name']);
    if (approvalId == null || toolName == null) {
      return const [];
    }

    final providerMetadata = _itemMetadata(
      item,
      extra: {
        'approvalRequestId': approvalId,
        'serverLabel': _asString(item['server_label']),
      },
    );
    final qualifiedToolName = 'mcp.$toolName';

    return [
      ToolCallContentPart(
        ToolCallContent(
          toolCallId: approvalId,
          toolName: qualifiedToolName,
          input: _decodeJsonValue(_asString(item['arguments']) ?? '{}'),
          providerExecuted: true,
          isDynamic: true,
          title: _asString(item['server_label']),
        ),
        providerMetadata: providerMetadata,
      ),
      ToolApprovalRequestContentPart(
        ToolApprovalRequestContent(
          approvalId: approvalId,
          toolCallId: approvalId,
        ),
        providerMetadata: providerMetadata,
      ),
    ];
  }

  List<ContentPart> _decodeMcpCallOutput(Map<String, Object?> item) {
    final toolCallId =
        _asString(item['approval_request_id']) ?? _asString(item['id']);
    final toolName = _asString(item['name']);
    if (toolCallId == null || toolName == null) {
      return const [];
    }

    final providerMetadata = _itemMetadata(
      item,
      extra: {
        'approvalRequestId': _asString(item['approval_request_id']),
        'serverLabel': _asString(item['server_label']),
      },
    );
    final qualifiedToolName = 'mcp.$toolName';
    final arguments = _decodeJsonValue(_asString(item['arguments']) ?? '{}');

    return [
      ToolCallContentPart(
        ToolCallContent(
          toolCallId: toolCallId,
          toolName: qualifiedToolName,
          input: arguments,
          providerExecuted: true,
          isDynamic: true,
          title: _asString(item['server_label']),
        ),
        providerMetadata: providerMetadata,
      ),
      ToolResultContentPart(
        ToolResultContent(
          toolCallId: toolCallId,
          toolName: qualifiedToolName,
          output: {
            'type': 'mcp_call',
            'serverLabel': _asString(item['server_label']),
            'name': toolName,
            'arguments': arguments,
            if (item['output'] != null) 'output': item['output'],
            if (item['error'] != null) 'error': item['error'],
          },
          isError: item['error'] != null,
          isDynamic: true,
        ),
        providerMetadata: providerMetadata,
      ),
    ];
  }

  CustomContentPart? _decodeCustomOutput(Map<String, Object?> item) {
    final type = _asString(item['type']);
    if (type == null) {
      return null;
    }

    return CustomContentPart(
      kind: 'openai.$type',
      data: item,
      providerMetadata: _itemMetadata(item),
    );
  }

  SourceReference? _decodeSourceAnnotation(Map<String, Object?>? annotation) {
    if (annotation == null) {
      return null;
    }

    final type = _asString(annotation['type']);
    if (type == 'url_citation') {
      final url = _asString(annotation['url']);
      if (url == null) {
        return null;
      }

      return SourceReference(
        kind: SourceReferenceKind.url,
        sourceId: url,
        uri: Uri.tryParse(url),
        title: _asString(annotation['title']),
        providerMetadata: _providerMetadata({
          'annotationType': type,
          'startIndex': _asInt(annotation['start_index']),
          'endIndex': _asInt(annotation['end_index']),
        }),
      );
    }

    if (type == 'file_citation') {
      final sourceId =
          _asString(annotation['file_id']) ?? _asString(annotation['filename']);
      if (sourceId == null) {
        return null;
      }

      return SourceReference(
        kind: SourceReferenceKind.document,
        sourceId: sourceId,
        title: _asString(annotation['filename']),
        filename: _asString(annotation['filename']),
        mediaType: 'text/plain',
        providerMetadata: _providerMetadata({
          'annotationType': type,
          'fileId': _asString(annotation['file_id']),
          'index': _asInt(annotation['index']),
        }),
      );
    }

    if (type == 'container_file_citation') {
      final sourceId =
          _asString(annotation['file_id']) ?? _asString(annotation['filename']);
      if (sourceId == null) {
        return null;
      }

      return SourceReference(
        kind: SourceReferenceKind.document,
        sourceId: sourceId,
        title: _asString(annotation['filename']),
        filename: _asString(annotation['filename']),
        mediaType: 'text/plain',
        providerMetadata: _providerMetadata({
          'annotationType': type,
          'fileId': _asString(annotation['file_id']),
          'containerId': _asString(annotation['container_id']),
        }),
      );
    }

    if (type == 'file_path') {
      final sourceId = _asString(annotation['file_id']);
      if (sourceId == null) {
        return null;
      }

      return SourceReference(
        kind: SourceReferenceKind.document,
        sourceId: sourceId,
        title: sourceId,
        filename: sourceId,
        mediaType: 'application/octet-stream',
        providerMetadata: _providerMetadata({
          'annotationType': type,
          'fileId': sourceId,
          'index': _asInt(annotation['index']),
        }),
      );
    }

    return null;
  }

  ProviderMetadata? _responseMetadata(Map<String, Object?> response) {
    return _providerMetadata({
      'status': _asString(response['status']),
      'serviceTier': _asString(response['service_tier']),
    });
  }

  ProviderMetadata? _itemMetadata(
    Map<String, Object?> item, {
    Map<String, Object?> extra = const {},
  }) {
    return _providerMetadata({
      'itemId': _asString(item['id']),
      'itemType': _asString(item['type']),
      'status': _asString(item['status']),
      ...extra,
    });
  }

  ProviderMetadata? _streamItemMetadata(
    OpenAIResponsesStreamState state, {
    required Map<String, Object?> chunk,
    required Map<String, Object?>? item,
  }) {
    return _providerMetadata({
      'responseId': state.responseId,
      'itemId': _asString(chunk['item_id']) ?? _asString(item?['id']),
      'itemType': _asString(item?['type']),
      'outputIndex': _asInt(chunk['output_index']),
      'contentIndex': _asInt(chunk['content_index']),
      'summaryIndex': _asInt(chunk['summary_index']),
      'serviceTier': state.serviceTier,
    });
  }

  ProviderMetadata? _providerMetadata(Map<String, Object?> values) {
    final openaiValues = <String, Object?>{};
    for (final entry in values.entries) {
      if (entry.value != null) {
        openaiValues[entry.key] = entry.value;
      }
    }

    if (openaiValues.isEmpty) {
      return null;
    }

    return ProviderMetadata({
      'openai': openaiValues,
    });
  }

  _OpenAIToolCallState _resolveToolCallState({
    required OpenAIResponsesStreamState state,
    required Map<String, Object?> chunk,
    required Map<String, Object?>? item,
    required int? outputIndex,
  }) {
    _OpenAIToolCallState? toolState;
    if (outputIndex != null) {
      toolState = state._toolCallsByIndex[outputIndex];
    }

    final resolvedToolCallId =
        _asString(item?['call_id']) ?? _asString(chunk['item_id']) ?? 'tool';
    final resolvedToolName = _asString(item?['name']) ?? 'function';

    if (toolState == null) {
      toolState = _OpenAIToolCallState(
        toolCallId: resolvedToolCallId,
        toolName: resolvedToolName,
      );
      if (outputIndex != null) {
        state._toolCallsByIndex[outputIndex] = toolState;
      }
    } else {
      if (_asString(item?['call_id']) case final callId?) {
        toolState.toolCallId = callId;
      }
      if (_asString(item?['name']) case final toolName?) {
        toolState.toolName = toolName;
      }
    }

    state.hasToolCalls = true;
    return toolState;
  }

  FinishReason _mapFinishReason({
    required String? rawReason,
    required bool hasToolCalls,
    required String? status,
  }) {
    if (status == 'failed') {
      return FinishReason.error;
    }

    if (rawReason == null) {
      return hasToolCalls ? FinishReason.toolCalls : FinishReason.stop;
    }

    if (rawReason == 'max_output_tokens') {
      return FinishReason.maxTokens;
    }

    if (rawReason == 'content_filter') {
      return FinishReason.contentFilter;
    }

    if (rawReason == 'cancelled') {
      return FinishReason.aborted;
    }

    return hasToolCalls ? FinishReason.toolCalls : FinishReason.other;
  }

  UsageStats? _decodeUsage(Map<String, Object?>? usage) {
    if (usage == null) {
      return null;
    }

    final inputTokens = _asInt(usage['input_tokens']);
    final outputTokens = _asInt(usage['output_tokens']);
    final totalTokens = _asInt(usage['total_tokens']) ??
        ((inputTokens != null && outputTokens != null)
            ? inputTokens + outputTokens
            : null);
    final outputDetails = _asMap(usage['output_tokens_details']);

    return UsageStats(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: totalTokens,
      reasoningTokens: _asInt(outputDetails?['reasoning_tokens']),
    );
  }

  List<Map<String, Object?>> _outputItems(Map<String, Object?> response) {
    final output = _asList(response['output']);
    final items = <Map<String, Object?>>[];

    for (final rawItem in output) {
      final item = _asMap(rawItem);
      if (item != null) {
        items.add(item);
      }
    }

    return items;
  }

  String? _responseFinishReason(Map<String, Object?> response) {
    final incompleteDetails = _asMap(response['incomplete_details']);
    return _asString(incompleteDetails?['reason']);
  }

  String _resolveTextId(
    Map<String, Object?> chunk,
    Map<String, Object?>? item,
  ) {
    return _asString(chunk['item_id']) ??
        _asString(item?['id']) ??
        'text-${_asInt(chunk['output_index']) ?? 0}';
  }

  String _resolveReasoningId(Map<String, Object?> chunk) {
    return '${_asString(chunk['item_id']) ?? 'reasoning'}:${_asInt(chunk['summary_index']) ?? 0}';
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

  String _encodeToolOutput({
    required Object? output,
    required bool isError,
  }) {
    if (output == null) {
      return isError ? 'Tool execution failed' : 'null';
    }

    if (output is String) {
      return output;
    }

    return jsonEncode(output);
  }

  Object? _decodeJsonValue(String value) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }

  void _throwIfError(Map<String, Object?> response) {
    final error = _asMap(response['error']);
    if (error == null) {
      return;
    }

    final message = _asString(error['message']) ?? 'OpenAI response error';
    final type = _asString(error['type']);
    final code = error['code'];
    throw StateError(
      'OpenAI response error: $message'
      '${type == null ? '' : ' (type: $type)'}'
      '${code == null ? '' : ' (code: $code)'}',
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

  List<Object?> _asList(Object? value) {
    if (value is List<Object?>) {
      return value;
    }

    if (value is List) {
      return List<Object?>.from(value);
    }

    return const [];
  }

  String? _asString(Object? value) {
    return value is String ? value : null;
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return null;
  }

  DateTime? _decodeResponseTimestamp(Map<String, Object?> response) {
    final createdAt = _asInt(response['created_at']);
    if (createdAt == null) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(
      createdAt * 1000,
      isUtc: true,
    );
  }
}

final class _OpenAIToolCallState {
  String toolCallId;
  String toolName;
  final StringBuffer arguments = StringBuffer();
  bool startEmitted = false;
  bool endEmitted = false;

  _OpenAIToolCallState({
    required this.toolCallId,
    required this.toolName,
  });
}
