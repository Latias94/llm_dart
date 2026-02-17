import 'dart:async';

import 'ai_errors.dart';
import 'ui_messages.dart';

class _ToolCallMeta {
  final String toolName;
  final bool isDynamic;
  final bool? providerExecuted;
  final String? title;
  final Map<String, dynamic>? providerMetadata;

  const _ToolCallMeta({
    required this.toolName,
    required this.isDynamic,
    this.providerExecuted,
    this.title,
    this.providerMetadata,
  });
}

class StreamingUIMessageState {
  UIMessage message;

  final Map<String, Map<String, Object?>> _activeTextParts = {};
  final Map<String, Map<String, Object?>> _activeReasoningParts = {};

  final Map<String, StringBuffer> _partialToolInputText = {};
  final Map<String, _ToolCallMeta> _partialToolMeta = {};
  final Map<String, Map<String, Object?>> _toolPartsByCallId = {};

  String? finishReason;
  bool isAborted = false;

  StreamingUIMessageState(this.message);
}

StreamingUIMessageState createStreamingUIMessageState({
  UIMessage? lastMessage,
  String? messageId,
}) {
  final base = lastMessage;
  if (base != null && base.role == 'assistant') {
    return StreamingUIMessageState(
      UIMessage(
        id: base.id,
        role: base.role,
        metadata: deepCloneJsonLike(base.metadata),
        parts: base.parts
            .map((p) =>
                (deepCloneJsonLike(p) as Map?)?.cast<String, Object?>() ??
                const <String, Object?>{})
            .toList(growable: true),
      ),
    );
  }

  final id = (messageId != null && messageId.trim().isNotEmpty)
      ? messageId.trim()
      : fallbackUiMessageId();

  return StreamingUIMessageState(
    UIMessage(
      id: id,
      role: 'assistant',
      parts: <Map<String, Object?>>[],
    ),
  );
}

Map<String, dynamic>? _asProviderMetadata(Object? raw) {
  if (raw == null) return null;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return null;
}

Map<String, Object?> _ensureToolPart(
  StreamingUIMessageState state, {
  required String toolCallId,
  required String toolName,
  required bool isDynamic,
  bool? providerExecuted,
  String? title,
  Map<String, dynamic>? providerMetadata,
}) {
  final existing = state._toolPartsByCallId[toolCallId];
  if (existing != null) {
    if (providerExecuted != null && existing['providerExecuted'] == null) {
      existing['providerExecuted'] = providerExecuted;
    }
    if (title != null) {
      existing['title'] = title;
    }
    if (providerMetadata != null) {
      existing['callProviderMetadata'] = providerMetadata;
    }
    if (isDynamic) {
      existing['toolName'] = toolName;
    }
    return existing;
  }

  final part = <String, Object?>{
    'type': isDynamic ? 'dynamic-tool' : 'tool-$toolName',
    'toolCallId': toolCallId,
    if (isDynamic) 'toolName': toolName,
    if (title != null && title.trim().isNotEmpty) 'title': title,
    if (providerExecuted != null) 'providerExecuted': providerExecuted,
    if (providerMetadata != null && providerMetadata.isNotEmpty)
      'callProviderMetadata': providerMetadata,
    'state': 'input-streaming',
    'input': null,
  };

  state.message.parts.add(part);
  state._toolPartsByCallId[toolCallId] = part;
  return part;
}

Map<String, Object?> _ensureTextPart(StreamingUIMessageState state, String id,
    {Map<String, dynamic>? providerMetadata}) {
  final existing = state._activeTextParts[id];
  if (existing != null) return existing;

  final part = <String, Object?>{
    'type': 'text',
    'text': '',
    'state': 'streaming',
    if (providerMetadata != null && providerMetadata.isNotEmpty)
      'providerMetadata': providerMetadata,
  };
  state.message.parts.add(part);
  state._activeTextParts[id] = part;
  return part;
}

Map<String, Object?> _ensureReasoningPart(
    StreamingUIMessageState state, String id,
    {Map<String, dynamic>? providerMetadata}) {
  final existing = state._activeReasoningParts[id];
  if (existing != null) return existing;

  final part = <String, Object?>{
    'type': 'reasoning',
    'text': '',
    'state': 'streaming',
    if (providerMetadata != null && providerMetadata.isNotEmpty)
      'providerMetadata': providerMetadata,
  };
  state.message.parts.add(part);
  state._activeReasoningParts[id] = part;
  return part;
}

void applyUiMessageChunk(
  StreamingUIMessageState state,
  Map<String, Object?> chunk,
) {
  final type = chunk['type'];
  if (type is! String || type.isEmpty) {
    throw UiMessageStreamError(
      cause: chunk,
      message: 'UI message chunk missing non-empty "type".',
    );
  }

  switch (type) {
    case 'start':
      final messageId = chunk['messageId'];
      if (messageId is String && messageId.trim().isNotEmpty) {
        state.message = state.message.copyWith(id: messageId.trim());
      }
      final meta = chunk['messageMetadata'];
      if (meta != null) {
        state.message = state.message.copyWith(
          metadata: mergeJsonLike(state.message.metadata, meta),
        );
      }
      return;

    case 'message-metadata':
      final meta = chunk['messageMetadata'];
      if (meta != null) {
        state.message = state.message.copyWith(
          metadata: mergeJsonLike(state.message.metadata, meta),
        );
      }
      return;

    case 'text-start':
      final id = (chunk['id'] as String?)?.trim();
      if (id == null || id.isEmpty) return;
      _ensureTextPart(state, id,
          providerMetadata: _asProviderMetadata(chunk['providerMetadata']));
      return;

    case 'text-delta':
      final id = (chunk['id'] as String?)?.trim();
      final delta = chunk['delta'] as String?;
      if (id == null || id.isEmpty || delta == null || delta.isEmpty) return;
      final part = state._activeTextParts[id];
      if (part == null) {
        throw UiMessageStreamError(
          cause: chunk,
          chunkType: 'text-delta',
          chunkId: id,
          message:
              'Received text-delta for missing text part id "$id". Send a "text-start" chunk before any "text-delta" chunks.',
        );
      }
      part['text'] = ((part['text'] as String?) ?? '') + delta;
      return;

    case 'text-end':
      final id = (chunk['id'] as String?)?.trim();
      if (id == null || id.isEmpty) return;
      final part = state._activeTextParts[id];
      if (part == null) {
        throw UiMessageStreamError(
          cause: chunk,
          chunkType: 'text-end',
          chunkId: id,
          message:
              'Received text-end for missing text part id "$id". Send a "text-start" chunk before "text-end".',
        );
      }
      part['state'] = 'done';
      state._activeTextParts.remove(id);
      return;

    case 'reasoning-start':
      final id = (chunk['id'] as String?)?.trim();
      if (id == null || id.isEmpty) return;
      _ensureReasoningPart(state, id,
          providerMetadata: _asProviderMetadata(chunk['providerMetadata']));
      return;

    case 'reasoning-delta':
      final id = (chunk['id'] as String?)?.trim();
      final delta = chunk['delta'] as String?;
      if (id == null || id.isEmpty || delta == null || delta.isEmpty) return;
      final part = state._activeReasoningParts[id];
      if (part == null) {
        throw UiMessageStreamError(
          cause: chunk,
          chunkType: 'reasoning-delta',
          chunkId: id,
          message:
              'Received reasoning-delta for missing reasoning part id "$id". Send a "reasoning-start" chunk before any "reasoning-delta" chunks.',
        );
      }
      part['text'] = ((part['text'] as String?) ?? '') + delta;
      return;

    case 'reasoning-end':
      final id = (chunk['id'] as String?)?.trim();
      if (id == null || id.isEmpty) return;
      final part = state._activeReasoningParts[id];
      if (part == null) {
        throw UiMessageStreamError(
          cause: chunk,
          chunkType: 'reasoning-end',
          chunkId: id,
          message:
              'Received reasoning-end for missing reasoning part id "$id". Send a "reasoning-start" chunk before "reasoning-end".',
        );
      }
      part['state'] = 'done';
      state._activeReasoningParts.remove(id);
      return;

    case 'error':
      // Error chunks are not part of the UI message itself, but they should
      // surface as errors to the consumer (AI SDK parity). Callers can decide
      // whether to terminate or keep consuming via `terminateOnError`.
      final errorText = chunk['errorText'] as String?;
      if (errorText != null && errorText.trim().isNotEmpty) {
        throw UiMessageStreamError(
          cause: chunk,
          chunkType: 'error',
          chunkId: (chunk['id'] as String?)?.trim(),
          message: errorText.trim(),
        );
      }
      throw UiMessageStreamError(
        cause: chunk,
        chunkType: 'error',
        chunkId: (chunk['id'] as String?)?.trim(),
        message: 'UI message stream error chunk received.',
      );

    case 'start-step':
      state.message.parts.add(const <String, Object?>{'type': 'step-start'});
      return;

    case 'finish-step':
      return;

    case 'source-url':
      final sourceId = (chunk['sourceId'] as String?)?.trim();
      final url = (chunk['url'] as String?)?.trim();
      if (sourceId == null || sourceId.isEmpty || url == null || url.isEmpty) {
        return;
      }
      state.message.parts.add(<String, Object?>{
        'type': 'source',
        'sourceType': 'url',
        'id': sourceId,
        'url': url,
        if (chunk['title'] is String && (chunk['title'] as String).isNotEmpty)
          'title': chunk['title'] as String,
        if (chunk['providerMetadata'] != null)
          'providerMetadata': _asProviderMetadata(chunk['providerMetadata']),
      });
      return;

    case 'source-document':
      final sourceId = (chunk['sourceId'] as String?)?.trim();
      final mediaType = (chunk['mediaType'] as String?)?.trim();
      final title = (chunk['title'] as String?)?.trim();
      if (sourceId == null ||
          sourceId.isEmpty ||
          mediaType == null ||
          mediaType.isEmpty ||
          title == null ||
          title.isEmpty) {
        return;
      }
      state.message.parts.add(<String, Object?>{
        'type': 'source',
        'sourceType': 'document',
        'id': sourceId,
        'mediaType': mediaType,
        'title': title,
        if (chunk['filename'] is String &&
            (chunk['filename'] as String).isNotEmpty)
          'filename': chunk['filename'] as String,
        if (chunk['providerMetadata'] != null)
          'providerMetadata': _asProviderMetadata(chunk['providerMetadata']),
      });
      return;

    case 'file':
      final url = (chunk['url'] as String?)?.trim();
      final mediaType = (chunk['mediaType'] as String?)?.trim();
      if (url == null ||
          url.isEmpty ||
          mediaType == null ||
          mediaType.isEmpty) {
        return;
      }
      state.message.parts.add(<String, Object?>{
        'type': 'file',
        'url': url,
        'mediaType': mediaType,
        if (chunk['providerMetadata'] != null)
          'providerMetadata': _asProviderMetadata(chunk['providerMetadata']),
      });
      return;

    case 'tool-input-start':
      final toolCallId = (chunk['toolCallId'] as String?)?.trim();
      final toolName = (chunk['toolName'] as String?)?.trim();
      if (toolCallId == null ||
          toolCallId.isEmpty ||
          toolName == null ||
          toolName.isEmpty) {
        return;
      }

      final dynamicTool = chunk['dynamic'] == true;
      final providerExecuted = chunk['providerExecuted'] == true ? true : null;
      final title = (chunk['title'] as String?)?.trim();
      final pm = _asProviderMetadata(chunk['providerMetadata']);

      state._partialToolInputText[toolCallId] = StringBuffer();
      state._partialToolMeta[toolCallId] = _ToolCallMeta(
        toolName: toolName,
        isDynamic: dynamicTool,
        providerExecuted: providerExecuted,
        title: (title != null && title.isNotEmpty) ? title : null,
        providerMetadata: pm,
      );

      final part = _ensureToolPart(
        state,
        toolCallId: toolCallId,
        toolName: toolName,
        isDynamic: dynamicTool,
        providerExecuted: providerExecuted,
        title: title,
        providerMetadata: pm,
      );
      part['state'] = 'input-streaming';
      part['input'] = null;
      return;

    case 'tool-input-delta':
      final toolCallId = (chunk['toolCallId'] as String?)?.trim();
      final delta = chunk['inputTextDelta'] as String?;
      if (toolCallId == null ||
          toolCallId.isEmpty ||
          delta == null ||
          delta.isEmpty) {
        return;
      }

      if (!state._partialToolInputText.containsKey(toolCallId) &&
          !state._partialToolMeta.containsKey(toolCallId)) {
        throw UiMessageStreamError(
          cause: chunk,
          chunkType: 'tool-input-delta',
          chunkId: toolCallId,
          message:
              'Received tool-input-delta for missing tool call id "$toolCallId". Send a "tool-input-start" chunk before any "tool-input-delta" chunks.',
        );
      }

      final buffer = state._partialToolInputText.putIfAbsent(
        toolCallId,
        StringBuffer.new,
      );
      buffer.write(delta);

      final meta = state._partialToolMeta[toolCallId];
      final toolName = meta?.toolName ?? (chunk['toolName'] as String?) ?? '';
      final dynamicTool = meta?.isDynamic ?? (chunk['dynamic'] == true);

      final part = _ensureToolPart(
        state,
        toolCallId: toolCallId,
        toolName: toolName.isEmpty ? 'tool' : toolName,
        isDynamic: dynamicTool,
        providerExecuted: meta?.providerExecuted,
        title: meta?.title,
        providerMetadata: meta?.providerMetadata,
      );
      part['state'] = 'input-streaming';
      part['input'] = buffer.toString();
      return;

    case 'tool-input-available':
      final toolCallId = (chunk['toolCallId'] as String?)?.trim();
      final toolName = (chunk['toolName'] as String?)?.trim();
      if (toolCallId == null ||
          toolCallId.isEmpty ||
          toolName == null ||
          toolName.isEmpty) {
        return;
      }
      final dynamicTool = chunk['dynamic'] == true;
      final providerExecuted = chunk['providerExecuted'] == true ? true : null;
      final title = (chunk['title'] as String?)?.trim();
      final pm = _asProviderMetadata(chunk['providerMetadata']);

      final part = _ensureToolPart(
        state,
        toolCallId: toolCallId,
        toolName: toolName,
        isDynamic: dynamicTool,
        providerExecuted: providerExecuted,
        title: title,
        providerMetadata: pm,
      );
      part['state'] = 'input-available';
      part['input'] = chunk['input'];
      return;

    case 'tool-input-error':
      final toolCallId = (chunk['toolCallId'] as String?)?.trim();
      final toolName = (chunk['toolName'] as String?)?.trim();
      final errorText = chunk['errorText'] as String?;
      if (toolCallId == null ||
          toolCallId.isEmpty ||
          toolName == null ||
          toolName.isEmpty ||
          errorText == null ||
          errorText.isEmpty) {
        return;
      }
      final dynamicTool = chunk['dynamic'] == true;
      final providerExecuted = chunk['providerExecuted'] == true ? true : null;
      final pm = _asProviderMetadata(chunk['providerMetadata']);

      final part = _ensureToolPart(
        state,
        toolCallId: toolCallId,
        toolName: toolName,
        isDynamic: dynamicTool,
        providerExecuted: providerExecuted,
        providerMetadata: pm,
      );
      part['state'] = 'output-error';
      if (dynamicTool) {
        part['input'] = chunk['input'];
      } else {
        part['input'] = null;
        part['rawInput'] = chunk['input'];
      }
      part['errorText'] = errorText;
      return;

    case 'tool-approval-request':
      final toolCallId = (chunk['toolCallId'] as String?)?.trim();
      final approvalId = (chunk['approvalId'] as String?)?.trim();
      if (toolCallId == null ||
          toolCallId.isEmpty ||
          approvalId == null ||
          approvalId.isEmpty) {
        return;
      }
      final part = state._toolPartsByCallId[toolCallId];
      if (part == null) {
        throw UiMessageStreamError(
          cause: chunk,
          chunkType: 'tool-approval-request',
          chunkId: toolCallId,
          message:
              'Received tool-approval-request for missing tool call id "$toolCallId". Ensure tool input chunks are sent before requesting approval.',
        );
      }
      part['state'] = 'approval-requested';
      part['approval'] = <String, Object?>{'id': approvalId};
      return;

    case 'tool-output-denied':
      final toolCallId = (chunk['toolCallId'] as String?)?.trim();
      if (toolCallId == null || toolCallId.isEmpty) return;
      final part = state._toolPartsByCallId[toolCallId];
      if (part == null) {
        throw UiMessageStreamError(
          cause: chunk,
          chunkType: 'tool-output-denied',
          chunkId: toolCallId,
          message:
              'Received tool-output-denied for missing tool call id "$toolCallId".',
        );
      }
      part['state'] = 'output-denied';
      return;

    case 'tool-output-available':
      final toolCallId = (chunk['toolCallId'] as String?)?.trim();
      if (toolCallId == null || toolCallId.isEmpty) return;
      final part = state._toolPartsByCallId[toolCallId];
      if (part == null) {
        throw UiMessageStreamError(
          cause: chunk,
          chunkType: 'tool-output-available',
          chunkId: toolCallId,
          message:
              'Received tool-output-available for missing tool call id "$toolCallId".',
        );
      }
      part['state'] = 'output-available';
      part['output'] = chunk['output'];
      if (chunk['preliminary'] == true) part['preliminary'] = true;
      if (chunk['providerExecuted'] == true) part['providerExecuted'] = true;
      return;

    case 'tool-output-error':
      final toolCallId = (chunk['toolCallId'] as String?)?.trim();
      final errorText = chunk['errorText'] as String?;
      if (toolCallId == null ||
          toolCallId.isEmpty ||
          errorText == null ||
          errorText.isEmpty) {
        return;
      }
      final part = state._toolPartsByCallId[toolCallId];
      if (part == null) {
        throw UiMessageStreamError(
          cause: chunk,
          chunkType: 'tool-output-error',
          chunkId: toolCallId,
          message:
              'Received tool-output-error for missing tool call id "$toolCallId".',
        );
      }
      part['state'] = 'output-error';
      part['errorText'] = errorText;
      if (chunk['providerExecuted'] == true) part['providerExecuted'] = true;
      return;

    case 'finish':
      final reason = chunk['finishReason'];
      if (reason is String && reason.isNotEmpty) {
        state.finishReason = reason;
      }
      final meta = chunk['messageMetadata'];
      if (meta != null) {
        state.message = state.message.copyWith(
          metadata: mergeJsonLike(state.message.metadata, meta),
        );
      }
      return;

    case 'abort':
      state.isAborted = true;
      return;

    default:
      // Data parts use `type: data-*`.
      if (type.startsWith('data-')) {
        final data = chunk['data'];
        state.message.parts.add(<String, Object?>{
          'type': type,
          if (chunk['id'] is String && (chunk['id'] as String).isNotEmpty)
            'id': chunk['id'] as String,
          'data': data,
          if (chunk['transient'] == true) 'transient': true,
        });
        return;
      }

      // Unknown chunk types are ignored for forward compatibility.
      return;
  }
}

/// Reads an AI SDK-style UI message chunk stream into a stream of `UIMessage`
/// snapshots.
///
/// Each emitted element is a different state of the same message as it is being
/// completed.
Stream<UIMessage> readUiMessageStream({
  required Stream<Map<String, Object?>> chunks,
  UIMessage? message,
  bool terminateOnError = false,
  void Function(Object error)? onError,
}) {
  final state = createStreamingUIMessageState(
    lastMessage: message,
    messageId: message?.id,
  );

  late final StreamSubscription<Map<String, Object?>> sub;
  final controller = StreamController<UIMessage>(sync: true);

  void handle(Object error) {
    onError?.call(error);
    if (terminateOnError && !controller.isClosed) {
      controller.addError(error);
      sub.cancel();
      controller.close();
    }
  }

  sub = chunks.listen(
    (chunk) {
      try {
        applyUiMessageChunk(state, chunk);

        // Do not emit snapshots for purely control chunks unless they could
        // affect callbacks/state.
        final type = chunk['type'];
        if (type == 'finish-step') return;
        if (type == 'error') return;

        controller.add(deepCloneUiMessage(state.message));
      } catch (e) {
        handle(e);
      }
    },
    onError: (e) => handle(e),
    onDone: () async {
      await controller.close();
    },
    cancelOnError: false,
  );

  controller.onCancel = () => sub.cancel();
  return controller.stream;
}
