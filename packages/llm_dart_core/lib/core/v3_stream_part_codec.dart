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
}) {
  final state = _V3EncodeState(injectMissingBlockIds: injectMissingBlockIds);
  final out = <V3JsonMap>[];

  for (final part in parts) {
    out.addAll(_encodeV3Part(part, state));
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
      return [
        {
          'type': 'tool-result',
          'toolCallId': result.toolCallId,
          'toolName': state.toolInput.toolNameForToolCallId(result.toolCallId),
          'result': _decodeJsonIfPossible(result.content),
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
      final encodedData =
          data is Uint8List ? base64Encode(data) : data as String;
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

    // Provider metadata snapshots:
    case LLMProviderMetadataPart(:final providerMetadata):
      return [
        {
          'type': 'raw',
          'rawValue': {
            'kind': 'provider-metadata',
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
            'kind': 'provider-tool-delta',
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
  if (value is List)
    return value.map(_normalizeJsonLike).toList(growable: false);
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), _normalizeJsonLike(v)));
  }
  return value.toString();
}

class _V3EncodeState {
  final bool injectMissingBlockIds;

  final _BlockIdState text = _BlockIdState(prefix: 'text');
  final _BlockIdState reasoning = _BlockIdState(prefix: 'reasoning');
  final _ToolInputState toolInput = _ToolInputState();

  _V3EncodeState({required this.injectMissingBlockIds}) {
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
