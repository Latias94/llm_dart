import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'ai_errors.dart';
import 'types.dart';

/// Encodes [LLMStreamPart] streams into Vercel AI SDK-style UI message chunks.
///
/// Upstream reference schema:
/// `repo-ref/ai/packages/ai/src/ui-message-stream/ui-message-chunks.ts`
///
/// This is intended for app/framework integrations that need to send an SSE
/// stream to a browser/UI client.
Stream<Map<String, Object?>> uiMessageChunksFromParts(
  Stream<LLMStreamPart> parts, {
  bool sendStart = true,
  bool sendFinish = true,
  bool sendReasoning = true,
  bool sendSources = false,
  bool sendFiles = true,
  String? messageId,
  Object? startMessageMetadata,
  Object? Function(LLMStreamPart part)? messageMetadata,
  Object? Function(LLMFinishPart part)? finishMessageMetadata,
  Object? Function(ToolLoopBlockedState state)? toolApprovalBlockedStateData,
  Object? Function(ProviderToolApprovalBlockedState state)?
      providerToolApprovalBlockedStateData,
  String Function(Object error)? onError,
}) async* {
  if (sendStart) {
    yield <String, Object?>{
      'type': 'start',
      if (messageId != null && messageId.isNotEmpty) 'messageId': messageId,
      if (startMessageMetadata != null) 'messageMetadata': startMessageMetadata,
    };
  }

  final toolInputTextById = <String, StringBuffer>{};
  final toolInputMetaById = <String, _ToolInputMeta>{};

  void clearStepState() {
    toolInputTextById.clear();
    toolInputMetaById.clear();
  }

  await for (final part in parts) {
    final messageMeta = messageMetadata != null ? messageMetadata(part) : null;

    switch (part) {
      case LLMStepStartPart():
        clearStepState();
        yield const <String, Object?>{'type': 'start-step'};
        if (messageMeta != null) {
          yield <String, Object?>{
            'type': 'message-metadata',
            'messageMetadata': messageMeta,
          };
        }

      case LLMStepFinishPart():
        yield const <String, Object?>{'type': 'finish-step'};
        if (messageMeta != null) {
          yield <String, Object?>{
            'type': 'message-metadata',
            'messageMetadata': messageMeta,
          };
        }

      case LLMTextStartPart(blockId: final id, providerMetadata: final pm):
        final blockId = _requireNonEmptyId(id);
        yield <String, Object?>{
          'type': 'text-start',
          'id': blockId,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        };
        if (messageMeta != null) {
          yield <String, Object?>{
            'type': 'message-metadata',
            'messageMetadata': messageMeta,
          };
        }

      case LLMTextDeltaPart(
          :final delta,
          blockId: final id,
          providerMetadata: final pm,
        ):
        final blockId = _requireNonEmptyId(id);
        yield <String, Object?>{
          'type': 'text-delta',
          'id': blockId,
          'delta': delta,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        };
        if (messageMeta != null) {
          yield <String, Object?>{
            'type': 'message-metadata',
            'messageMetadata': messageMeta,
          };
        }

      case LLMTextEndPart(blockId: final id, providerMetadata: final pm):
        final blockId = _requireNonEmptyId(id);
        yield <String, Object?>{
          'type': 'text-end',
          'id': blockId,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        };
        if (messageMeta != null) {
          yield <String, Object?>{
            'type': 'message-metadata',
            'messageMetadata': messageMeta,
          };
        }

      case LLMReasoningStartPart(blockId: final id, providerMetadata: final pm):
        if (!sendReasoning) break;
        final blockId = _requireNonEmptyId(id);
        yield <String, Object?>{
          'type': 'reasoning-start',
          'id': blockId,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        };
        if (messageMeta != null) {
          yield <String, Object?>{
            'type': 'message-metadata',
            'messageMetadata': messageMeta,
          };
        }

      case LLMReasoningDeltaPart(
          :final delta,
          blockId: final id,
          providerMetadata: final pm,
        ):
        if (!sendReasoning) break;
        final blockId = _requireNonEmptyId(id);
        yield <String, Object?>{
          'type': 'reasoning-delta',
          'id': blockId,
          'delta': delta,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        };
        if (messageMeta != null) {
          yield <String, Object?>{
            'type': 'message-metadata',
            'messageMetadata': messageMeta,
          };
        }

      case LLMReasoningEndPart(blockId: final id, providerMetadata: final pm):
        if (!sendReasoning) break;
        final blockId = _requireNonEmptyId(id);
        yield <String, Object?>{
          'type': 'reasoning-end',
          'id': blockId,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        };
        if (messageMeta != null) {
          yield <String, Object?>{
            'type': 'message-metadata',
            'messageMetadata': messageMeta,
          };
        }

      case LLMToolInputStartPart(
          id: final toolCallId,
          toolName: final toolName,
          providerExecuted: final providerExecuted,
          isDynamic: final dynamicTool,
          title: final title,
          providerMetadata: final pm,
        ):
        toolInputTextById[toolCallId] = StringBuffer();
        toolInputMetaById[toolCallId] = _ToolInputMeta(
          toolName: toolName,
          providerExecuted: providerExecuted,
          dynamicTool: dynamicTool,
          title: title,
          providerMetadata: pm,
        );
        yield <String, Object?>{
          'type': 'tool-input-start',
          'toolCallId': toolCallId,
          'toolName': toolName,
          if (providerExecuted == true) 'providerExecuted': true,
          if (dynamicTool == true) 'dynamic': true,
          if (title != null && title.isNotEmpty) 'title': title,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        };
        if (messageMeta != null) {
          yield <String, Object?>{
            'type': 'message-metadata',
            'messageMetadata': messageMeta,
          };
        }

      case LLMToolInputDeltaPart(id: final toolCallId, delta: final delta):
        (toolInputTextById[toolCallId] ??= StringBuffer()).write(delta);
        yield <String, Object?>{
          'type': 'tool-input-delta',
          'toolCallId': toolCallId,
          'inputTextDelta': delta,
        };
        if (messageMeta != null) {
          yield <String, Object?>{
            'type': 'message-metadata',
            'messageMetadata': messageMeta,
          };
        }

      case LLMToolInputEndPart(id: final toolCallId):
        final meta = toolInputMetaById[toolCallId];
        final toolName = meta?.toolName;
        if (toolName == null || toolName.isEmpty) {
          // Best-effort: no tool name, skip emitting input-available/error.
          break;
        }

        final inputText = toolInputTextById[toolCallId]?.toString() ?? '';
        final parsed = _tryDecodeJson(inputText);
        if (parsed.error != null) {
          yield <String, Object?>{
            'type': 'tool-input-error',
            'toolCallId': toolCallId,
            'toolName': toolName,
            'input': inputText,
            if (meta?.providerExecuted == true) 'providerExecuted': true,
            if (meta?.dynamicTool == true) 'dynamic': true,
            if (meta?.title != null && meta!.title!.isNotEmpty)
              'title': meta.title,
            if (meta?.providerMetadata != null &&
                meta!.providerMetadata!.isNotEmpty)
              'providerMetadata': meta.providerMetadata!,
            'errorText': parsed.error!,
          };
          if (messageMeta != null) {
            yield <String, Object?>{
              'type': 'message-metadata',
              'messageMetadata': messageMeta,
            };
          }
        } else {
          yield <String, Object?>{
            'type': 'tool-input-available',
            'toolCallId': toolCallId,
            'toolName': toolName,
            'input': parsed.value,
            if (meta?.providerExecuted == true) 'providerExecuted': true,
            if (meta?.dynamicTool == true) 'dynamic': true,
            if (meta?.title != null && meta!.title!.isNotEmpty)
              'title': meta.title,
            if (meta?.providerMetadata != null &&
                meta!.providerMetadata!.isNotEmpty)
              'providerMetadata': meta.providerMetadata!,
          };
          if (messageMeta != null) {
            yield <String, Object?>{
              'type': 'message-metadata',
              'messageMetadata': messageMeta,
            };
          }
        }

      case LLMProviderToolCallPart(
          toolCallId: final toolCallId,
          toolName: final toolName,
          input: final input,
          providerExecuted: final providerExecuted,
          isDynamic: final dynamicTool,
          providerMetadata: final pm,
        ):
        yield <String, Object?>{
          'type': 'tool-input-available',
          'toolCallId': toolCallId,
          'toolName': toolName,
          'input': input,
          if (providerExecuted == true) 'providerExecuted': true,
          if (dynamicTool == true) 'dynamic': true,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        };
        if (messageMeta != null) {
          yield <String, Object?>{
            'type': 'message-metadata',
            'messageMetadata': messageMeta,
          };
        }

      case LLMProviderToolDeltaPart(
          toolCallId: final toolCallId,
          toolName: final toolName,
          status: final status,
          data: final data,
          providerMetadata: final pm,
        ):
        yield <String, Object?>{
          'type': 'data-provider-tool-delta',
          'id': toolCallId,
          'data': <String, Object?>{
            'toolCallId': toolCallId,
            'toolName': toolName,
            'status': status,
            if (data != null) 'data': data,
            if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
          },
        };
        if (messageMeta != null) {
          yield <String, Object?>{
            'type': 'message-metadata',
            'messageMetadata': messageMeta,
          };
        }

      case LLMProviderToolApprovalRequestPart(
          approvalId: final approvalId,
          toolCallId: final toolCallId,
        ):
        yield <String, Object?>{
          'type': 'tool-approval-request',
          'approvalId': approvalId,
          'toolCallId': toolCallId,
        };
        if (messageMeta != null) {
          yield <String, Object?>{
            'type': 'message-metadata',
            'messageMetadata': messageMeta,
          };
        }

      case LLMProviderToolResultPart(
          toolCallId: final toolCallId,
          result: final result,
          isError: final isError,
          preliminary: final preliminary,
          isDynamic: final dynamicTool,
        ):
        if (isError == true) {
          yield <String, Object?>{
            'type': 'tool-output-error',
            'toolCallId': toolCallId,
            'errorText': _stringifyUnknown(result),
            'providerExecuted': true,
            if (dynamicTool == true) 'dynamic': true,
          };
          if (messageMeta != null) {
            yield <String, Object?>{
              'type': 'message-metadata',
              'messageMetadata': messageMeta,
            };
          }
        } else {
          yield <String, Object?>{
            'type': 'tool-output-available',
            'toolCallId': toolCallId,
            'output': result,
            'providerExecuted': true,
            if (dynamicTool == true) 'dynamic': true,
            if (preliminary == true) 'preliminary': true,
          };
          if (messageMeta != null) {
            yield <String, Object?>{
              'type': 'message-metadata',
              'messageMetadata': messageMeta,
            };
          }
        }

      case LLMToolResultPart(result: final toolResult):
        if (toolResult.isError) {
          yield <String, Object?>{
            'type': 'tool-output-error',
            'toolCallId': toolResult.toolCallId,
            'errorText': _stringifyUnknown(toolResult.result),
          };
          if (messageMeta != null) {
            yield <String, Object?>{
              'type': 'message-metadata',
              'messageMetadata': messageMeta,
            };
          }
        } else {
          Object? value = toolResult.result;
          if (value is String) {
            final parsed = _tryDecodeJson(value);
            if (parsed.error == null) {
              value = parsed.value;
            }
          }
          if (value is Map && value['type'] == 'execution-denied') {
            yield <String, Object?>{
              'type': 'tool-output-denied',
              'toolCallId': toolResult.toolCallId,
            };
            if (messageMeta != null) {
              yield <String, Object?>{
                'type': 'message-metadata',
                'messageMetadata': messageMeta,
              };
            }
          } else {
            yield <String, Object?>{
              'type': 'tool-output-available',
              'toolCallId': toolResult.toolCallId,
              'output': value,
            };
            if (messageMeta != null) {
              yield <String, Object?>{
                'type': 'message-metadata',
                'messageMetadata': messageMeta,
              };
            }
          }
        }

      case LLMToolLoopBlockedPart(:final state):
        if (state is! ToolLoopBlockedState) break;
        if (toolApprovalBlockedStateData != null) {
          final extra = toolApprovalBlockedStateData(state);
          final data = <String, Object?>{
            'kind': 'tool-loop',
            'stepIndex': state.stepIndex,
            'approvalIds': state.toolApprovalRequests
                .map((r) => r.approvalId)
                .toList(growable: false),
            'toolCallIds': state.toolApprovalRequests
                .map((r) => r.toolCall.toolCallId)
                .toList(growable: false),
            if (extra != null) 'extra': extra,
          };
          if (data.isNotEmpty) {
            yield <String, Object?>{
              'type': 'data-tool-blocked',
              'data': data,
            };
            yield <String, Object?>{
              'type': 'data-tool-loop-blocked',
              'data': data,
            };
          }
        }
        if (messageMeta != null) {
          yield <String, Object?>{
            'type': 'message-metadata',
            'messageMetadata': messageMeta,
          };
        }

      case LLMProviderToolApprovalBlockedPart(:final state):
        if (state is! ProviderToolApprovalBlockedState) break;
        if (providerToolApprovalBlockedStateData != null) {
          final extra = providerToolApprovalBlockedStateData(state);
          final data = <String, Object?>{
            'kind': 'provider-tool-approval',
            'stepIndex': state.stepIndex,
            'approvalIds': state.approvalRequests
                .map((r) => r.approvalId)
                .toList(growable: false),
            'toolCallIds': state.approvalRequests
                .map((r) => r.toolCallId)
                .toList(growable: false),
            if (extra != null) 'extra': extra,
          };
          if (data.isNotEmpty) {
            yield <String, Object?>{
              'type': 'data-tool-blocked',
              'data': data,
            };
            yield <String, Object?>{
              'type': 'data-tool-approval-blocked',
              'data': data,
            };
          }
        }
        if (messageMeta != null) {
          yield <String, Object?>{
            'type': 'message-metadata',
            'messageMetadata': messageMeta,
          };
        }

      case LLMRawPart():
        // Only emitted when includeRawChunks is enabled. UI chunk schema does
        // not include raw chunks, so we ignore them here.
        break;

      case LLMSourceUrlPart(
          sourceId: final sourceId,
          url: final url,
          title: final title,
          providerMetadata: final pm,
        ):
        if (!sendSources) break;
        yield <String, Object?>{
          'type': 'source-url',
          'sourceId': sourceId,
          'url': url,
          if (title != null && title.isNotEmpty) 'title': title,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        };
        if (messageMeta != null) {
          yield <String, Object?>{
            'type': 'message-metadata',
            'messageMetadata': messageMeta,
          };
        }

      case LLMSourceDocumentPart(
          sourceId: final sourceId,
          mediaType: final mediaType,
          title: final title,
          filename: final filename,
          providerMetadata: final pm,
        ):
        if (!sendSources) break;
        yield <String, Object?>{
          'type': 'source-document',
          'sourceId': sourceId,
          'mediaType': mediaType,
          'title': title,
          if (filename != null && filename.isNotEmpty) 'filename': filename,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        };
        if (messageMeta != null) {
          yield <String, Object?>{
            'type': 'message-metadata',
            'messageMetadata': messageMeta,
          };
        }

      case LLMFilePart(
          mediaType: final mediaType,
          data: final data,
          providerMetadata: final pm,
        ):
        if (!sendFiles) break;
        final url = _toDataUri(mediaType: mediaType, data: data);
        yield <String, Object?>{
          'type': 'file',
          'url': url,
          'mediaType': mediaType,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        };
        if (messageMeta != null) {
          yield <String, Object?>{
            'type': 'message-metadata',
            'messageMetadata': messageMeta,
          };
        }

      case LLMErrorPart(error: final error):
        if (error is ToolApprovalRequiredError) {
          for (final req in error.state.toolApprovalRequests) {
            yield <String, Object?>{
              'type': 'tool-approval-request',
              // Some runtimes do not distinguish approvalId vs toolCallId.
              // Reuse toolCallId as a stable approvalId.
              'approvalId': req.approvalId,
              'toolCallId': req.toolCall.toolCallId,
            };
          }
          if (toolApprovalBlockedStateData != null) {
            final state = error.state;
            final extra = toolApprovalBlockedStateData(state);
            final data = <String, Object?>{
              'kind': 'tool-loop',
              'stepIndex': state.stepIndex,
              'approvalIds': state.toolApprovalRequests
                  .map((r) => r.approvalId)
                  .toList(growable: false),
              'toolCallIds': state.toolApprovalRequests
                  .map((r) => r.toolCall.toolCallId)
                  .toList(growable: false),
              if (extra != null) 'extra': extra,
            };
            if (data.isNotEmpty) {
              yield <String, Object?>{
                'type': 'data-tool-blocked',
                'data': data,
              };
              yield <String, Object?>{
                'type': 'data-tool-loop-blocked',
                'data': data,
              };
            }
          }
          if (sendFinish) {
            yield const <String, Object?>{
              'type': 'finish',
              'finishReason': 'tool-calls',
            };
          }
          return;
        }

        if (error is ProviderToolApprovalRequiredError) {
          if (providerToolApprovalBlockedStateData != null) {
            final state = error.state;
            final extra = providerToolApprovalBlockedStateData(state);
            final data = <String, Object?>{
              'kind': 'provider-tool-approval',
              'stepIndex': state.stepIndex,
              'approvalIds': state.approvalRequests
                  .map((r) => r.approvalId)
                  .toList(growable: false),
              'toolCallIds': state.approvalRequests
                  .map((r) => r.toolCallId)
                  .toList(growable: false),
              if (extra != null) 'extra': extra,
            };
            if (data.isNotEmpty) {
              yield <String, Object?>{
                'type': 'data-tool-blocked',
                'data': data,
              };
              yield <String, Object?>{
                'type': 'data-tool-approval-blocked',
                'data': data,
              };
            }
          }
          if (sendFinish) {
            yield const <String, Object?>{
              'type': 'finish',
              'finishReason': 'tool-calls',
            };
          }
          return;
        }

        yield <String, Object?>{
          'type': 'error',
          'errorText': onError != null ? onError(error) : error.message,
        };
        if (messageMeta != null) {
          yield <String, Object?>{
            'type': 'message-metadata',
            'messageMetadata': messageMeta,
          };
        }

      case LLMErrorRawPart(:final rawError, decodedError: final decoded):
        yield <String, Object?>{
          'type': 'error',
          'errorText': onError != null
              ? onError(decoded ?? rawError ?? 'Unknown error')
              : (decoded?.message ?? _stringifyUnknown(rawError)),
        };
        if (messageMeta != null) {
          yield <String, Object?>{
            'type': 'message-metadata',
            'messageMetadata': messageMeta,
          };
        }

      case LLMFinishPart(finishReason: final reason):
        if (!sendFinish) break;
        final meta =
            finishMessageMetadata != null ? finishMessageMetadata(part) : null;
        yield <String, Object?>{
          'type': 'finish',
          if (reason != null) 'finishReason': _encodeFinishReason(reason),
          if (meta != null) 'messageMetadata': meta,
        };

      default:
        // Ignore parts that are not part of the UI message stream contract
        // (e.g. request/response metadata snapshots, provider tool deltas).
        break;
    }
  }
}

/// Encodes UI message chunks into an SSE stream (`data: <json>\n\n`).
///
/// Upstream reference:
/// `repo-ref/ai/packages/ai/src/ui-message-stream/json-to-sse-transform-stream.ts`
Stream<String> uiMessageSseFromChunks(
  Stream<Map<String, Object?>> chunks,
) async* {
  await for (final chunk in chunks) {
    yield 'data: ${jsonEncode(chunk)}\n\n';
  }
  yield 'data: [DONE]\n\n';
}

/// Convenience: [LLMStreamPart] -> UI message chunks -> SSE.
Stream<String> uiMessageSseFromParts(
  Stream<LLMStreamPart> parts, {
  bool sendStart = true,
  bool sendFinish = true,
  bool sendReasoning = true,
  bool sendSources = false,
  bool sendFiles = true,
}) {
  return uiMessageSseFromChunks(
    uiMessageChunksFromParts(
      parts,
      sendStart: sendStart,
      sendFinish: sendFinish,
      sendReasoning: sendReasoning,
      sendSources: sendSources,
      sendFiles: sendFiles,
    ),
  );
}

String _requireNonEmptyId(String? id) {
  final trimmed = id?.trim();
  return (trimmed == null || trimmed.isEmpty) ? '1' : trimmed;
}

String _encodeFinishReason(LLMFinishReason reason) {
  switch (reason.unified) {
    case LLMUnifiedFinishReason.stop:
      return 'stop';
    case LLMUnifiedFinishReason.length:
      return 'length';
    case LLMUnifiedFinishReason.contentFilter:
      return 'content-filter';
    case LLMUnifiedFinishReason.toolCalls:
      return 'tool-calls';
    case LLMUnifiedFinishReason.error:
      return 'error';
    case LLMUnifiedFinishReason.other:
      return 'other';
  }
}

({Object value, String? error}) _tryDecodeJson(String content) {
  final trimmed = content.trim();
  if (trimmed.isEmpty) {
    return (value: const <String, dynamic>{}, error: null);
  }

  final looksJsonLike = trimmed.startsWith('{') ||
      trimmed.startsWith('[') ||
      trimmed == 'null' ||
      trimmed == 'true' ||
      trimmed == 'false' ||
      num.tryParse(trimmed) != null;

  if (!looksJsonLike) return (value: content, error: null);

  try {
    return (value: jsonDecode(trimmed), error: null);
  } catch (e) {
    return (value: content, error: 'Invalid JSON: $e');
  }
}

String _stringifyUnknown(Object? value) {
  if (value == null) return 'null';
  if (value is String) return value;
  try {
    return jsonEncode(value);
  } catch (_) {
    return value.toString();
  }
}

String _toDataUri({required String mediaType, required Object data}) {
  final String base64Data;
  if (data is String) {
    base64Data = data;
  } else if (data is Uint8List) {
    base64Data = base64Encode(data);
  } else {
    throw UiMessageStreamError(
      cause: data,
      message:
          'LLMFilePart.data must be a String (base64) or Uint8List (bytes).',
    );
  }

  return 'data:$mediaType;base64,$base64Data';
}

class _ToolInputMeta {
  final String toolName;
  final bool? providerExecuted;
  final bool? dynamicTool;
  final String? title;
  final Map<String, dynamic>? providerMetadata;

  const _ToolInputMeta({
    required this.toolName,
    this.providerExecuted,
    this.dynamicTool,
    this.title,
    this.providerMetadata,
  });
}
