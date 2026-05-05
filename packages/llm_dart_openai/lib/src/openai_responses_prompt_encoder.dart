part of 'openai_responses_codec.dart';

extension _OpenAIResponsesCodecPromptEncoder on OpenAIResponsesCodec {
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
        final metadata = _providerMetadataValues(
          part.providerMetadata,
          namespace: 'openai',
        );
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

        final metadata = _providerMetadataValues(
          part.providerMetadata,
          namespace: 'openai',
        );
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
        final metadata = _providerMetadataValues(
          part.providerMetadata,
          namespace: 'openai',
        );
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

        final metadata = _providerMetadataValues(
          part.providerMetadata,
          namespace: 'openai',
        );
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
      final openaiMetadata = _providerMetadataValues(
        part.providerMetadata,
        namespace: 'openai',
      );
      final imageDetail = _asString(openaiMetadata?['imageDetail']);
      if (_openAIFileId(
        data: part.data,
        metadata: part.providerMetadata,
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
      final openaiMetadata = _providerMetadataValues(
        part.providerMetadata,
        namespace: 'openai',
      );
      if (part.mediaType.startsWith('image/')) {
        final imageDetail = _asString(openaiMetadata?['imageDetail']);
        if (_openAIFileId(
          data: part.data,
          metadata: part.providerMetadata,
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
          metadata: part.providerMetadata,
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
            'User PDF file prompt parts need bytes, a URI, or an OpenAI fileId on the migrated Responses path.',
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
}
