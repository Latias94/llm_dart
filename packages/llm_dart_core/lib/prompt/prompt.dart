import 'dart:convert';

import 'package:llm_dart_core/core/provider_options.dart';
import 'package:llm_dart_core/models/chat_models.dart';

/// Role of a message in the Vercel-style prompt IR.
///
/// This is intentionally separate from [ChatRole] because the legacy
/// prompt IR needs a dedicated `tool` role with additional constraints (only
/// tool results / approvals are allowed in tool messages).
enum PromptRole {
  system,
  user,
  assistant,
  tool,
}

/// A Vercel-style prompt intermediate representation (IR).
///
/// This IR is provider-agnostic and can be compiled to legacy `ChatMessage`
/// lists for providers that still consume the message model.
///
/// Design notes:
/// - `providerOptions` can be attached at message and part level.
/// - Part-level providerOptions override message-level providerOptions.
/// - Providers can additionally apply config-level defaults from
///   `LLMConfig.providerOptions`.
class Prompt {
  final List<PromptMessage> messages;

  const Prompt({required this.messages});

  /// Compile this prompt IR into a sequence of legacy `ChatMessage`s.
  ///
  /// This is a best-effort adapter that preserves ordering by emitting one
  /// `ChatMessage` per part.
  List<ChatMessage> toChatMessages() =>
      messages.expand((m) => m.toChatMessages()).toList(growable: false);
}

class PromptMessage {
  final PromptRole role;
  final List<PromptPart> parts;
  final String? name;
  final ProviderOptions providerOptions;

  /// Provider-specific protocol payloads (internal).
  ///
  /// This is an escape hatch for protocol adapters that must persist
  /// provider-native content blocks through the legacy `ChatMessage` model.
  ///
  /// App code should prefer:
  /// - Prompt parts + providerOptions for prompt composition
  /// - providerOptions for provider-only knobs
  final Map<String, dynamic> protocolPayloads;

  const PromptMessage({
    required this.role,
    required this.parts,
    this.name,
    this.providerOptions = const {},
    this.protocolPayloads = const {},
  });

  factory PromptMessage.system(
    String text, {
    String? name,
    ProviderOptions providerOptions = const {},
  }) =>
      PromptMessage(
        role: PromptRole.system,
        parts: [TextPart(text, providerOptions: providerOptions)],
        name: name,
        providerOptions: providerOptions,
      );

  factory PromptMessage.user(
    String text, {
    ProviderOptions providerOptions = const {},
  }) =>
      PromptMessage(
        role: PromptRole.user,
        parts: [TextPart(text, providerOptions: providerOptions)],
        providerOptions: providerOptions,
      );

  factory PromptMessage.assistant(
    String text, {
    ProviderOptions providerOptions = const {},
  }) =>
      PromptMessage(
        role: PromptRole.assistant,
        parts: [TextPart(text, providerOptions: providerOptions)],
        providerOptions: providerOptions,
      );

  factory PromptMessage.tool({
    required List<PromptPart> parts,
    ProviderOptions providerOptions = const {},
  }) =>
      PromptMessage(
        role: PromptRole.tool,
        parts: parts,
        providerOptions: providerOptions,
      );

  static ChatRole _toChatRole(PromptRole role) {
    return switch (role) {
      PromptRole.system => ChatRole.system,
      PromptRole.user => ChatRole.user,
      PromptRole.assistant => ChatRole.assistant,
      PromptRole.tool => ChatRole.tool,
    };
  }

  List<ChatMessage> toChatMessages() {
    final result = <ChatMessage>[];

    for (final part in parts) {
      final effectiveProviderOptions =
          _mergeProviderOptions(providerOptions, part.providerOptions);

      switch (part) {
        case TextPart(:final text):
          result.add(
            ChatMessage(
              role: _toChatRole(role),
              messageType: const TextMessage(),
              content: text,
              name: name,
              protocolPayloads: protocolPayloads,
              providerOptions: effectiveProviderOptions,
            ),
          );

        case ImagePart(:final mime, :final data, :final text):
          if (role == PromptRole.system) {
            throw ArgumentError('System messages cannot contain images.');
          }
          result.add(
            ChatMessage.image(
              role: _toChatRole(role),
              mime: mime,
              data: data,
              content: text ?? '',
              protocolPayloads: protocolPayloads,
              providerOptions: effectiveProviderOptions,
            ),
          );

        case ImageUrlPart(:final url, :final text):
          if (role == PromptRole.system) {
            throw ArgumentError('System messages cannot contain image URLs.');
          }
          result.add(
            ChatMessage.imageUrl(
              role: _toChatRole(role),
              url: url,
              content: text ?? '',
              protocolPayloads: protocolPayloads,
              providerOptions: effectiveProviderOptions,
            ),
          );

        case FilePart(:final mime, :final data, :final text):
          if (role == PromptRole.system) {
            throw ArgumentError('System messages cannot contain files.');
          }
          result.add(
            ChatMessage.file(
              role: _toChatRole(role),
              mime: mime,
              data: data,
              content: text ?? '',
              protocolPayloads: protocolPayloads,
              providerOptions: effectiveProviderOptions,
            ),
          );

        case FileUrlPart():
          throw ArgumentError(
            'FileUrlPart cannot be converted to legacy ChatMessage. '
            'Use a provider that implements PromptChatCapability / '
            'PromptChatStreamPartsCapability.',
          );

        case FileIdPart():
          throw ArgumentError(
            'FileIdPart cannot be converted to legacy ChatMessage. '
            'Use a provider that implements PromptChatCapability / '
            'PromptChatStreamPartsCapability.',
          );

        case ToolCallPart(
            :final toolCallId,
            :final toolName,
            :final input,
            :final overrideRole,
          ):
          final effectiveRole = overrideRole ?? role;
          if (effectiveRole != PromptRole.assistant) {
            throw ArgumentError(
              'ToolCallPart must be emitted from an assistant message.',
            );
          }

          final mergedToolCall = ToolCall(
            id: toolCallId,
            callType: 'function',
            function: FunctionCall(
              name: toolName,
              arguments: jsonEncode(_normalizeJsonLike(input)),
            ),
            providerOptions: effectiveProviderOptions,
          );

          result.add(
            ChatMessage.toolUse(
              toolCalls: [mergedToolCall],
              protocolPayloads: protocolPayloads,
              providerOptions: effectiveProviderOptions,
            ),
          );

        case ToolResultPart(
            :final toolCallId,
            :final toolName,
            :final output,
            :final overrideRole,
          ):
          final effectiveRole = overrideRole ?? role;
          if (effectiveRole != PromptRole.tool) {
            throw ArgumentError(
              'ToolResultPart must be emitted from a tool message.',
            );
          }

          final mergedToolResultProviderOptions = _mergeProviderOptions(
              effectiveProviderOptions, output.providerOptions);

          final mergedToolResult = ToolCall(
            id: toolCallId,
            callType: 'function',
            function: FunctionCall(
              name: toolName,
              arguments: _stringifyToolResultOutput(output),
            ),
            providerOptions: mergedToolResultProviderOptions,
          );

          result.add(
            ChatMessage.toolResult(
              results: [mergedToolResult],
              protocolPayloads: protocolPayloads,
              providerOptions: effectiveProviderOptions,
            ),
          );

        case ToolApprovalResponsePart():
          throw ArgumentError(
            'ToolApprovalResponsePart cannot be converted to legacy ChatMessage. '
            'Use a provider that implements PromptChatCapability / '
            'PromptChatStreamPartsCapability.',
          );

        case ToolApprovalRequestPart():
          throw ArgumentError(
            'ToolApprovalRequestPart cannot be converted to legacy ChatMessage. '
            'Use a provider that implements PromptChatCapability / '
            'PromptChatStreamPartsCapability.',
          );
      }
    }

    return List<ChatMessage>.unmodifiable(result);
  }
}

sealed class PromptPart {
  final ProviderOptions providerOptions;

  const PromptPart({this.providerOptions = const {}});
}

class TextPart extends PromptPart {
  final String text;

  const TextPart(this.text, {super.providerOptions});
}

class ImagePart extends PromptPart {
  final ImageMime mime;
  final List<int> data;
  final String? text;

  const ImagePart({
    required this.mime,
    required this.data,
    this.text,
    super.providerOptions,
  });
}

class ImageUrlPart extends PromptPart {
  final String url;
  final String? text;

  const ImageUrlPart({
    required this.url,
    this.text,
    super.providerOptions,
  });
}

class FilePart extends PromptPart {
  final FileMime mime;
  final List<int> data;
  final String? text;

  const FilePart({
    required this.mime,
    required this.data,
    this.text,
    super.providerOptions,
  });
}

/// A URL-based file prompt part.
///
/// This models provider-native "file URL" inputs (AI SDK style) and is intended
/// to be consumed by prompt-native provider request builders.
///
/// Notes:
/// - This part cannot be losslessly converted to legacy `ChatMessage` because
///   the message model has no file-url message type.
/// - Use providers that implement `PromptChatCapability` /
///   `PromptChatStreamPartsCapability`.
class FileUrlPart extends PromptPart {
  final FileMime mime;
  final String url;
  final String? text;

  const FileUrlPart({
    required this.mime,
    required this.url,
    this.text,
    super.providerOptions,
  });
}

/// A provider-managed file reference prompt part.
///
/// This models provider-native file references, e.g.:
/// - Google Generative Language Files API resource names (`files/...`)
/// - OpenAI file ids (`file-...`)
///
/// Notes:
/// - This part cannot be losslessly converted to legacy `ChatMessage` because
///   the message model has no file-id message type.
/// - Use providers that implement `PromptChatCapability` /
///   `PromptChatStreamPartsCapability`.
class FileIdPart extends PromptPart {
  final FileMime mime;
  final String id;
  final String? text;

  const FileIdPart({
    required this.mime,
    required this.id,
    this.text,
    super.providerOptions,
  });
}

class ToolCallPart extends PromptPart {
  final String toolCallId;
  final String toolName;

  /// Tool input (JSON-serializable).
  final Object? input;

  /// Whether the tool call will be executed by the provider.
  ///
  /// If null/false, the tool call is expected to be executed by the client.
  final bool? providerExecuted;

  /// Override role when this part is embedded into a mixed-role prompt message.
  ///
  /// If null, the enclosing `PromptMessage.role` is used.
  final PromptRole? overrideRole;

  const ToolCallPart({
    required this.toolCallId,
    required this.toolName,
    required this.input,
    this.providerExecuted,
    this.overrideRole,
    super.providerOptions,
  });

  factory ToolCallPart.fromToolCall(
    ToolCall toolCall, {
    PromptRole? overrideRole,
    ProviderOptions providerOptions = const {},
  }) {
    Object input;
    final raw = toolCall.function.arguments.trim();
    if (raw.isEmpty) {
      input = const <String, dynamic>{};
    } else {
      try {
        input = jsonDecode(raw);
      } catch (_) {
        // Best-effort: keep as string for non-JSON tool call args.
        input = raw;
      }
    }

    return ToolCallPart(
      toolCallId: toolCall.id,
      toolName: toolCall.function.name,
      input: _normalizeJsonLike(input),
      providerExecuted: null,
      overrideRole: overrideRole,
      providerOptions:
          _mergeProviderOptions(toolCall.providerOptions, providerOptions),
    );
  }
}

class ToolResultPart extends PromptPart {
  final String toolCallId;
  final String toolName;
  final ToolResultOutput output;

  /// Override role when this part is embedded into a mixed-role prompt message.
  ///
  /// If null, the enclosing `PromptMessage.role` is used.
  final PromptRole? overrideRole;

  const ToolResultPart(
    this.toolCallId,
    this.toolName,
    this.output, {
    this.overrideRole,
    super.providerOptions,
  });

  factory ToolResultPart.fromToolCall(
    ToolCall toolResult, {
    PromptRole? overrideRole,
    ProviderOptions providerOptions = const {},
  }) {
    final raw = toolResult.function.arguments;
    ToolResultOutput output;

    // Best-effort: if the content looks like a v3 tool-result output envelope,
    // decode it. Otherwise treat JSON values as json output and everything else
    // as plain text output.
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map) {
        final map = parsed.cast<String, dynamic>();
        if (map['type'] is String) {
          output = ToolResultOutput.fromJson(map);
        } else {
          output = ToolResultJsonOutput(_normalizeJsonLike(map));
        }
      } else if (parsed is List || parsed is num || parsed is bool) {
        output = ToolResultJsonOutput(_normalizeJsonLike(parsed));
      } else {
        output = ToolResultTextOutput(raw);
      }
    } catch (_) {
      output = ToolResultTextOutput(raw);
    }

    if (toolResult.providerOptions.isNotEmpty) {
      output = switch (output) {
        ToolResultTextOutput(:final value, :final providerOptions) =>
          ToolResultTextOutput(
            value,
            providerOptions: _mergeProviderOptions(
                toolResult.providerOptions, providerOptions),
          ),
        ToolResultJsonOutput(:final value, :final providerOptions) =>
          ToolResultJsonOutput(
            value,
            providerOptions: _mergeProviderOptions(
                toolResult.providerOptions, providerOptions),
          ),
        ToolResultExecutionDeniedOutput(
          :final reason,
          :final providerOptions
        ) =>
          ToolResultExecutionDeniedOutput(
            reason: reason,
            providerOptions: _mergeProviderOptions(
                toolResult.providerOptions, providerOptions),
          ),
        ToolResultErrorTextOutput(:final value, :final providerOptions) =>
          ToolResultErrorTextOutput(
            value,
            providerOptions: _mergeProviderOptions(
                toolResult.providerOptions, providerOptions),
          ),
        ToolResultErrorJsonOutput(:final value, :final providerOptions) =>
          ToolResultErrorJsonOutput(
            value,
            providerOptions: _mergeProviderOptions(
                toolResult.providerOptions, providerOptions),
          ),
        ToolResultContentOutput(:final value, :final providerOptions) =>
          ToolResultContentOutput(
            value,
            providerOptions: _mergeProviderOptions(
                toolResult.providerOptions, providerOptions),
          ),
      };
    }

    return ToolResultPart(
      toolResult.id,
      toolResult.function.name,
      output,
      overrideRole: overrideRole,
      providerOptions: providerOptions,
    );
  }
}

/// Tool approval response prompt part (AI SDK v3-style).
///
/// This represents the user's decision to approve or deny a provider-executed
/// tool call (e.g. MCP tools). It is intended for prompt-native provider
/// request builders and cannot be losslessly compiled to legacy [ChatMessage].
class ToolApprovalResponsePart extends PromptPart {
  /// Approval request id (AI SDK v3 `approvalId`).
  final String approvalId;

  /// Whether the approval was granted.
  final bool approved;

  /// Optional reason for the decision.
  final String? reason;

  const ToolApprovalResponsePart({
    required this.approvalId,
    required this.approved,
    this.reason,
    super.providerOptions,
  });
}

/// Tool approval request prompt part (AI SDK v3-style).
///
/// This represents the model/provider requesting approval for a provider-executed
/// tool call. The corresponding decision should be sent back as a
/// [ToolApprovalResponsePart] in a subsequent tool message.
class ToolApprovalRequestPart extends PromptPart {
  /// Approval request id (AI SDK v3 `approvalId`).
  final String approvalId;

  /// Tool call id that this approval request is for.
  final String toolCallId;

  const ToolApprovalRequestPart({
    required this.approvalId,
    required this.toolCallId,
    super.providerOptions,
  });
}

ProviderOptions _mergeProviderOptions(
  ProviderOptions base,
  ProviderOptions override,
) {
  if (base.isEmpty) return override;
  if (override.isEmpty) return base;

  final merged = <String, Map<String, dynamic>>{...base};
  for (final entry in override.entries) {
    final existing = merged[entry.key];
    merged[entry.key] = {...?existing, ...entry.value};
  }
  return merged;
}

String _stringifyToolResultOutput(ToolResultOutput output) {
  switch (output) {
    case ToolResultTextOutput(:final value):
      return value;

    case ToolResultErrorTextOutput(:final value):
      return value;

    case ToolResultExecutionDeniedOutput(:final reason):
      return (reason != null && reason.trim().isNotEmpty)
          ? reason.trim()
          : 'Tool execution denied.';

    case ToolResultJsonOutput(:final value):
    case ToolResultErrorJsonOutput(:final value):
      try {
        return jsonEncode(value);
      } catch (_) {
        return value.toString();
      }

    case ToolResultContentOutput(:final value):
      try {
        return jsonEncode(value.map((e) => e.toJson()).toList(growable: false));
      } catch (_) {
        return value.toString();
      }
  }
}

Object? _normalizeJsonLike(Object? value) {
  if (value == null) return null;
  if (value is num || value is bool || value is String) return value;

  if (value is List) {
    return value.map(_normalizeJsonLike).toList(growable: false);
  }

  if (value is Map) {
    final out = <String, Object?>{};
    value.forEach((k, v) {
      out[k.toString()] = _normalizeJsonLike(v);
    });
    return out;
  }

  // Best-effort: stringify unknown objects.
  return value.toString();
}

sealed class ToolResultOutput {
  final ProviderOptions providerOptions;
  const ToolResultOutput({this.providerOptions = const {}});

  Map<String, dynamic> toJson();

  static ToolResultOutput fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    if (type is! String || type.trim().isEmpty) {
      throw const FormatException(
        'tool-result output missing non-empty "type".',
      );
    }

    ProviderOptions parseProviderOptions(Object? value) {
      if (value is! Map) return const {};
      return value.map<String, Map<String, dynamic>>(
        (k, v) => MapEntry(
          k.toString(),
          (v is Map ? v.cast<String, dynamic>() : const <String, dynamic>{}),
        ),
      );
    }

    final providerOptions = parseProviderOptions(json['providerOptions']);

    switch (type) {
      case 'text':
        final value = json['value'];
        if (value is! String) {
          throw const FormatException(
            'tool-result output type=text requires string "value".',
          );
        }
        return ToolResultTextOutput(value, providerOptions: providerOptions);

      case 'json':
        if (!json.containsKey('value')) {
          throw const FormatException(
            'tool-result output type=json requires "value".',
          );
        }
        return ToolResultJsonOutput(
          _normalizeJsonLike(json['value']),
          providerOptions: providerOptions,
        );

      case 'execution-denied':
        final reason = json['reason'];
        if (reason != null && reason is! String) {
          throw const FormatException(
            'tool-result output type=execution-denied requires string "reason" when present.',
          );
        }
        return ToolResultExecutionDeniedOutput(
          reason: (reason is String && reason.trim().isNotEmpty)
              ? reason.trim()
              : null,
          providerOptions: providerOptions,
        );

      case 'error-text':
        final value = json['value'];
        if (value is! String) {
          throw const FormatException(
            'tool-result output type=error-text requires string "value".',
          );
        }
        return ToolResultErrorTextOutput(value,
            providerOptions: providerOptions);

      case 'error-json':
        if (!json.containsKey('value')) {
          throw const FormatException(
            'tool-result output type=error-json requires "value".',
          );
        }
        return ToolResultErrorJsonOutput(
          _normalizeJsonLike(json['value']),
          providerOptions: providerOptions,
        );

      case 'content':
        final value = json['value'];
        if (value is! List) {
          throw const FormatException(
            'tool-result output type=content requires list "value".',
          );
        }
        final items = value.map((e) {
          if (e is! Map) {
            throw const FormatException(
              'tool-result output content items must be objects.',
            );
          }
          return ToolResultContentItem.fromJson(e.cast<String, dynamic>());
        }).toList(growable: false);
        return ToolResultContentOutput(items, providerOptions: providerOptions);

      default:
        throw FormatException('Unsupported tool-result output type: $type');
    }
  }
}

class ToolResultTextOutput extends ToolResultOutput {
  final String value;
  const ToolResultTextOutput(
    this.value, {
    super.providerOptions,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        'value': value,
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      };
}

class ToolResultJsonOutput extends ToolResultOutput {
  final Object? value;
  const ToolResultJsonOutput(
    this.value, {
    super.providerOptions,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'json',
        'value': value,
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      };
}

class ToolResultExecutionDeniedOutput extends ToolResultOutput {
  final String? reason;
  const ToolResultExecutionDeniedOutput({
    this.reason,
    super.providerOptions,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'execution-denied',
        if (reason != null && reason!.trim().isNotEmpty) 'reason': reason,
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      };
}

class ToolResultErrorTextOutput extends ToolResultOutput {
  final String value;
  const ToolResultErrorTextOutput(
    this.value, {
    super.providerOptions,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'error-text',
        'value': value,
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      };
}

class ToolResultErrorJsonOutput extends ToolResultOutput {
  final Object? value;
  const ToolResultErrorJsonOutput(
    this.value, {
    super.providerOptions,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'error-json',
        'value': value,
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      };
}

class ToolResultContentOutput extends ToolResultOutput {
  final List<ToolResultContentItem> value;
  const ToolResultContentOutput(
    this.value, {
    super.providerOptions,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'content',
        'value': value.map((e) => e.toJson()).toList(growable: false),
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      };
}

sealed class ToolResultContentItem {
  final ProviderOptions providerOptions;
  const ToolResultContentItem({this.providerOptions = const {}});

  Map<String, dynamic> toJson();

  static ToolResultContentItem fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    if (type is! String || type.trim().isEmpty) {
      throw const FormatException(
        'tool-result content item missing non-empty "type".',
      );
    }

    ProviderOptions parseProviderOptions(Object? value) {
      if (value is! Map) return const {};
      return value.map<String, Map<String, dynamic>>(
        (k, v) => MapEntry(
          k.toString(),
          (v is Map ? v.cast<String, dynamic>() : const <String, dynamic>{}),
        ),
      );
    }

    final providerOptions = parseProviderOptions(json['providerOptions']);

    switch (type) {
      case 'text':
        final text = json['text'];
        if (text is! String) {
          throw const FormatException(
            'tool-result content item type=text requires string "text".',
          );
        }
        return ToolResultContentText(text, providerOptions: providerOptions);

      case 'file-data':
        final data = json['data'];
        final mediaType = json['mediaType'];
        final filename = json['filename'];
        if (data is! String || data.isEmpty) {
          throw const FormatException(
            'tool-result content item type=file-data requires non-empty string "data".',
          );
        }
        if (mediaType is! String || mediaType.isEmpty) {
          throw const FormatException(
            'tool-result content item type=file-data requires non-empty string "mediaType".',
          );
        }
        if (filename != null && filename is! String) {
          throw const FormatException(
            'tool-result content item type=file-data requires string "filename" when present.',
          );
        }
        return ToolResultContentFileData(
          data: data,
          mediaType: mediaType,
          filename:
              (filename is String && filename.isNotEmpty) ? filename : null,
          providerOptions: providerOptions,
        );

      case 'file-url':
        final url = json['url'];
        if (url is! String || url.trim().isEmpty) {
          throw const FormatException(
            'tool-result content item type=file-url requires non-empty string "url".',
          );
        }
        return ToolResultContentFileUrl(url.trim(),
            providerOptions: providerOptions);

      case 'file-id':
        final fileId = json['fileId'];
        if (fileId is! String && fileId is! Map) {
          throw const FormatException(
            'tool-result content item type=file-id requires "fileId" (string or map).',
          );
        }
        if (fileId is Map) {
          for (final v in fileId.values) {
            if (v is! String) {
              throw const FormatException(
                'tool-result content item fileId map must contain string values.',
              );
            }
          }
        }
        return ToolResultContentFileId(
          fileId: _normalizeJsonLike(fileId) as Object,
          providerOptions: providerOptions,
        );

      case 'image-data':
        final data = json['data'];
        final mediaType = json['mediaType'];
        if (data is! String || data.isEmpty) {
          throw const FormatException(
            'tool-result content item type=image-data requires non-empty string "data".',
          );
        }
        if (mediaType is! String || mediaType.isEmpty) {
          throw const FormatException(
            'tool-result content item type=image-data requires non-empty string "mediaType".',
          );
        }
        return ToolResultContentImageData(
          data: data,
          mediaType: mediaType,
          providerOptions: providerOptions,
        );

      case 'image-url':
        final url = json['url'];
        if (url is! String || url.trim().isEmpty) {
          throw const FormatException(
            'tool-result content item type=image-url requires non-empty string "url".',
          );
        }
        return ToolResultContentImageUrl(url.trim(),
            providerOptions: providerOptions);

      case 'image-file-id':
        final fileId = json['fileId'];
        if (fileId is! String && fileId is! Map) {
          throw const FormatException(
            'tool-result content item type=image-file-id requires "fileId" (string or map).',
          );
        }
        if (fileId is Map) {
          for (final v in fileId.values) {
            if (v is! String) {
              throw const FormatException(
                'tool-result content item fileId map must contain string values.',
              );
            }
          }
        }
        return ToolResultContentImageFileId(
          fileId: _normalizeJsonLike(fileId) as Object,
          providerOptions: providerOptions,
        );

      case 'custom':
        return ToolResultContentCustom(providerOptions: providerOptions);

      default:
        throw FormatException(
          'Unsupported tool-result content item type: $type',
        );
    }
  }
}

class ToolResultContentText extends ToolResultContentItem {
  final String text;
  const ToolResultContentText(
    this.text, {
    super.providerOptions,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        'text': text,
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      };
}

class ToolResultContentFileData extends ToolResultContentItem {
  final String data;
  final String mediaType;
  final String? filename;
  const ToolResultContentFileData({
    required this.data,
    required this.mediaType,
    this.filename,
    super.providerOptions,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'file-data',
        'data': data,
        'mediaType': mediaType,
        if (filename != null && filename!.isNotEmpty) 'filename': filename,
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      };
}

class ToolResultContentFileUrl extends ToolResultContentItem {
  final String url;
  const ToolResultContentFileUrl(
    this.url, {
    super.providerOptions,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'file-url',
        'url': url,
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      };
}

class ToolResultContentFileId extends ToolResultContentItem {
  final Object fileId;
  const ToolResultContentFileId({
    required this.fileId,
    super.providerOptions,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'file-id',
        'fileId': fileId,
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      };
}

class ToolResultContentImageData extends ToolResultContentItem {
  final String data;
  final String mediaType;
  const ToolResultContentImageData({
    required this.data,
    required this.mediaType,
    super.providerOptions,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'image-data',
        'data': data,
        'mediaType': mediaType,
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      };
}

class ToolResultContentImageUrl extends ToolResultContentItem {
  final String url;
  const ToolResultContentImageUrl(
    this.url, {
    super.providerOptions,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'image-url',
        'url': url,
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      };
}

class ToolResultContentImageFileId extends ToolResultContentItem {
  final Object fileId;
  const ToolResultContentImageFileId({
    required this.fileId,
    super.providerOptions,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'image-file-id',
        'fileId': fileId,
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      };
}

class ToolResultContentCustom extends ToolResultContentItem {
  const ToolResultContentCustom({
    super.providerOptions,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'custom',
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      };
}
