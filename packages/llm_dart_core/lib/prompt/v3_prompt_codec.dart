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
    out.add(_encodeV3PromptMessage(message, dataEncoding: dataEncoding));
  }

  return out;
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
    ChatRole.system => 'system',
    ChatRole.user => 'user',
    ChatRole.assistant => 'assistant',
  };

  final providerOptions = message.providerOptions;

  if (message.role == ChatRole.system) {
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

List<Map<String, dynamic>> _encodeV3PromptPartsForMessage({
  required ChatRole role,
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
      if (role == ChatRole.system) {
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
      if (role == ChatRole.system) {
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
      if (role == ChatRole.system) {
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
      if (role == ChatRole.system) {
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
        :final toolCall,
        providerOptions: final providerOptions,
      ):
      if (role != ChatRole.assistant) {
        throw const FormatException(
          'v3 prompt: tool-call parts are only supported in assistant messages.',
        );
      }
      final mergedProviderOptions =
          _mergeProviderOptions(toolCall.providerOptions, providerOptions);
      out.add({
        'type': 'tool-call',
        'toolCallId': toolCall.id,
        'toolName': toolCall.function.name,
        'input': _decodeJsonIfPossible(toolCall.function.arguments) ??
            toolCall.function.arguments,
        if (mergedProviderOptions.isNotEmpty)
          'providerOptions': mergedProviderOptions,
      });
      return out;

    case ToolResultPart(
        :final toolResult,
        providerOptions: final providerOptions,
      ):
      if (role != ChatRole.assistant) {
        throw const FormatException(
          'v3 prompt: tool-result parts are only supported in assistant messages.',
        );
      }

      final mergedProviderOptions =
          _mergeProviderOptions(toolResult.providerOptions, providerOptions);
      final parsed = _decodeJsonIfPossible(toolResult.function.arguments);
      final output = _normalizeToolResultOutput(parsed) ??
          _normalizeToolResultOutput(toolResult.function.arguments) ??
          {
            'type': 'text',
            'value': toolResult.function.arguments,
          };

      out.add({
        'type': 'tool-result',
        'toolCallId': toolResult.id,
        'toolName': toolResult.function.name,
        'output': output,
        if (mergedProviderOptions.isNotEmpty)
          'providerOptions': mergedProviderOptions,
      });
      return out;
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
      role: ChatRole.system,
      parts: [TextPart(content)],
      providerOptions: providerOptions,
    );
  }

  final content = obj['content'];
  if (content is! List) {
    throw const FormatException('v3 prompt message missing list "content".');
  }

  final role = switch (roleRaw) {
    'user' => ChatRole.user,
    'assistant' => ChatRole.assistant,
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
  required ChatRole role,
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
      if (role != ChatRole.assistant) {
        throw const FormatException(
          'v3 prompt: tool-call parts are only supported in assistant messages.',
        );
      }
      final toolCallId = obj['toolCallId'];
      final toolName = obj['toolName'];
      if (toolCallId is! String || toolCallId.isEmpty) {
        throw const FormatException(
            'v3 prompt tool-call missing "toolCallId".');
      }
      if (toolName is! String || toolName.isEmpty) {
        throw const FormatException('v3 prompt tool-call missing "toolName".');
      }
      final input = obj['input'];
      return ToolCallPart(
        ToolCall(
          id: toolCallId,
          callType: 'function',
          function: FunctionCall(
            name: toolName,
            arguments: jsonEncode(_normalizeJsonLike(input)),
          ),
          providerOptions: providerOptions,
        ),
      );

    case 'tool-result':
      if (role != ChatRole.assistant) {
        throw const FormatException(
          'v3 prompt: tool-result parts are only supported in assistant messages.',
        );
      }
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
      return ToolResultPart(
        ToolCall(
          id: toolCallId,
          callType: 'function',
          function: FunctionCall(
            name: toolName,
            arguments: jsonEncode(_normalizeJsonLike(output)),
          ),
          providerOptions: providerOptions,
        ),
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

Object? _normalizeToolResultOutput(Object? parsed) {
  if (parsed is Map) {
    final type = parsed['type'];
    if (type is String && type.isNotEmpty) {
      // If it already looks like a LanguageModelV3ToolResultOutput, preserve it.
      if (parsed.containsKey('value') || parsed.containsKey('reason')) {
        return _normalizeJsonLike(parsed);
      }
    }
    // Otherwise treat as JSON.
    return {
      'type': 'json',
      'value': _normalizeJsonLike(parsed),
    };
  }

  if (parsed is List) {
    return {
      'type': 'json',
      'value': _normalizeJsonLike(parsed),
    };
  }

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

  return null;
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
