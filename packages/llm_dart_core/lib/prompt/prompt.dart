import 'package:llm_dart_core/core/provider_options.dart';
import 'package:llm_dart_core/models/chat_models.dart';

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
  final ChatRole role;
  final List<PromptPart> parts;
  final String? name;
  final ProviderOptions providerOptions;

  const PromptMessage({
    required this.role,
    required this.parts,
    this.name,
    this.providerOptions = const {},
  });

  factory PromptMessage.system(
    String text, {
    String? name,
    ProviderOptions providerOptions = const {},
  }) =>
      PromptMessage(
        role: ChatRole.system,
        parts: [TextPart(text, providerOptions: providerOptions)],
        name: name,
        providerOptions: providerOptions,
      );

  factory PromptMessage.user(
    String text, {
    ProviderOptions providerOptions = const {},
  }) =>
      PromptMessage(
        role: ChatRole.user,
        parts: [TextPart(text, providerOptions: providerOptions)],
        providerOptions: providerOptions,
      );

  factory PromptMessage.assistant(
    String text, {
    ProviderOptions providerOptions = const {},
  }) =>
      PromptMessage(
        role: ChatRole.assistant,
        parts: [TextPart(text, providerOptions: providerOptions)],
        providerOptions: providerOptions,
      );

  List<ChatMessage> toChatMessages() {
    final result = <ChatMessage>[];

    for (final part in parts) {
      final effectiveProviderOptions =
          _mergeProviderOptions(providerOptions, part.providerOptions);

      switch (part) {
        case TextPart(:final text):
          result.add(
            ChatMessage(
              role: role,
              messageType: const TextMessage(),
              content: text,
              name: name,
              providerOptions: effectiveProviderOptions,
            ),
          );

        case ImagePart(:final mime, :final data, :final text):
          if (role == ChatRole.system) {
            throw ArgumentError('System messages cannot contain images.');
          }
          result.add(
            ChatMessage.image(
              role: role,
              mime: mime,
              data: data,
              content: text ?? '',
              providerOptions: effectiveProviderOptions,
            ),
          );

        case ImageUrlPart(:final url, :final text):
          if (role == ChatRole.system) {
            throw ArgumentError('System messages cannot contain image URLs.');
          }
          result.add(
            ChatMessage.imageUrl(
              role: role,
              url: url,
              content: text ?? '',
              providerOptions: effectiveProviderOptions,
            ),
          );

        case FilePart(:final mime, :final data, :final text):
          if (role == ChatRole.system) {
            throw ArgumentError('System messages cannot contain files.');
          }
          result.add(
            ChatMessage.file(
              role: role,
              mime: mime,
              data: data,
              content: text ?? '',
              providerOptions: effectiveProviderOptions,
            ),
          );

        case ToolCallPart(:final toolCall, :final overrideRole):
          final effectiveRole = overrideRole ?? role;
          if (effectiveRole != ChatRole.assistant) {
            throw ArgumentError(
              'ToolCallPart must be emitted from an assistant message.',
            );
          }

          final mergedToolCall = _copyToolCallWithMergedProviderOptions(
            toolCall,
            effectiveProviderOptions,
          );

          result.add(
            ChatMessage.toolUse(
              toolCalls: [mergedToolCall],
              providerOptions: effectiveProviderOptions,
            ),
          );

        case ToolResultPart(:final toolResult, :final overrideRole):
          final effectiveRole = overrideRole ?? role;
          if (effectiveRole != ChatRole.user) {
            throw ArgumentError(
              'ToolResultPart must be emitted from a user message.',
            );
          }

          final mergedToolResult = _copyToolCallWithMergedProviderOptions(
            toolResult,
            effectiveProviderOptions,
          );

          result.add(
            ChatMessage.toolResult(
              results: [mergedToolResult],
              providerOptions: effectiveProviderOptions,
            ),
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

class ToolCallPart extends PromptPart {
  final ToolCall toolCall;

  /// Override role when this part is embedded into a mixed-role prompt message.
  ///
  /// If null, the enclosing `PromptMessage.role` is used.
  final ChatRole? overrideRole;

  const ToolCallPart(
    this.toolCall, {
    this.overrideRole,
    super.providerOptions,
  });
}

class ToolResultPart extends PromptPart {
  /// Encoded tool result in the `ToolCall` shape used by `ChatMessage.toolResult`.
  final ToolCall toolResult;

  /// Override role when this part is embedded into a mixed-role prompt message.
  ///
  /// If null, the enclosing `PromptMessage.role` is used.
  final ChatRole? overrideRole;

  const ToolResultPart(
    this.toolResult, {
    this.overrideRole,
    super.providerOptions,
  });
}

ToolCall _copyToolCallWithMergedProviderOptions(
  ToolCall toolCall,
  ProviderOptions extraProviderOptions,
) {
  if (extraProviderOptions.isEmpty) return toolCall;

  final merged = <String, Map<String, dynamic>>{
    ...toolCall.providerOptions,
  };

  for (final entry in extraProviderOptions.entries) {
    final existing = merged[entry.key];
    merged[entry.key] = {...?existing, ...entry.value};
  }

  return ToolCall(
    id: toolCall.id,
    callType: toolCall.callType,
    function: toolCall.function,
    providerOptions: merged,
  );
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
