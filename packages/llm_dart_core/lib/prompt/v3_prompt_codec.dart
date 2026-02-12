import 'dart:convert';
import 'dart:typed_data';

import '../core/provider_options.dart';
import '../models/chat_models.dart';
import 'prompt.dart';

typedef V3PromptJson = List<Map<String, dynamic>>;

/// How to encode binary prompt data (images/files) in JSON.
enum V3PromptDataEncoding {
  /// Encode bytes as a base64 string.
  base64,

  /// Encode bytes as a JSON array of integers (0..255).
  bytes,
}

/// Encodes a [Prompt] into AI SDK v3 `LanguageModelV3Prompt`-style JSON.
///
/// This codec is intended for interoperability tests and debugging. It is
/// best-effort and may throw [FormatException] if the prompt cannot be mapped
/// to the v3 shape (e.g. unsupported parts in a given role).
V3PromptJson encodeV3Prompt(
  Prompt prompt, {
  V3PromptDataEncoding dataEncoding = V3PromptDataEncoding.base64,
}) {
  final out = <Map<String, dynamic>>[];

  for (final message in prompt.messages) {
    out.addAll(_encodeV3PromptMessages(message, dataEncoding: dataEncoding));
  }

  return List<Map<String, dynamic>>.unmodifiable(out);
}

/// Decodes AI SDK v3 `LanguageModelV3Prompt`-style JSON into a [Prompt].
Prompt decodeV3Prompt(V3PromptJson messages) {
  final out = <PromptMessage>[];

  for (final m in messages) {
    out.add(_decodeV3PromptMessage(m));
  }

  return Prompt(messages: List<PromptMessage>.unmodifiable(out));
}

Map<String, dynamic> _encodeV3PromptMessage(
  PromptMessage message, {
  required V3PromptDataEncoding dataEncoding,
}) {
  final role = switch (message.role) {
    PromptRole.system => 'system',
    PromptRole.user => 'user',
    PromptRole.assistant => 'assistant',
    PromptRole.tool => 'tool',
  };

  final providerOptions = message.providerOptions;

  if (message.role == PromptRole.system) {
    final buffer = StringBuffer();
    for (final part in message.parts) {
      if (part is! TextPart) {
        throw const FormatException(
          'v3 prompt: system messages can only contain text parts.',
        );
      }
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write(part.text);
    }

    return {
      'role': role,
      'content': buffer.toString(),
      if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
    };
  }

  if (message.role == PromptRole.tool) {
    final content = <Map<String, dynamic>>[];
    for (final part in message.parts) {
      if (part is! ToolResultPart && part is! ToolApprovalResponsePart) {
        throw const FormatException(
          "v3 prompt: role 'tool' can only contain tool-result/tool-approval-response parts.",
        );
      }
      content.add(_encodeV3ToolContentPart(part));
    }

    return {
      'role': role,
      'content': content,
      if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
    };
  }

  final content = <Map<String, dynamic>>[];
  for (final part in message.parts) {
    content.addAll(
      _encodeV3PromptPartsForMessage(
        role: message.role,
        part: part,
        dataEncoding: dataEncoding,
      ),
    );
  }

  return {
    'role': role,
    'content': content,
    if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
  };
}

List<Map<String, dynamic>> _encodeV3PromptMessages(
  PromptMessage message, {
  required V3PromptDataEncoding dataEncoding,
}) {
  if (message.role == PromptRole.system || message.role == PromptRole.tool) {
    return [
      _encodeV3PromptMessage(message, dataEncoding: dataEncoding),
    ];
  }

  final baseRole = switch (message.role) {
    PromptRole.user => 'user',
    PromptRole.assistant => 'assistant',
    PromptRole.system => 'system',
    PromptRole.tool => 'tool',
  };

  final providerOptions = message.providerOptions;
  final out = <Map<String, dynamic>>[];

  final current = <Map<String, dynamic>>[];
  final toolCurrent = <Map<String, dynamic>>[];
  void flushCurrent() {
    if (current.isEmpty) return;
    out.add({
      'role': baseRole,
      'content': List<Map<String, dynamic>>.unmodifiable(current),
      if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
    });
    current.clear();
  }

  void flushTool() {
    if (toolCurrent.isEmpty) return;
    out.add({
      'role': 'tool',
      'content': List<Map<String, dynamic>>.unmodifiable(toolCurrent),
      if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
    });
    toolCurrent.clear();
  }

  for (final part in message.parts) {
    if (part is ToolResultPart || part is ToolApprovalResponsePart) {
      flushCurrent();
      toolCurrent.add(_encodeV3ToolContentPart(part));
      continue;
    }

    flushTool();
    current.addAll(
      _encodeV3PromptPartsForMessage(
        role: message.role,
        part: part,
        dataEncoding: dataEncoding,
      ),
    );
  }

  flushTool();
  flushCurrent();
  return List<Map<String, dynamic>>.unmodifiable(out);
}

Map<String, dynamic> _encodeV3ToolContentPart(PromptPart part) {
  switch (part) {
    case ToolResultPart(
        :final toolCallId,
        :final toolName,
        :final output,
        providerOptions: final po,
      ):
      return {
        'type': 'tool-result',
        'toolCallId': toolCallId,
        'toolName': toolName,
        'output': output.toJson(),
        if (po.isNotEmpty) 'providerOptions': po,
      };

    case ToolApprovalResponsePart(
        :final approvalId,
        :final approved,
        :final reason,
        providerOptions: final po,
      ):
      return {
        'type': 'tool-approval-response',
        'approvalId': approvalId,
        'approved': approved,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (po.isNotEmpty) 'providerOptions': po,
      };

    default:
      throw StateError(
        'v3 prompt: unsupported tool role part: ${part.runtimeType}',
      );
  }
}

List<Map<String, dynamic>> _encodeV3PromptPartsForMessage({
  required PromptRole role,
  required PromptPart part,
  required V3PromptDataEncoding dataEncoding,
}) {
  final out = <Map<String, dynamic>>[];

  switch (part) {
    case TextPart(:final text, providerOptions: final providerOptions):
      out.add({
        'type': 'text',
        'text': text,
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      });
      return out;

    case ImagePart(
        :final mime,
        :final data,
        :final text,
        providerOptions: final providerOptions,
      ):
      if (role == PromptRole.system || role == PromptRole.tool) {
        throw const FormatException('v3 prompt: system cannot contain files.');
      }
      if (text != null && text.isNotEmpty) {
        out.add({
          'type': 'text',
          'text': text,
          if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
        });
      }
      out.add({
        'type': 'file',
        'mediaType': mime.mimeType,
        'data': _encodeV3DataContent(
          Uint8List.fromList(data),
          dataEncoding: dataEncoding,
        ),
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      });
      return out;

    case ImageUrlPart(
        :final url,
        :final text,
        providerOptions: final providerOptions,
      ):
      if (role == PromptRole.system || role == PromptRole.tool) {
        throw const FormatException('v3 prompt: system cannot contain files.');
      }
      if (text != null && text.isNotEmpty) {
        out.add({
          'type': 'text',
          'text': text,
          if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
        });
      }
      out.add({
        'type': 'file',
        'mediaType': 'image/*',
        'data': url,
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      });
      return out;

    case FilePart(
        :final mime,
        :final data,
        :final text,
        providerOptions: final providerOptions,
      ):
      if (role == PromptRole.system || role == PromptRole.tool) {
        throw const FormatException('v3 prompt: system cannot contain files.');
      }
      if (text != null && text.isNotEmpty) {
        out.add({
          'type': 'text',
          'text': text,
          if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
        });
      }
      out.add({
        'type': 'file',
        'mediaType': mime.mimeType,
        'data': _encodeV3DataContent(
          Uint8List.fromList(data),
          dataEncoding: dataEncoding,
        ),
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      });
      return out;

    case FileUrlPart(
        :final mime,
        :final url,
        :final text,
        providerOptions: final providerOptions,
      ):
      if (role == PromptRole.system || role == PromptRole.tool) {
        throw const FormatException('v3 prompt: system cannot contain files.');
      }
      if (text != null && text.isNotEmpty) {
        out.add({
          'type': 'text',
          'text': text,
          if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
        });
      }
      out.add({
        'type': 'file',
        'mediaType': mime.mimeType,
        'data': url,
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      });
      return out;

    case FileIdPart():
      throw const FormatException(
        'v3 prompt: file-id parts are not representable as LanguageModelV3FilePart.data.',
      );

    case ToolCallPart(
        :final toolCallId,
        :final toolName,
        :final input,
        :final providerExecuted,
        :final overrideRole,
        providerOptions: final providerOptions,
      ):
      final effectiveRole = overrideRole ?? role;
      if (effectiveRole != PromptRole.assistant) {
        throw const FormatException(
          'v3 prompt: tool-call parts are only supported in assistant messages.',
        );
      }
      out.add({
        'type': 'tool-call',
        'toolCallId': toolCallId,
        'toolName': toolName,
        'input': _normalizeJsonLike(input),
        if (providerExecuted != null) 'providerExecuted': providerExecuted,
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      });
      return out;

    case ToolResultPart():
      // Tool results are encoded as separate `role: 'tool'` messages by
      // [_encodeV3PromptMessages] to match the AI SDK v3 prompt shape.
      throw const FormatException(
        'v3 prompt: tool parts must be encoded via tool role messages.',
      );

    case ToolApprovalResponsePart():
      // Tool approvals are encoded as `role: 'tool'` messages by
      // [_encodeV3PromptMessages] to match the AI SDK v3 prompt shape.
      throw const FormatException(
        'v3 prompt: tool parts must be encoded via tool role messages.',
      );
  }
}

PromptMessage _decodeV3PromptMessage(Map<String, dynamic> obj) {
  final roleRaw = obj['role'];
  if (roleRaw is! String || roleRaw.isEmpty) {
    throw const FormatException('v3 prompt message missing non-empty "role".');
  }
  final providerOptions =
      _asProviderOptions(obj['providerOptions']) ?? const {};

  if (roleRaw == 'system') {
    final content = obj['content'];
    if (content is! String) {
      throw const FormatException(
          'v3 prompt: system message content must be a string.');
    }
    return PromptMessage(
      role: PromptRole.system,
      parts: [TextPart(content)],
      providerOptions: providerOptions,
    );
  }

  final content = obj['content'];
  if (content is! List) {
    throw const FormatException('v3 prompt message missing list "content".');
  }

  final role = switch (roleRaw) {
    'user' => PromptRole.user,
    'assistant' => PromptRole.assistant,
    'tool' => PromptRole.tool,
    _ => throw FormatException('v3 prompt: unsupported role: $roleRaw'),
  };

  final parts = <PromptPart>[];
  for (final item in content) {
    if (item is! Map) {
      throw const FormatException('v3 prompt: content items must be objects.');
    }
    parts.add(
      _decodeV3PromptPart(
        role: role,
        roleRaw: roleRaw,
        obj: item.cast<String, dynamic>(),
      ),
    );
  }

  return PromptMessage(
    role: role,
    parts: List<PromptPart>.unmodifiable(parts),
    providerOptions: providerOptions,
  );
}

PromptPart _decodeV3PromptPart({
  required PromptRole role,
  required String roleRaw,
  required Map<String, dynamic> obj,
}) {
  final type = obj['type'];
  if (type is! String || type.isEmpty) {
    throw const FormatException('v3 prompt part missing non-empty "type".');
  }

  final providerOptions =
      _asProviderOptions(obj['providerOptions']) ?? const {};

  switch (type) {
    case 'text':
      final text = obj['text'];
      if (text is! String) {
        throw const FormatException(
            'v3 prompt text part missing string "text".');
      }
      return TextPart(text, providerOptions: providerOptions);

    case 'file':
      if (roleRaw == 'tool') {
        throw const FormatException(
          'v3 prompt: tool messages cannot contain file parts.',
        );
      }
      final mediaType = obj['mediaType'];
      if (mediaType is! String || mediaType.isEmpty) {
        throw const FormatException(
            'v3 prompt file part missing non-empty "mediaType".');
      }
      final data = obj['data'];
      final decoded = _decodeV3DataContent(data);

      if (decoded is _V3UrlData) {
        return FileUrlPart(
          mime: FileMime(mediaType),
          url: decoded.url,
          providerOptions: providerOptions,
        );
      }

      final bytes = decoded as Uint8List;
      if (mediaType.startsWith('image/')) {
        final imageMime = _imageMimeFromMediaType(mediaType);
        if (imageMime != null) {
          return ImagePart(
            mime: imageMime,
            data: bytes,
            providerOptions: providerOptions,
          );
        }
      }

      return FilePart(
        mime: FileMime(mediaType),
        data: bytes,
        providerOptions: providerOptions,
      );

    case 'tool-call':
      if (role != PromptRole.assistant) {
        throw const FormatException(
          'v3 prompt: tool-call parts are only supported in assistant messages.',
        );
      }
      final toolCallId = obj['toolCallId'];
      final toolName = obj['toolName'];
      final providerExecuted = obj['providerExecuted'];
      if (toolCallId is! String || toolCallId.isEmpty) {
        throw const FormatException(
            'v3 prompt tool-call missing "toolCallId".');
      }
      if (toolName is! String || toolName.isEmpty) {
        throw const FormatException('v3 prompt tool-call missing "toolName".');
      }
      if (providerExecuted != null && providerExecuted is! bool) {
        throw const FormatException(
          'v3 prompt tool-call requires boolean "providerExecuted" when present.',
        );
      }
      final input = obj['input'];
      return ToolCallPart(
        toolCallId: toolCallId,
        toolName: toolName,
        input: _normalizeJsonLike(input),
        providerExecuted: providerExecuted as bool?,
        providerOptions: providerOptions,
      );

    case 'tool-result':
      final toolCallId = obj['toolCallId'];
      final toolName = obj['toolName'];
      final output = obj['output'];
      if (toolCallId is! String || toolCallId.isEmpty) {
        throw const FormatException(
            'v3 prompt tool-result missing "toolCallId".');
      }
      if (toolName is! String || toolName.isEmpty) {
        throw const FormatException(
            'v3 prompt tool-result missing "toolName".');
      }
      if (roleRaw != 'tool') {
        throw FormatException(
          "v3 prompt: tool-result parts are not supported in role '$roleRaw'.",
        );
      }
      final normalizedOutput = _normalizeAndValidateToolResultOutput(output);
      if (normalizedOutput == null) {
        throw const FormatException('v3 prompt tool-result missing "output".');
      }
      return ToolResultPart(
        toolCallId,
        toolName,
        ToolResultOutput.fromJson(normalizedOutput),
        overrideRole: PromptRole.tool,
        providerOptions: providerOptions,
      );

    case 'tool-approval-response':
      if (roleRaw != 'tool') {
        throw FormatException(
          "v3 prompt: tool-approval-response is only supported in role 'tool', got '$roleRaw'.",
        );
      }
      final approvalId = obj['approvalId'];
      final approved = obj['approved'];
      final reason = obj['reason'];
      if (approvalId is! String || approvalId.isEmpty) {
        throw const FormatException(
            'v3 prompt tool-approval-response missing non-empty "approvalId".');
      }
      if (approved is! bool) {
        throw const FormatException(
            'v3 prompt tool-approval-response missing boolean "approved".');
      }
      if (reason != null && reason is! String) {
        throw const FormatException(
          'v3 prompt tool-approval-response requires string "reason" when present.',
        );
      }
      return ToolApprovalResponsePart(
        approvalId: approvalId,
        approved: approved,
        reason: (reason is String && reason.isNotEmpty) ? reason : null,
        providerOptions: providerOptions,
      );

    default:
      throw FormatException('v3 prompt: unsupported part type: $type');
  }
}

Object _encodeV3DataContent(
  Uint8List bytes, {
  required V3PromptDataEncoding dataEncoding,
}) =>
    switch (dataEncoding) {
      V3PromptDataEncoding.base64 => base64Encode(bytes),
      V3PromptDataEncoding.bytes => bytes.toList(growable: false),
    };

sealed class _V3DecodedDataContent {
  const _V3DecodedDataContent();
}

class _V3UrlData extends _V3DecodedDataContent {
  final String url;
  const _V3UrlData(this.url);
}

Object _decodeV3DataContent(Object? value) {
  if (value is String) {
    final uri = Uri.tryParse(value);
    final isUrl = uri != null &&
        uri.scheme.isNotEmpty &&
        (uri.scheme == 'http' ||
            uri.scheme == 'https' ||
            uri.scheme == 'data') &&
        (uri.scheme == 'data' || (uri.host.isNotEmpty));
    if (isUrl) return _V3UrlData(value);

    try {
      return Uint8List.fromList(base64Decode(value));
    } catch (_) {
      throw const FormatException(
        'v3 prompt file.data string is neither a URL nor valid base64.',
      );
    }
  }

  if (value is List) {
    final bytes = <int>[];
    for (final item in value) {
      final n = item is int ? item : (item is num ? item.toInt() : null);
      if (n == null || n < 0 || n > 255) {
        throw const FormatException(
          'v3 prompt file.data byte array must contain integers in range 0..255.',
        );
      }
      bytes.add(n);
    }
    return Uint8List.fromList(bytes);
  }

  throw const FormatException('v3 prompt file.data must be a string or list.');
}

ProviderOptions? _asProviderOptions(Object? value) {
  if (value is! Map) return null;
  return value.map<String, Map<String, dynamic>>(
    (k, v) => MapEntry(
      k.toString(),
      v is Map ? v.cast<String, dynamic>() : <String, dynamic>{},
    ),
  );
}

ImageMime? _imageMimeFromMediaType(String mediaType) => switch (mediaType) {
      'image/jpeg' => ImageMime.jpeg,
      'image/png' => ImageMime.png,
      'image/gif' => ImageMime.gif,
      'image/webp' => ImageMime.webp,
      _ => null,
    };

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

Map<String, dynamic>? _normalizeAndValidateToolResultOutput(Object? parsed) {
  if (parsed == null) return null;

  if (parsed is String) {
    return {
      'type': 'text',
      'value': parsed,
    };
  }

  if (parsed is num || parsed is bool) {
    return {
      'type': 'json',
      'value': parsed,
    };
  }

  if (parsed is List) {
    return {
      'type': 'json',
      'value': _normalizeJsonLike(parsed),
    };
  }

  if (parsed is! Map) return null;

  final typeRaw = parsed['type'];
  if (typeRaw is! String || typeRaw.isEmpty) {
    return {
      'type': 'json',
      'value': _normalizeJsonLike(parsed),
    };
  }

  Map<String, dynamic> normalizeMap(Map value) =>
      value.map((k, v) => MapEntry(k.toString(), _normalizeJsonLike(v)));

  Map<String, dynamic>? normalizeSharedProviderOptions(Object? value) {
    if (value is! Map) return null;
    final out = <String, dynamic>{};
    value.forEach((k, v) {
      out[k.toString()] = _normalizeJsonLike(v);
    });
    return out.isEmpty ? null : out;
  }

  final outputProviderOptions =
      normalizeSharedProviderOptions(parsed['providerOptions']);

  switch (typeRaw) {
    case 'text':
      final value = parsed['value'];
      if (value is! String) {
        throw const FormatException(
          'v3 prompt tool-result output type=text requires string "value".',
        );
      }
      return {
        'type': 'text',
        'value': value,
        if (outputProviderOptions != null)
          'providerOptions': outputProviderOptions,
      };

    case 'json':
      if (!parsed.containsKey('value')) {
        throw const FormatException(
          'v3 prompt tool-result output type=json requires "value".',
        );
      }
      return {
        'type': 'json',
        'value': _normalizeJsonLike(parsed['value']),
        if (outputProviderOptions != null)
          'providerOptions': outputProviderOptions,
      };

    case 'execution-denied':
      final reason = parsed['reason'];
      if (reason != null && reason is! String) {
        throw const FormatException(
          'v3 prompt tool-result output type=execution-denied requires string "reason" when present.',
        );
      }
      return {
        'type': 'execution-denied',
        if (reason is String && reason.isNotEmpty) 'reason': reason,
        if (outputProviderOptions != null)
          'providerOptions': outputProviderOptions,
      };

    case 'error-text':
      final value = parsed['value'];
      if (value is! String) {
        throw const FormatException(
          'v3 prompt tool-result output type=error-text requires string "value".',
        );
      }
      return {
        'type': 'error-text',
        'value': value,
        if (outputProviderOptions != null)
          'providerOptions': outputProviderOptions,
      };

    case 'error-json':
      if (!parsed.containsKey('value')) {
        throw const FormatException(
          'v3 prompt tool-result output type=error-json requires "value".',
        );
      }
      return {
        'type': 'error-json',
        'value': _normalizeJsonLike(parsed['value']),
        if (outputProviderOptions != null)
          'providerOptions': outputProviderOptions,
      };

    case 'content':
      final value = parsed['value'];
      if (value is! List) {
        throw const FormatException(
          'v3 prompt tool-result output type=content requires list "value".',
        );
      }

      final items = <Map<String, dynamic>>[];
      for (final item in value) {
        if (item is! Map) {
          throw const FormatException(
            'v3 prompt tool-result output content items must be objects.',
          );
        }
        final itemType = item['type'];
        if (itemType is! String || itemType.isEmpty) {
          throw const FormatException(
            'v3 prompt tool-result output content item missing non-empty "type".',
          );
        }

        switch (itemType) {
          case 'text':
            final text = item['text'];
            if (text is! String) {
              throw const FormatException(
                'v3 prompt tool-result output content item type=text requires string "text".',
              );
            }
            final itemProviderOptions =
                normalizeSharedProviderOptions(item['providerOptions']);
            items.add({
              'type': 'text',
              'text': text,
              if (itemProviderOptions != null)
                'providerOptions': itemProviderOptions,
            });
            break;

          case 'file-data':
            final data = item['data'];
            final mediaType = item['mediaType'];
            if (data is! String || data.isEmpty) {
              throw const FormatException(
                'v3 prompt tool-result output content item type=file-data requires non-empty string "data".',
              );
            }
            if (mediaType is! String || mediaType.isEmpty) {
              throw const FormatException(
                'v3 prompt tool-result output content item type=file-data requires non-empty string "mediaType".',
              );
            }
            final filename = item['filename'];
            if (filename != null && filename is! String) {
              throw const FormatException(
                'v3 prompt tool-result output content item type=file-data requires string "filename" when present.',
              );
            }
            final itemProviderOptions =
                normalizeSharedProviderOptions(item['providerOptions']);
            items.add({
              'type': 'file-data',
              'data': data,
              'mediaType': mediaType,
              if (filename is String && filename.isNotEmpty)
                'filename': filename,
              if (itemProviderOptions != null)
                'providerOptions': itemProviderOptions,
            });
            break;

          case 'file-url':
            final url = item['url'];
            if (url is! String || url.isEmpty) {
              throw const FormatException(
                'v3 prompt tool-result output content item type=file-url requires non-empty string "url".',
              );
            }
            final itemProviderOptions =
                normalizeSharedProviderOptions(item['providerOptions']);
            items.add({
              'type': 'file-url',
              'url': url,
              if (itemProviderOptions != null)
                'providerOptions': itemProviderOptions,
            });
            break;

          case 'image-data':
            final data = item['data'];
            final mediaType = item['mediaType'];
            if (data is! String || data.isEmpty) {
              throw const FormatException(
                'v3 prompt tool-result output content item type=image-data requires non-empty string "data".',
              );
            }
            if (mediaType is! String || mediaType.isEmpty) {
              throw const FormatException(
                'v3 prompt tool-result output content item type=image-data requires non-empty string "mediaType".',
              );
            }
            final itemProviderOptions =
                normalizeSharedProviderOptions(item['providerOptions']);
            items.add({
              'type': 'image-data',
              'data': data,
              'mediaType': mediaType,
              if (itemProviderOptions != null)
                'providerOptions': itemProviderOptions,
            });
            break;

          case 'image-url':
            final url = item['url'];
            if (url is! String || url.isEmpty) {
              throw const FormatException(
                'v3 prompt tool-result output content item type=image-url requires non-empty string "url".',
              );
            }
            final itemProviderOptions =
                normalizeSharedProviderOptions(item['providerOptions']);
            items.add({
              'type': 'image-url',
              'url': url,
              if (itemProviderOptions != null)
                'providerOptions': itemProviderOptions,
            });
            break;

          case 'file-id':
          case 'image-file-id':
            final fileId = item['fileId'];
            if (fileId is String && fileId.isNotEmpty) {
              final itemProviderOptions =
                  normalizeSharedProviderOptions(item['providerOptions']);
              items.add({
                'type': itemType,
                'fileId': fileId,
                if (itemProviderOptions != null)
                  'providerOptions': itemProviderOptions,
              });
              break;
            }
            if (fileId is Map) {
              final normalized = <String, String>{};
              fileId.forEach((k, v) {
                if (k is String && v is String && v.isNotEmpty) {
                  normalized[k] = v;
                }
              });
              if (normalized.isEmpty) {
                throw const FormatException(
                  'v3 prompt tool-result output content item fileId map must contain string values.',
                );
              }
              final itemProviderOptions =
                  normalizeSharedProviderOptions(item['providerOptions']);
              items.add({
                'type': itemType,
                'fileId': normalized,
                if (itemProviderOptions != null)
                  'providerOptions': itemProviderOptions,
              });
              break;
            }
            throw const FormatException(
              'v3 prompt tool-result output content item requires "fileId" (string or map).',
            );

          case 'custom':
            items.add(normalizeMap(item));
            break;

          default:
            throw FormatException(
              'v3 prompt tool-result output content item unsupported type: $itemType',
            );
        }
      }

      return {
        'type': 'content',
        'value': items,
        if (outputProviderOptions != null)
          'providerOptions': outputProviderOptions,
      };

    default:
      throw FormatException(
          'v3 prompt tool-result output unsupported type: $typeRaw');
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

ProviderOptions _mergeProviderOptions(
  ProviderOptions a,
  ProviderOptions b,
) {
  if (a.isEmpty) return b;
  if (b.isEmpty) return a;

  final merged = <String, Map<String, dynamic>>{...a};
  for (final entry in b.entries) {
    final existing = merged[entry.key];
    merged[entry.key] = {...?existing, ...entry.value};
  }
  return merged;
}
