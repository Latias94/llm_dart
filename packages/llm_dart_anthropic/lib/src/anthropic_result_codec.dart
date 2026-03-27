import 'package:llm_dart_core/llm_dart_core.dart';

final class AnthropicMessagesResultCodec {
  const AnthropicMessagesResultCodec();

  GenerateTextResult decodeResponse(
    Map<String, Object?> response, {
    List<ModelWarning> warnings = const [],
  }) {
    final content = <ContentPart>[];
    final toolDescriptors = <String, _AnthropicToolDescriptor>{};

    for (final rawPart in _asList(response['content'])) {
      final part = _asMap(rawPart);
      if (part == null) {
        continue;
      }

      final type = _asString(part['type']);
      if (type == 'text') {
        content.add(TextContentPart(_asString(part['text']) ?? ''));
        for (final rawCitation in _asList(part['citations'])) {
          final citation = _asMap(rawCitation);
          final source = _decodeCitationSource(citation);
          if (source != null) {
            content.add(SourceContentPart(source));
          }
        }
        continue;
      }

      if (type == 'thinking') {
        content.add(
          ReasoningContentPart(
            _asString(part['thinking']) ?? '',
            providerMetadata: _providerMetadata({
              'signature': _asString(part['signature']),
            }),
          ),
        );
        continue;
      }

      if (type == 'redacted_thinking') {
        content.add(
          ReasoningContentPart(
            '',
            providerMetadata: _providerMetadata({
              'redactedData': _asString(part['data']),
            }),
          ),
        );
        continue;
      }

      if (type == 'compaction') {
        content.add(
          TextContentPart(
            _asString(part['content']) ?? '',
            providerMetadata: _providerMetadata({
              'type': 'compaction',
            }),
          ),
        );
        continue;
      }

      if (type == 'tool_use') {
        final toolCallId = _asString(part['id']);
        final toolName = _asString(part['name']);
        if (toolCallId == null || toolName == null) {
          continue;
        }

        final metadata = _providerMetadata({
          'caller': part['caller'],
        });
        toolDescriptors[toolCallId] = _AnthropicToolDescriptor(
          toolName: toolName,
          providerMetadata: metadata,
          providerExecuted: false,
          isDynamic: false,
          title: null,
        );
        content.add(
          ToolCallContentPart(
            ToolCallContent(
              toolCallId: toolCallId,
              toolName: toolName,
              input: _normalizeJsonValue(part['input']),
            ),
            providerMetadata: metadata,
          ),
        );
        continue;
      }

      if (type == 'server_tool_use') {
        final toolCallId = _asString(part['id']);
        final toolName = _asString(part['name']);
        if (toolCallId == null || toolName == null) {
          continue;
        }

        final metadata = _providerMetadata({
          'providerToolName': toolName,
          'caller': part['caller'],
        });
        toolDescriptors[toolCallId] = _AnthropicToolDescriptor(
          toolName: toolName,
          providerMetadata: metadata,
          providerExecuted: true,
          isDynamic: true,
          title: null,
        );
        content.add(
          ToolCallContentPart(
            ToolCallContent(
              toolCallId: toolCallId,
              toolName: toolName,
              input: _normalizeJsonValue(part['input']),
              providerExecuted: true,
              isDynamic: true,
            ),
            providerMetadata: metadata,
          ),
        );
        continue;
      }

      if (type == 'mcp_tool_use') {
        final toolCallId = _asString(part['id']);
        final rawToolName = _asString(part['name']);
        if (toolCallId == null || rawToolName == null) {
          continue;
        }

        final toolName = 'mcp.$rawToolName';
        final metadata = _providerMetadata({
          'serverName': _asString(part['server_name']),
        });
        toolDescriptors[toolCallId] = _AnthropicToolDescriptor(
          toolName: toolName,
          providerMetadata: metadata,
          providerExecuted: true,
          isDynamic: true,
          title: _asString(part['server_name']),
        );
        content.add(
          ToolCallContentPart(
            ToolCallContent(
              toolCallId: toolCallId,
              toolName: toolName,
              input: _normalizeJsonValue(part['input']),
              providerExecuted: true,
              isDynamic: true,
              title: _asString(part['server_name']),
            ),
            providerMetadata: metadata,
          ),
        );
        continue;
      }

      if (_isToolResultPart(type)) {
        content.addAll(_decodeToolResultParts(part, toolDescriptors));
        continue;
      }

      if (type != null) {
        content.add(
          CustomContentPart(
            kind: 'anthropic.$type',
            data: part,
          ),
        );
      }
    }

    return GenerateTextResult(
      content: content,
      finishReason: _mapFinishReason(_asString(response['stop_reason'])),
      rawFinishReason: _asString(response['stop_reason']),
      responseId: _asString(response['id']),
      responseModelId: _asString(response['model']),
      usage: _decodeUsage(_asMap(response['usage'])),
      providerMetadata: _providerMetadata({
        'usage': _asMap(response['usage']),
        'stopSequence': _asString(response['stop_sequence']),
        'container': _decodeContainer(_asMap(response['container'])),
        'contextManagement': _asMap(response['context_management']),
      }),
      warnings: warnings,
    );
  }

  List<ContentPart> _decodeToolResultParts(
    Map<String, Object?> part,
    Map<String, _AnthropicToolDescriptor> toolDescriptors,
  ) {
    final type = _asString(part['type']);
    final toolUseId = _asString(part['tool_use_id']);
    if (type == null || toolUseId == null) {
      return const [];
    }

    final descriptor = toolDescriptors[toolUseId];
    final toolName = descriptor?.toolName ?? _fallbackToolName(type);
    final metadata = _providerMetadata({
      ..._providerMetadataValues(descriptor?.providerMetadata),
      'partType': type,
    });

    final parts = <ContentPart>[
      ToolResultContentPart(
        ToolResultContent(
          toolCallId: toolUseId,
          toolName: toolName,
          output: _toolResultOutput(type, part),
          isError: _isErrorToolResult(type, part),
          isDynamic: descriptor?.isDynamic ?? true,
        ),
        providerMetadata: metadata,
      ),
    ];

    if (type == 'web_search_tool_result') {
      final resultList = part['content'];
      if (resultList is List) {
        for (final item in resultList) {
          final result = _asMap(item);
          final url = _asString(result?['url']);
          if (url == null) {
            continue;
          }

          parts.add(
            SourceContentPart(
              SourceReference(
                kind: SourceReferenceKind.url,
                sourceId: url,
                uri: Uri.tryParse(url),
                title: _asString(result?['title']),
                providerMetadata: _providerMetadata({
                  'pageAge': _asString(result?['page_age']),
                  'resultType': _asString(result?['type']),
                }),
              ),
            ),
          );
        }
      }
    }

    return parts;
  }

  bool _isToolResultPart(String? type) {
    return type == 'mcp_tool_result' ||
        type == 'web_fetch_tool_result' ||
        type == 'web_search_tool_result' ||
        type == 'code_execution_tool_result' ||
        type == 'bash_code_execution_tool_result' ||
        type == 'text_editor_code_execution_tool_result' ||
        type == 'tool_search_tool_result';
  }

  FinishReason _mapFinishReason(String? rawReason) {
    switch (rawReason) {
      case 'pause_turn':
      case 'end_turn':
      case 'stop_sequence':
        return FinishReason.stop;
      case 'tool_use':
        return FinishReason.toolCalls;
      case 'max_tokens':
      case 'model_context_window_exceeded':
        return FinishReason.maxTokens;
      case 'refusal':
        return FinishReason.contentFilter;
      default:
        return FinishReason.other;
    }
  }

  UsageStats? _decodeUsage(Map<String, Object?>? usage) {
    if (usage == null) {
      return null;
    }

    final inputTokens = _asInt(usage['input_tokens']);
    final outputTokens = _asInt(usage['output_tokens']);
    return UsageStats(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: (inputTokens ?? 0) + (outputTokens ?? 0),
    );
  }

  Map<String, Object?>? _decodeContainer(Map<String, Object?>? container) {
    if (container == null) {
      return null;
    }

    return {
      if (_asString(container['id']) != null) 'id': _asString(container['id']),
      if (_asString(container['expires_at']) != null)
        'expiresAt': _asString(container['expires_at']),
      if (container['skills'] != null)
        'skills': _normalizeJsonValue(container['skills']),
    };
  }

  ProviderMetadata? _providerMetadata(Map<String, Object?> values) {
    final anthropicValues = <String, Object?>{};
    for (final entry in values.entries) {
      if (entry.value != null) {
        anthropicValues[entry.key] = entry.value;
      }
    }

    if (anthropicValues.isEmpty) {
      return null;
    }

    return ProviderMetadata({
      'anthropic': anthropicValues,
    });
  }

  Map<String, Object?> _providerMetadataValues(ProviderMetadata? metadata) {
    final values = metadata?.values['anthropic'];
    if (values is Map<String, Object?>) {
      return values;
    }

    if (values is Map) {
      return Map<String, Object?>.from(values);
    }

    return const {};
  }

  SourceReference? _decodeCitationSource(Map<String, Object?>? citation) {
    if (citation == null) {
      return null;
    }

    final type = _asString(citation['type']);
    if (type == 'web_search_result_location') {
      final url = _asString(citation['url']);
      if (url == null) {
        return null;
      }

      return SourceReference(
        kind: SourceReferenceKind.url,
        sourceId: url,
        uri: Uri.tryParse(url),
        title: _asString(citation['title']),
        providerMetadata: _providerMetadata({
          'citationType': type,
          'citedText': _asString(citation['cited_text']),
          'encryptedIndex': _asString(citation['encrypted_index']),
        }),
      );
    }

    if (type == 'page_location' || type == 'char_location') {
      final documentIndex = _asInt(citation['document_index']);
      return SourceReference(
        kind: SourceReferenceKind.document,
        sourceId: 'document-${documentIndex ?? 0}',
        title: _asString(citation['document_title']),
        providerMetadata: _providerMetadata({
          'citationType': type,
          'citedText': _asString(citation['cited_text']),
          'documentIndex': documentIndex,
          'startPageNumber': _asInt(citation['start_page_number']),
          'endPageNumber': _asInt(citation['end_page_number']),
          'startCharIndex': _asInt(citation['start_char_index']),
          'endCharIndex': _asInt(citation['end_char_index']),
        }),
      );
    }

    return null;
  }

  String _fallbackToolName(String partType) {
    switch (partType) {
      case 'mcp_tool_result':
        return 'mcp.unknown';
      case 'web_fetch_tool_result':
        return 'web_fetch';
      case 'web_search_tool_result':
        return 'web_search';
      case 'code_execution_tool_result':
      case 'bash_code_execution_tool_result':
      case 'text_editor_code_execution_tool_result':
        return 'code_execution';
      case 'tool_search_tool_result':
        return 'tool_search';
      default:
        return 'tool';
    }
  }

  bool _isErrorToolResult(String partType, Map<String, Object?> part) {
    if (partType == 'mcp_tool_result') {
      return part['is_error'] == true;
    }

    final content = _asMap(part['content']);
    final contentType = _asString(content?['type']);
    return contentType != null && contentType.endsWith('_error');
  }

  Object? _toolResultOutput(String partType, Map<String, Object?> part) {
    if (partType == 'mcp_tool_result') {
      return _normalizeJsonValue(part['content']);
    }

    return _normalizeJsonValue(part['content']);
  }

  Object? _normalizeJsonValue(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }

    if (value is Map<String, Object?>) {
      return value.map(
        (key, nestedValue) => MapEntry(key, _normalizeJsonValue(nestedValue)),
      );
    }

    if (value is Map) {
      final normalized = <String, Object?>{};
      for (final entry in value.entries) {
        if (entry.key is! String) {
          throw UnsupportedError(
            'Expected a string key in Anthropic JSON payload.',
          );
        }

        normalized[entry.key as String] = _normalizeJsonValue(entry.value);
      }
      return normalized;
    }

    if (value is List) {
      return [for (final item in value) _normalizeJsonValue(item)];
    }

    throw UnsupportedError(
      'Expected a JSON-safe Anthropic payload but received ${value.runtimeType}.',
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
}

final class _AnthropicToolDescriptor {
  final String toolName;
  final ProviderMetadata? providerMetadata;
  final bool providerExecuted;
  final bool isDynamic;
  final String? title;

  const _AnthropicToolDescriptor({
    required this.toolName,
    required this.providerMetadata,
    required this.providerExecuted,
    required this.isDynamic,
    required this.title,
  });
}
