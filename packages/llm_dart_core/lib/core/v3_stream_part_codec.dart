import 'dart:convert';
import 'dart:typed_data';

import '../models/chat_models.dart';
import '../models/tool_models.dart';
import 'capability.dart';
import 'llm_error.dart';
import 'stream_parts.dart';

/// AI SDK v3-inspired JSON codec for [LLMStreamPart].
///
/// This codec is primarily intended for fixture-driven tests and golden files.
/// It encodes a stream of parts into a stable JSON object per part, using a
/// `type` discriminator aligned with Vercel AI SDK v3 stream parts.
///
/// Design notes:
/// - This codec is best-effort and may intentionally omit fields that are not
///   part of the canonical v3 shape.
/// - Some `llm_dart` part types are richer than the v3 shape (e.g. `text` on
///   `LLMTextEndPart`). These fields are preserved in Dart objects but omitted
///   from the v3 JSON encoding.

typedef V3JsonMap = Map<String, dynamic>;

/// How to encode [LLMFilePart.data] when it contains binary bytes ([Uint8List]).
///
/// AI SDK v3 represents binary file data as `Uint8Array` in memory. When
/// serialized to JSON, it may be represented as a JSON array of bytes or a
/// base64-encoded string. This codec defaults to base64 to keep fixtures small,
/// but can emit byte arrays when needed for round-trip tests.
enum V3FileDataEncoding {
  /// Encode bytes as a base64 string.
  base64,

  /// Encode bytes as a JSON array of integers (0..255).
  bytes,
}

class _DecodedChatResponse extends ChatResponse
    implements ChatResponseWithFinishReason {
  @override
  final LLMFinishReason? finishReason;

  @override
  final UsageInfo? usage;

  @override
  final Map<String, dynamic>? providerMetadata;

  _DecodedChatResponse({
    this.finishReason,
    this.usage,
    this.providerMetadata,
  });

  @override
  String? get text => null;

  @override
  List<ToolCall>? get toolCalls => null;
}

LLMFinishReason _defaultFinishReasonForResponse(ChatResponse response) {
  final hasToolCalls =
      response.toolCalls != null && response.toolCalls!.isNotEmpty;
  if (hasToolCalls) {
    return const LLMFinishReason(
      unified: LLMUnifiedFinishReason.toolCalls,
      raw: null,
    );
  }

  final hasText = response.text != null && response.text!.trim().isNotEmpty;
  final hasThinking =
      response.thinking != null && response.thinking!.trim().isNotEmpty;
  if (hasText || hasThinking) {
    return const LLMFinishReason(
      unified: LLMUnifiedFinishReason.stop,
      raw: null,
    );
  }

  return const LLMFinishReason(
    unified: LLMUnifiedFinishReason.other,
    raw: null,
  );
}

/// Encodes a list/stream of [LLMStreamPart] into AI SDK v3-style JSON objects.
///
/// This encoder performs a small amount of normalization to make fixture tests
/// deterministic:
/// - Injects missing block ids for text/reasoning blocks (counter-based).
/// - Converts tool-call start/delta/end parts into `tool-input-*` parts and
///   emits a final `tool-call` part once input is complete.
List<V3JsonMap> encodeV3StreamParts(
  Iterable<LLMStreamPart> parts, {
  bool injectMissingBlockIds = true,
  V3FileDataEncoding fileDataEncoding = V3FileDataEncoding.base64,
}) {
  final state = _V3EncodeState(
    injectMissingBlockIds: injectMissingBlockIds,
    fileDataEncoding: fileDataEncoding,
  );
  final out = <V3JsonMap>[];

  for (final part in parts) {
    out.addAll(_encodeV3Part(part, state));
  }

  return out;
}

/// Decodes AI SDK v3-style JSON objects into [LLMStreamPart]s.
///
/// This decoder is intended for fixture-driven tests and round-trip debugging.
/// It is best-effort and may throw [FormatException] if the input stream is
/// structurally invalid (e.g. missing required fields).
List<LLMStreamPart> decodeV3StreamParts(Iterable<V3JsonMap> objects) {
  final state = _V3DecodeState();
  final out = <LLMStreamPart>[];

  for (final obj in objects) {
    final type = obj['type'];
    if (type is! String || type.isEmpty) {
      throw const FormatException('v3 part missing non-empty "type".');
    }

    final providerMetadata = _asStringKeyedMap(obj['providerMetadata']);

    switch (type) {
      case 'stream-start':
        out.add(
          LLMStreamStartPart(
            warnings: _asListOfStringKeyedMaps(obj['warnings']) ?? const [],
          ),
        );
        break;

      case 'response-metadata':
        final id = obj['id'] as String?;
        final timestampRaw = obj['timestamp'];
        final modelId = obj['modelId'] as String?;
        out.add(
          LLMResponseMetadataPart(
            id: (id != null && id.isNotEmpty) ? id : null,
            timestamp:
                timestampRaw != null ? _decodeV3Timestamp(timestampRaw) : null,
            model: (modelId != null && modelId.isNotEmpty) ? modelId : null,
            providerMetadata: providerMetadata,
            raw: _asStringKeyedMap(obj['raw']),
          ),
        );
        break;

      case 'text-start':
        final id = _requireString(obj, 'id');
        state.text.onStart(id);
        out.add(
          LLMTextStartPart(blockId: id, providerMetadata: providerMetadata),
        );
        break;

      case 'text-delta':
        final id = _requireString(obj, 'id');
        final delta = _requireString(obj, 'delta');
        state.text.onDelta(id, delta);
        out.add(
          LLMTextDeltaPart(delta,
              blockId: id, providerMetadata: providerMetadata),
        );
        break;

      case 'text-end':
        final id = _requireString(obj, 'id');
        final text = state.text.onEnd(id);
        out.add(
          LLMTextEndPart(text, blockId: id, providerMetadata: providerMetadata),
        );
        break;

      case 'reasoning-start':
        final id = _requireString(obj, 'id');
        state.reasoning.onStart(id);
        out.add(
          LLMReasoningStartPart(
              blockId: id, providerMetadata: providerMetadata),
        );
        break;

      case 'reasoning-delta':
        final id = _requireString(obj, 'id');
        final delta = _requireString(obj, 'delta');
        state.reasoning.onDelta(id, delta);
        out.add(
          LLMReasoningDeltaPart(
            delta,
            blockId: id,
            providerMetadata: providerMetadata,
          ),
        );
        break;

      case 'reasoning-end':
        final id = _requireString(obj, 'id');
        final thinking = state.reasoning.onEnd(id);
        state.reasoning.currentId = null;
        out.add(
          LLMReasoningEndPart(
            thinking,
            blockId: id,
            providerMetadata: providerMetadata,
          ),
        );
        break;

      case 'tool-input-start':
        final id = _requireString(obj, 'id');
        final toolName = _requireString(obj, 'toolName');
        final providerExecuted = obj['providerExecuted'] == true ? true : null;
        final dynamicTool = obj['dynamic'] == true ? true : null;
        final title = obj['title'] as String?;

        state.toolInput.onStart(id);
        state.rememberTool(id: id, toolName: toolName);

        out.add(
          LLMToolInputStartPart(
            id: id,
            toolName: toolName,
            providerExecuted: providerExecuted,
            isDynamic: dynamicTool,
            title: (title != null && title.isNotEmpty) ? title : null,
            providerMetadata: providerMetadata,
          ),
        );
        break;

      case 'tool-input-delta':
        final id = _requireString(obj, 'id');
        final delta = _requireString(obj, 'delta');
        state.toolInput.onDelta(id, delta);
        out.add(
          LLMToolInputDeltaPart(
            id: id,
            delta: delta,
            providerMetadata: providerMetadata,
          ),
        );
        break;

      case 'tool-input-end':
        final id = _requireString(obj, 'id');
        state.toolInput.onEnd(id);
        out.add(
            LLMToolInputEndPart(id: id, providerMetadata: providerMetadata));
        break;

      case 'tool-call':
        final toolCallId = _requireString(obj, 'toolCallId');
        final toolName = _requireString(obj, 'toolName');
        final inputRaw = obj['input'];
        if (inputRaw is! String) {
          throw const FormatException('v3 tool-call missing string "input".');
        }
        final providerExecuted = obj['providerExecuted'] == true ? true : null;
        final dynamicTool = obj['dynamic'] == true ? true : null;

        if (!state.emittedToolCallIds.add(toolCallId)) {
          throw FormatException(
              'v3 tool-call duplicated for toolCallId: $toolCallId');
        }

        final existing = state.toolById[toolCallId];
        if (existing != null && existing.toolName != toolName) {
          throw FormatException(
            'v3 tool-call toolName mismatch for toolCallId=$toolCallId: '
            'existing=${existing.toolName}, got=$toolName',
          );
        }

        // Preserve the original v3 shape: `tool-call.input` is a stringified JSON
        // object. Do not decode it, otherwise whitespace/minification differences
        // would break fixture round-trips.
        state.rememberTool(id: toolCallId, toolName: toolName, input: inputRaw);

        out.add(
          LLMProviderToolCallPart(
            toolCallId: toolCallId,
            toolName: toolName,
            input: inputRaw,
            providerExecuted: providerExecuted,
            isDynamic: dynamicTool,
            providerMetadata: providerMetadata,
          ),
        );
        break;

      case 'tool-result':
        final toolCallId = _requireString(obj, 'toolCallId');
        final toolName = _requireString(obj, 'toolName');
        final result = obj['result'];
        if (result == null) {
          throw const FormatException(
              'v3 tool-result missing non-null "result".');
        }
        final isError = obj['isError'] == true ? true : null;
        final preliminary = obj['preliminary'] == true ? true : null;
        final dynamicTool = obj['dynamic'] == true ? true : null;

        final existing = state.toolById[toolCallId];
        if (existing != null && existing.toolName != toolName) {
          throw FormatException(
            'v3 tool-result toolName mismatch for toolCallId=$toolCallId: '
            'existing=${existing.toolName}, got=$toolName',
          );
        }

        final toolState = state.toolResultStateByToolCallId
            .putIfAbsent(toolCallId, _ToolResultDecodeState.new);
        if (toolState.seenFinal) {
          throw FormatException(
            'v3 tool-result emitted after final result for toolCallId: $toolCallId',
          );
        }
        if (preliminary != true) {
          toolState.seenFinal = true;
        }
        toolState.seenAny = true;

        state.rememberTool(id: toolCallId, toolName: toolName);

        out.add(
          LLMProviderToolResultPart(
            toolCallId: toolCallId,
            toolName: toolName,
            result: _normalizeJsonLike(result),
            isError: isError,
            preliminary: preliminary,
            isDynamic: dynamicTool,
            providerMetadata: providerMetadata,
          ),
        );
        break;

      case 'tool-approval-request':
        final approvalId = _requireString(obj, 'approvalId');
        final toolCallId = _requireString(obj, 'toolCallId');
        if (!state.emittedApprovalIds.add(approvalId)) {
          throw FormatException(
              'v3 tool-approval-request duplicated approvalId: $approvalId');
        }

        final remembered = state.toolById[toolCallId];
        if (remembered == null || remembered.toolName.isEmpty) {
          throw FormatException(
            'v3 tool-approval-request references unknown toolCallId: $toolCallId',
          );
        }
        final fallbackInput = state.toolInput.fullInputForId(toolCallId);

        out.add(
          LLMProviderToolApprovalRequestPart(
            approvalId: approvalId,
            toolCallId: toolCallId,
            toolName: remembered?.toolName ?? 'unknown',
            input: remembered?.input ??
                (fallbackInput != null && fallbackInput.isNotEmpty
                    ? _decodeJsonIfPossible(fallbackInput)
                    : null),
            providerMetadata: providerMetadata,
          ),
        );
        break;

      case 'source':
        final sourceType = _requireString(obj, 'sourceType');
        final id = _requireString(obj, 'id');
        if (!state.emittedSourceIds.add(id)) {
          throw FormatException('v3 source duplicated id: $id');
        }
        switch (sourceType) {
          case 'url':
            final url = _requireString(obj, 'url');
            final title = obj['title'] as String?;
            out.add(
              LLMSourceUrlPart(
                sourceId: id,
                url: url,
                title: (title != null && title.isNotEmpty) ? title : null,
                providerMetadata: providerMetadata,
              ),
            );
            break;
          case 'document':
            final mediaType = _requireString(obj, 'mediaType');
            final title = _requireString(obj, 'title');
            final filename = obj['filename'] as String?;
            out.add(
              LLMSourceDocumentPart(
                sourceId: id,
                mediaType: mediaType,
                title: title,
                filename:
                    (filename != null && filename.isNotEmpty) ? filename : null,
                providerMetadata: providerMetadata,
              ),
            );
            break;
          default:
            throw FormatException('Unsupported v3 sourceType: $sourceType');
        }
        break;

      case 'file':
        final mediaType = _requireString(obj, 'mediaType');
        final data = _decodeV3FileData(obj['data']);
        out.add(
          LLMFilePart(
            mediaType: mediaType,
            data: data,
            providerMetadata: providerMetadata,
          ),
        );
        break;

      case 'finish':
        final usageRaw = obj['usage'];
        if (usageRaw is! Map) {
          throw const FormatException('v3 finish missing object "usage".');
        }
        final finishReasonRaw = obj['finishReason'];
        if (finishReasonRaw is! Map) {
          throw const FormatException(
              'v3 finish missing object "finishReason".');
        }

        final reason =
            _decodeV3FinishReason(_asStringKeyedMap(finishReasonRaw)!);
        final usage = _decodeV3Usage(_asStringKeyedMap(usageRaw)!);

        out.add(
          LLMFinishPart(
            _DecodedChatResponse(
              finishReason: reason,
              usage: usage,
              providerMetadata: providerMetadata,
            ),
            usage: usage,
            finishReason: reason,
          ),
        );
        break;

      case 'raw':
        final rawValue = obj['rawValue'];
        if (rawValue is Map) {
          // Tool loop step boundaries (non-canonical v3; injected by llm_dart tool loops).
          final kind = rawValue['kind'];
          if (kind == 'step-start') {
            final stepIndexRaw = rawValue['stepIndex'];
            final stepIndex = stepIndexRaw is int
                ? stepIndexRaw
                : (stepIndexRaw is num ? stepIndexRaw.toInt() : null);
            if (stepIndex != null && stepIndex >= 0) {
              out.add(LLMStepStartPart(stepIndex));
              break;
            }
          }

          if (kind == 'step-finish') {
            final stepIndexRaw = rawValue['stepIndex'];
            final stepIndex = stepIndexRaw is int
                ? stepIndexRaw
                : (stepIndexRaw is num ? stepIndexRaw.toInt() : null);
            if (stepIndex == null || stepIndex < 0) {
              out.add(LLMRawPart(_normalizeJsonLike(rawValue)));
              break;
            }

            final usageRaw = _asStringKeyedMap(rawValue['usage']);
            final finishReasonRaw = _asStringKeyedMap(rawValue['finishReason']);
            final usage = usageRaw != null ? _decodeV3Usage(usageRaw) : null;
            final finishReason = finishReasonRaw != null
                ? _decodeV3FinishReason(finishReasonRaw)
                : null;

            final responseProviderMetadata =
                _asStringKeyedMap(rawValue['providerMetadata']);

            final toolCallsRaw = rawValue['toolCalls'];
            final toolResultsRaw = rawValue['toolResults'];

            final toolCalls = <ToolCall>[];
            if (toolCallsRaw is List) {
              for (final v in toolCallsRaw) {
                if (v is Map) {
                  toolCalls.add(ToolCall.fromJson(v.cast<String, dynamic>()));
                }
              }
            }

            final toolResults = <ToolResult>[];
            if (toolResultsRaw is List) {
              for (final v in toolResultsRaw) {
                if (v is Map) {
                  toolResults
                      .add(ToolResult.fromJson(v.cast<String, dynamic>()));
                }
              }
            }

            out.add(
              LLMStepFinishPart(
                stepIndex: stepIndex,
                response: _DecodedChatResponse(
                  finishReason: finishReason,
                  usage: usage,
                  providerMetadata: responseProviderMetadata,
                ),
                usage: usage,
                finishReason: finishReason,
                toolCalls: toolCalls,
                toolResults: toolResults,
              ),
            );
            break;
          }

          // Backward compatibility: historically we wrapped non-canonical parts
          // in `rawValue.kind=...` envelopes for fixture round-trips. Newer
          // fixtures omit `kind` and use a minimal, self-describing shape.

          // Provider tool delta (preferred): { toolCallId, toolName, status, ... }
          final toolCallId = rawValue['toolCallId'] as String?;
          final toolName = rawValue['toolName'] as String?;
          final status = rawValue['status'] as String?;
          if (toolCallId != null &&
              toolCallId.isNotEmpty &&
              toolName != null &&
              toolName.isNotEmpty &&
              status != null &&
              status.isNotEmpty) {
            final data = rawValue['data'];
            final pm = _asStringKeyedMap(rawValue['providerMetadata']);
            out.add(
              LLMProviderToolDeltaPart(
                toolCallId: toolCallId,
                toolName: toolName,
                status: status,
                data: _normalizeJsonLike(data),
                providerMetadata: pm,
              ),
            );
            break;
          }

          // Provider metadata snapshot (preferred): { providerMetadata: {...} }
          // Only treat it as a metadata snapshot when the object contains *only*
          // this single key, otherwise preserve as a raw chunk.
          if (rawValue.length == 1 &&
              rawValue.containsKey('providerMetadata')) {
            final pm = _asStringKeyedMap(rawValue['providerMetadata']);
            if (pm != null) {
              out.add(LLMProviderMetadataPart(pm));
              break;
            }
          }

          // Legacy envelopes: { kind: 'provider-metadata' | 'provider-tool-delta', ... }
          // (Note: step boundaries are handled above.)
          if (kind == 'provider-metadata') {
            final pm = _asStringKeyedMap(rawValue['providerMetadata']);
            if (pm != null) {
              out.add(LLMProviderMetadataPart(pm));
              break;
            }
          }
          if (kind == 'provider-tool-delta') {
            final toolCallId = rawValue['toolCallId'] as String?;
            final toolName = rawValue['toolName'] as String?;
            final status = rawValue['status'] as String?;
            final data = rawValue['data'];
            final pm = _asStringKeyedMap(rawValue['providerMetadata']);
            if (toolCallId != null &&
                toolCallId.isNotEmpty &&
                toolName != null &&
                toolName.isNotEmpty &&
                status != null &&
                status.isNotEmpty) {
              out.add(
                LLMProviderToolDeltaPart(
                  toolCallId: toolCallId,
                  toolName: toolName,
                  status: status,
                  data: _normalizeJsonLike(data),
                  providerMetadata: pm,
                ),
              );
              break;
            }
          }
        }
        out.add(LLMRawPart(_normalizeJsonLike(rawValue)));
        break;

      case 'error':
        final rawError = _normalizeJsonLike(obj['error']);
        out.add(
          LLMErrorRawPart(
            rawError,
            decodedError: _decodeV3Error(rawError),
          ),
        );
        break;

      default:
        // Preserve unknown parts as raw to keep decoding forward-compatible.
        out.add(LLMRawPart(_normalizeJsonLike(obj)));
        break;
    }
  }

  for (final entry in state.toolResultStateByToolCallId.entries) {
    final toolCallId = entry.key;
    final toolState = entry.value;
    if (toolState.seenAny && !toolState.seenFinal) {
      throw FormatException(
        'v3 tool-result missing final (non-preliminary) result for toolCallId: $toolCallId',
      );
    }
  }

  return out;
}

/// Encodes a single part into one or more v3 JSON objects.
///
/// Most parts map 1:1. Tool-call lifecycle parts may map to multiple outputs.
List<V3JsonMap> _encodeV3Part(LLMStreamPart part, _V3EncodeState state) {
  switch (part) {
    case LLMStreamStartPart(:final warnings):
      return [
        {
          'type': 'stream-start',
          'warnings': warnings,
        },
      ];

    case LLMResponseMetadataPart(
        id: final id,
        timestamp: final timestamp,
        model: final model,
      ):
      return [
        {
          'type': 'response-metadata',
          if (id != null && id.isNotEmpty) 'id': id,
          if (timestamp != null) 'timestamp': timestamp.toIso8601String(),
          if (model != null && model.isNotEmpty) 'modelId': model,
        },
      ];

    // Tool loop step boundaries are not part of the canonical AI SDK v3 stream
    // shape. Preserve them as raw passthroughs for fixtures/debugging.
    case LLMStepStartPart(:final stepIndex):
      return [
        {
          'type': 'raw',
          'rawValue': {
            'kind': 'step-start',
            'stepIndex': stepIndex,
          },
        },
      ];

    case LLMStepFinishPart(
        stepIndex: final stepIndex,
        response: final response,
        usage: final usage,
        finishReason: final finishReason,
        toolCalls: final toolCalls,
        toolResults: final toolResults,
      ):
      final mergedUsage = usage ?? response.usage;
      final mergedFinishReason = finishReason ??
          (response is ChatResponseWithFinishReason
              ? response.finishReason
              : null);
      final responseProviderMetadata = response.providerMetadata;

      return [
        {
          'type': 'raw',
          'rawValue': {
            'kind': 'step-finish',
            'stepIndex': stepIndex,
            if (mergedUsage != null) 'usage': _encodeV3Usage(mergedUsage),
            if (mergedFinishReason != null)
              'finishReason': _encodeV3FinishReason(mergedFinishReason),
            if (responseProviderMetadata != null &&
                responseProviderMetadata.isNotEmpty)
              'providerMetadata': responseProviderMetadata,
            if (toolCalls.isNotEmpty)
              'toolCalls': toolCalls.map((c) => c.toJson()).toList(),
            if (toolResults.isNotEmpty)
              'toolResults': toolResults.map((r) => r.toJson()).toList(),
          },
        },
      ];

    case LLMTextStartPart(blockId: final blockId, providerMetadata: final pm):
      final id = state.text.ensureBlockId(blockId);
      state.text.currentId = id;
      return [
        {
          'type': 'text-start',
          'id': id,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        },
      ];

    case LLMTextDeltaPart(
        :final delta,
        blockId: final blockId,
        providerMetadata: final pm,
      ):
      final id = state.text.resolveId(blockId);
      return [
        {
          'type': 'text-delta',
          'id': id,
          'delta': delta,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        },
      ];

    case LLMTextEndPart(blockId: final blockId, providerMetadata: final pm):
      final id = state.text.resolveId(blockId);
      state.text.currentId = null;
      return [
        {
          'type': 'text-end',
          'id': id,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        },
      ];

    case LLMReasoningStartPart(
        blockId: final blockId,
        providerMetadata: final pm,
      ):
      final id = state.reasoning.ensureBlockId(blockId);
      state.reasoning.currentId = id;
      return [
        {
          'type': 'reasoning-start',
          'id': id,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        },
      ];

    case LLMReasoningDeltaPart(
        :final delta,
        blockId: final blockId,
        providerMetadata: final pm,
      ):
      final id = state.reasoning.resolveId(blockId);
      return [
        {
          'type': 'reasoning-delta',
          'id': id,
          'delta': delta,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        },
      ];

    case LLMReasoningEndPart(
        blockId: final blockId,
        providerMetadata: final pm,
      ):
      final id = state.reasoning.resolveId(blockId);
      state.reasoning.currentId = null;
      return [
        {
          'type': 'reasoning-end',
          'id': id,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        },
      ];

    // Canonical v3 tool input parts:
    case LLMToolInputStartPart(
        id: final id,
        toolName: final toolName,
        providerMetadata: final pm,
        providerExecuted: final providerExecuted,
        isDynamic: final dynamicTool,
        title: final title,
      ):
      return [
        {
          'type': 'tool-input-start',
          'id': id,
          'toolName': toolName,
          if (providerExecuted == true) 'providerExecuted': true,
          if (dynamicTool == true) 'dynamic': true,
          if (title != null && title.isNotEmpty) 'title': title,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        },
      ];

    case LLMToolInputDeltaPart(
        id: final id,
        delta: final delta,
        providerMetadata: final pm,
      ):
      return [
        {
          'type': 'tool-input-delta',
          'id': id,
          'delta': delta,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        },
      ];

    case LLMToolInputEndPart(id: final id, providerMetadata: final pm):
      return [
        {
          'type': 'tool-input-end',
          'id': id,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        },
      ];

    // Local tool call lifecycle (client-executed function tools):
    case LLMToolCallStartPart(:final toolCall):
      state.toolInput.onStart(toolCall);
      final out = <V3JsonMap>[
        {
          'type': 'tool-input-start',
          'id': toolCall.id,
          'toolName': toolCall.function.name,
        },
      ];
      if (toolCall.function.arguments.isNotEmpty) {
        state.toolInput.onDelta(toolCall);
        out.add({
          'type': 'tool-input-delta',
          'id': toolCall.id,
          'delta': toolCall.function.arguments,
        });
      }
      return out;

    case LLMToolCallDeltaPart(:final toolCall):
      state.toolInput.onDelta(toolCall);
      return [
        {
          'type': 'tool-input-delta',
          'id': toolCall.id,
          'delta': toolCall.function.arguments,
        },
      ];

    case LLMToolCallEndPart(:final toolCallId):
      final completed = state.toolInput.onEnd(toolCallId);
      final out = <V3JsonMap>[
        {
          'type': 'tool-input-end',
          'id': toolCallId,
        },
      ];
      if (completed != null) {
        out.add({
          'type': 'tool-call',
          'toolCallId': completed.id,
          'toolName': completed.toolName,
          'input': completed.input,
          // client-executed tool call: omit providerExecuted
        });
      }
      return out;

    case LLMToolResultPart(:final result):
      final decoded = _decodeJsonIfPossible(result.content);
      if (decoded == null) {
        throw StateError(
          'v3 tool-result.result must be non-null. '
          'ToolResult.content decoded to null for toolCallId='
          '${result.toolCallId}.',
        );
      }
      return [
        {
          'type': 'tool-result',
          'toolCallId': result.toolCallId,
          'toolName': state.toolInput.toolNameForToolCallId(result.toolCallId),
          'result': decoded,
          if (result.isError) 'isError': true,
          if (result.metadata != null && result.metadata!.isNotEmpty)
            'providerMetadata': {'tool': result.metadata},
        },
      ];

    // Provider-executed tools (built-in tools):
    case LLMProviderToolCallPart(
        toolCallId: final id,
        toolName: final toolName,
        input: final input,
        providerExecuted: final providerExecuted,
        isDynamic: final dynamicTool,
        providerMetadata: final pm,
      ):
      return [
        {
          'type': 'tool-call',
          'toolCallId': id,
          'toolName': toolName,
          'input': _stringifyToolInput(input),
          if (providerExecuted == true) 'providerExecuted': true,
          if (dynamicTool == true) 'dynamic': true,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        },
      ];

    case LLMProviderToolResultPart(
        toolCallId: final id,
        toolName: final toolName,
        result: final result,
        isError: final isError,
        preliminary: final preliminary,
        isDynamic: final dynamicTool,
        providerMetadata: final pm,
      ):
      if (result == null) {
        throw StateError(
          'v3 tool-result.result must be non-null. '
          'LLMProviderToolResultPart.result was null for toolCallId=$id.',
        );
      }
      return [
        {
          'type': 'tool-result',
          'toolCallId': id,
          'toolName': toolName,
          'result': _normalizeJsonLike(result),
          if (isError == true) 'isError': true,
          if (preliminary == true) 'preliminary': true,
          if (dynamicTool == true) 'dynamic': true,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        },
      ];

    case LLMProviderToolApprovalRequestPart(
        approvalId: final approvalId,
        toolCallId: final toolCallId,
        providerMetadata: final pm,
      ):
      return [
        {
          'type': 'tool-approval-request',
          'approvalId': approvalId,
          'toolCallId': toolCallId,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        },
      ];

    // Sources:
    case LLMSourceUrlPart(
        sourceId: final sourceId,
        url: final url,
        title: final title,
        providerMetadata: final pm,
      ):
      return [
        {
          'type': 'source',
          'sourceType': 'url',
          'id': sourceId,
          'url': url,
          if (title != null && title.isNotEmpty) 'title': title,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        },
      ];

    // Files:
    case LLMFilePart(
        mediaType: final mediaType,
        data: final data,
        providerMetadata: final pm,
      ):
      final Object encodedData;
      if (data is Uint8List) {
        encodedData = switch (state.fileDataEncoding) {
          V3FileDataEncoding.base64 => base64Encode(data),
          V3FileDataEncoding.bytes => data.toList(growable: false),
        };
      } else {
        encodedData = data as String;
      }
      return [
        {
          'type': 'file',
          'mediaType': mediaType,
          'data': encodedData,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        },
      ];

    case LLMSourceDocumentPart(
        sourceId: final sourceId,
        mediaType: final mediaType,
        title: final title,
        filename: final filename,
        providerMetadata: final pm,
      ):
      return [
        {
          'type': 'source',
          'sourceType': 'document',
          'id': sourceId,
          'mediaType': mediaType,
          'title': title,
          if (filename != null && filename.isNotEmpty) 'filename': filename,
          if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
        },
      ];

    // Finish:
    case LLMFinishPart(
        usage: final usage,
        finishReason: final finishReason,
        response: final response,
      ):
      final mergedUsage = usage ?? response.usage;
      final mergedFinishReason = finishReason ??
          (response is ChatResponseWithFinishReason
              ? response.finishReason
              : null);
      final responseProviderMetadata = response.providerMetadata;
      return [
        {
          'type': 'finish',
          'usage': _encodeV3Usage(mergedUsage ?? const UsageInfo()),
          'finishReason': _encodeV3FinishReason(
            mergedFinishReason ?? _defaultFinishReasonForResponse(response),
          ),
          if (responseProviderMetadata != null &&
              responseProviderMetadata.isNotEmpty)
            'providerMetadata': responseProviderMetadata,
        },
      ];

    // Error:
    case LLMErrorPart(:final error):
      return [
        {
          'type': 'error',
          'error': _encodeError(error),
        },
      ];

    case LLMErrorRawPart(:final rawError):
      return [
        {
          'type': 'error',
          'error': _normalizeJsonLike(rawError),
        },
      ];

    // Provider metadata snapshots:
    case LLMProviderMetadataPart(:final providerMetadata):
      return [
        {
          'type': 'raw',
          'rawValue': {
            'providerMetadata': providerMetadata,
          },
        },
      ];

    // Raw passthrough (AI SDK v3 `raw` part).
    case LLMRawPart(:final rawValue):
      return [
        {
          'type': 'raw',
          'rawValue': _normalizeJsonLike(rawValue),
        },
      ];

    // Provider tool delta is not part of the canonical AI SDK v3 shape.
    // Preserve it as a raw passthrough for fixtures/debugging.
    case LLMProviderToolDeltaPart(
        toolCallId: final toolCallId,
        toolName: final toolName,
        status: final status,
        data: final data,
        providerMetadata: final pm,
      ):
      return [
        {
          'type': 'raw',
          'rawValue': {
            'toolCallId': toolCallId,
            'toolName': toolName,
            'status': status,
            if (data != null) 'data': _normalizeJsonLike(data),
            if (pm != null && pm.isNotEmpty) 'providerMetadata': pm,
          },
        },
      ];
  }
}

V3JsonMap _encodeV3Usage(UsageInfo usage) {
  final inputTotal = usage.promptTokens;
  final inputCacheRead = usage.promptTokensCacheRead;
  final inputNoCache = usage.promptTokensNoCache ??
      ((inputTotal != null && inputCacheRead != null)
          ? (inputTotal - inputCacheRead)
          : null);
  final inputCacheWrite = usage.promptTokensCacheWrite;

  final outputTotal = usage.completionTokens;
  final outputReasoning = usage.reasoningTokens;
  final outputText = usage.completionTokensText ??
      ((outputTotal != null && outputReasoning != null)
          ? (outputTotal - outputReasoning)
          : null);

  return {
    'inputTokens': {
      if (inputTotal != null) 'total': inputTotal,
      if (inputNoCache != null) 'noCache': inputNoCache,
      if (inputCacheRead != null) 'cacheRead': inputCacheRead,
      if (inputCacheWrite != null) 'cacheWrite': inputCacheWrite,
    },
    'outputTokens': {
      if (outputTotal != null) 'total': outputTotal,
      if (outputText != null) 'text': outputText,
      if (outputReasoning != null) 'reasoning': outputReasoning,
    },
    if (usage.raw != null && usage.raw!.isNotEmpty)
      'raw': _normalizeJsonLike(usage.raw),
  };
}

V3JsonMap _encodeV3FinishReason(LLMFinishReason reason) => {
      'unified': _encodeUnifiedFinishReason(reason.unified),
      if (reason.raw != null) 'raw': reason.raw,
    };

LLMFinishReason _decodeV3FinishReason(V3JsonMap obj) {
  final unifiedRaw = obj['unified'];
  if (unifiedRaw is! String || unifiedRaw.isEmpty) {
    throw const FormatException('v3 finishReason missing non-empty "unified".');
  }

  final unified = switch (unifiedRaw) {
    'stop' => LLMUnifiedFinishReason.stop,
    'length' => LLMUnifiedFinishReason.length,
    'content-filter' => LLMUnifiedFinishReason.contentFilter,
    'tool-calls' => LLMUnifiedFinishReason.toolCalls,
    'error' => LLMUnifiedFinishReason.error,
    'other' => LLMUnifiedFinishReason.other,
    _ => LLMUnifiedFinishReason.other,
  };

  final raw = obj['raw'] as String?;
  return LLMFinishReason(unified: unified, raw: raw);
}

UsageInfo _decodeV3Usage(V3JsonMap obj) {
  final input = _asStringKeyedMap(obj['inputTokens']) ?? const {};
  final output = _asStringKeyedMap(obj['outputTokens']) ?? const {};
  final raw = _asStringKeyedMap(obj['raw']);

  int? asInt(dynamic v) => v is int ? v : (v is num ? v.toInt() : null);

  final inputTotal = asInt(input['total']);
  final inputNoCache = asInt(input['noCache']);
  final inputCacheRead = asInt(input['cacheRead']);
  final inputCacheWrite = asInt(input['cacheWrite']);

  final outputTotal = asInt(output['total']);
  final outputText = asInt(output['text']);
  final outputReasoning = asInt(output['reasoning']);

  return UsageInfo(
    promptTokens: inputTotal,
    completionTokens: outputTotal,
    totalTokens: (inputTotal != null && outputTotal != null)
        ? (inputTotal + outputTotal)
        : null,
    reasoningTokens: outputReasoning,
    promptTokensCacheRead: inputCacheRead,
    promptTokensNoCache: inputNoCache,
    promptTokensCacheWrite: inputCacheWrite,
    completionTokensText: outputText,
    raw: raw,
  );
}

String _encodeUnifiedFinishReason(LLMUnifiedFinishReason reason) {
  switch (reason) {
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

Object _encodeError(LLMError error) => {
      'name': error.runtimeType.toString(),
      'message': error.message,
    };

String _stringifyToolInput(Object? input) {
  if (input == null) return 'null';
  if (input is String) return input;
  try {
    return jsonEncode(input);
  } catch (_) {
    return input.toString();
  }
}

Object? _decodeJsonIfPossible(String content) {
  final trimmed = content.trim();
  if (trimmed.isEmpty) return '';
  if (!(trimmed.startsWith('{') ||
      trimmed.startsWith('[') ||
      trimmed == 'null' ||
      trimmed == 'true' ||
      trimmed == 'false' ||
      num.tryParse(trimmed) != null)) {
    return content;
  }

  try {
    return jsonDecode(trimmed);
  } catch (_) {
    return content;
  }
}

Object? _normalizeJsonLike(Object? value) {
  if (value == null) return null;
  if (value is String || value is num || value is bool) return value;
  if (value is List) {
    return value.map(_normalizeJsonLike).toList(growable: false);
  }
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), _normalizeJsonLike(v)));
  }
  return value.toString();
}

class _V3EncodeState {
  final bool injectMissingBlockIds;
  final V3FileDataEncoding fileDataEncoding;

  final _BlockIdState text = _BlockIdState(prefix: 'text');
  final _BlockIdState reasoning = _BlockIdState(prefix: 'reasoning');
  final _ToolInputState toolInput = _ToolInputState();

  _V3EncodeState({
    required this.injectMissingBlockIds,
    required this.fileDataEncoding,
  }) {
    text.injectMissingIds = injectMissingBlockIds;
    reasoning.injectMissingIds = injectMissingBlockIds;
  }
}

class _BlockIdState {
  final String prefix;
  int _counter = 1;

  bool injectMissingIds = true;
  String? currentId;

  _BlockIdState({required this.prefix});

  String ensureBlockId(String? id) {
    final trimmed = id?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
    if (!injectMissingIds) {
      throw StateError('Missing $prefix block id (injection disabled).');
    }
    return '${prefix}_${_counter++}';
  }

  String resolveId(String? id) {
    final trimmed = id?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;

    final current = currentId;
    if (current != null && current.isNotEmpty) return current;

    if (!injectMissingIds) {
      throw StateError('Missing $prefix block id (no current block).');
    }

    // Best-effort: create a new id even if boundaries are malformed.
    final generated = '${prefix}_${_counter++}';
    currentId = generated;
    return generated;
  }
}

class _CompletedToolCall {
  final String id;
  final String toolName;
  final String input;

  const _CompletedToolCall({
    required this.id,
    required this.toolName,
    required this.input,
  });
}

class _ToolInputState {
  final Map<String, String> _toolNameById = {};
  final Map<String, StringBuffer> _argsById = {};

  void onStart(ToolCall toolCall) {
    _toolNameById[toolCall.id] = toolCall.function.name;
    _argsById.putIfAbsent(toolCall.id, StringBuffer.new);
  }

  void onDelta(ToolCall toolCall) {
    _toolNameById[toolCall.id] = toolCall.function.name;
    (_argsById[toolCall.id] ??= StringBuffer())
        .write(toolCall.function.arguments);
  }

  _CompletedToolCall? onEnd(String toolCallId) {
    final toolName = _toolNameById[toolCallId] ?? '';
    final input = _argsById[toolCallId]?.toString() ?? '';
    if (toolName.isEmpty) return null;

    return _CompletedToolCall(
      id: toolCallId,
      toolName: toolName,
      input: input,
    );
  }

  String toolNameForToolCallId(String toolCallId) =>
      _toolNameById[toolCallId] ?? 'tool';
}

LLMError _decodeV3Error(Object? error) {
  if (error is Map) {
    final name = error['name'] as String?;
    final message = error['message'];
    if (message is String && message.isNotEmpty) {
      switch (name) {
        case 'HttpError':
          return HttpError(message);
        case 'AuthError':
          return AuthError(message);
        case 'InvalidRequestError':
          return InvalidRequestError(message);
        case 'ProviderError':
          return ProviderError(message);
        case 'ResponseFormatError':
          return ResponseFormatError(message, '');
        case 'GenericError':
          return GenericError(message);
        case 'TimeoutError':
          return TimeoutError(message);
        case 'NotFoundError':
          return NotFoundError(message);
        case 'JsonError':
          return JsonError(message);
        case 'ToolConfigError':
          return ToolConfigError(message);
        case 'ToolExecutionError':
          return ToolExecutionError(message, toolName: 'tool');
        case 'ToolValidationError':
          return ToolValidationError(message, toolName: 'tool');
        case 'StructuredOutputError':
          return StructuredOutputError(message);
        case 'RateLimitError':
          return RateLimitError(message);
        case 'QuotaExceededError':
          return QuotaExceededError(message);
        default:
          // Best-effort fallback.
          return ProviderError(message);
      }
    }
  }
  if (error is String && error.isNotEmpty) return ProviderError(error);
  return const ProviderError('Unknown error');
}

class _V3DecodeState {
  final _DeltaAccumulationState text = _DeltaAccumulationState(kind: 'text');
  final _DeltaAccumulationState reasoning =
      _DeltaAccumulationState(kind: 'reasoning');
  final _ToolInputDecodeState toolInput = _ToolInputDecodeState();

  final Map<String, _RememberedTool> toolById = {};
  final Set<String> emittedToolCallIds = {};
  final Set<String> emittedApprovalIds = {};
  final Set<String> emittedSourceIds = {};
  final Map<String, _ToolResultDecodeState> toolResultStateByToolCallId = {};

  void rememberTool({
    required String id,
    required String toolName,
    Object? input,
  }) {
    final existing = toolById[id];
    toolById[id] = _RememberedTool(
      toolName: toolName,
      input: input ?? existing?.input,
    );
  }
}

class _RememberedTool {
  final String toolName;
  final Object? input;

  const _RememberedTool({
    required this.toolName,
    required this.input,
  });
}

class _ToolResultDecodeState {
  bool seenAny = false;
  bool seenFinal = false;
}

class _DeltaAccumulationState {
  final String kind;

  final Map<String, StringBuffer> _buffers = {};
  String? currentId;

  _DeltaAccumulationState({required this.kind});

  void onStart(String id) {
    currentId = id;
    _buffers.putIfAbsent(id, () => StringBuffer());
  }

  void onDelta(String id, String delta) {
    currentId = id;
    _buffers.putIfAbsent(id, () => StringBuffer()).write(delta);
  }

  String onEnd(String id) {
    currentId = id;
    final buffer = _buffers[id];
    if (buffer == null) {
      throw FormatException('v3 $kind-end references unknown id: $id');
    }
    return buffer.toString();
  }

  ({String? id, String full}) onEndOptionalId(String? id) {
    final resolvedId = (id != null && id.isNotEmpty) ? id : currentId;
    if (resolvedId == null || resolvedId.isEmpty) {
      throw FormatException(
          'v3 $kind-end missing id and no active $kind block.');
    }
    final full = onEnd(resolvedId);
    currentId = null;
    return (id: resolvedId, full: full);
  }
}

class _ToolInputDecodeState {
  final Map<String, StringBuffer> _buffers = {};
  final Set<String> _started = {};
  final Set<String> _ended = {};

  void onStart(String id) {
    if (!_started.add(id)) {
      throw FormatException('v3 tool-input-start duplicated for id: $id');
    }
    _buffers.putIfAbsent(id, () => StringBuffer());
  }

  void onDelta(String id, String delta) {
    if (!_started.contains(id)) {
      throw FormatException(
          'v3 tool-input-delta references unknown tool input id: $id');
    }
    _buffers.putIfAbsent(id, () => StringBuffer()).write(delta);
  }

  void onEnd(String id) {
    if (!_started.contains(id)) {
      throw FormatException(
          'v3 tool-input-end references unknown tool input id: $id');
    }
    if (!_ended.add(id)) {
      throw FormatException('v3 tool-input-end duplicated for id: $id');
    }
    // Intentionally keep buffers for later lookup (e.g. tool-approval-request).
    _buffers.putIfAbsent(id, () => StringBuffer());
  }

  String? fullInputForId(String id) => _buffers[id]?.toString();
}

String _requireString(V3JsonMap obj, String key) {
  final value = obj[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('v3 part missing non-empty "$key".');
}

Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
  if (value is! Map) return null;
  return value.map((k, v) => MapEntry(k.toString(), v));
}

DateTime? _decodeV3Timestamp(Object value) {
  if (value is String) return DateTime.tryParse(value);

  if (value is num) {
    if (!value.isFinite) {
      throw const FormatException(
          'v3 response-metadata.timestamp is not finite.');
    }
    final asInt = value is int ? value : value.round();
    // Heuristic:
    // - >= 1e11 => milliseconds (e.g. 1700000000000)
    // - otherwise => seconds (e.g. 1700000000)
    final ms = asInt.abs() >= 100000000000 ? asInt : asInt * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  throw const FormatException(
    'v3 response-metadata.timestamp must be a string or number.',
  );
}

Object _decodeV3FileData(Object? value) {
  if (value is String) return value;
  if (value is List) {
    final bytes = <int>[];
    for (final item in value) {
      final n = item is int ? item : (item is num ? item.toInt() : null);
      if (n == null || n < 0 || n > 255) {
        throw const FormatException(
          'v3 file.data byte array must contain integers in range 0..255.',
        );
      }
      bytes.add(n);
    }
    return Uint8List.fromList(bytes);
  }
  throw const FormatException(
    'v3 file part missing string or byte-array "data".',
  );
}

List<Map<String, dynamic>>? _asListOfStringKeyedMaps(dynamic value) {
  if (value is! List) return null;
  final out = <Map<String, dynamic>>[];
  for (final item in value) {
    final map = _asStringKeyedMap(item);
    if (map == null) return null;
    out.add(map);
  }
  return out;
}
