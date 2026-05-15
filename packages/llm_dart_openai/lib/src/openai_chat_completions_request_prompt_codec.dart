import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_chat_completions_request_tool_codec.dart';
import 'openai_options.dart';
import 'openai_request_encoding_util.dart';

final class OpenAIChatCompletionsPromptCodec {
  final String providerNamespace;
  final OpenAIChatCompletionsRequestToolCodec toolCodec;

  const OpenAIChatCompletionsPromptCodec({
    this.providerNamespace = 'openai',
    this.toolCodec = const OpenAIChatCompletionsRequestToolCodec(),
  });

  List<Map<String, Object?>> encodePromptMessage(
    PromptMessage message,
    List<ModelWarning> warnings, {
    required OpenAISystemMessageMode systemMessageMode,
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
        _encodeUserPromptMessage(message),
      ];
    }

    if (message is AssistantPromptMessage) {
      final textParts = <String>[];
      final encodedToolCalls = <Map<String, Object?>>[];

      for (final part in message.parts) {
        switch (part) {
          case TextPromptPart(:final text):
            textParts.add(text);
          case ToolCallPromptPart(
              :final toolCallId,
              :final toolName,
              :final input,
              :final providerExecuted,
              :final isDynamic,
            ):
            if (providerExecuted || isDynamic) {
              warnings.add(
                const ModelWarning(
                  type: ModelWarningType.unsupported,
                  field: 'prompt.assistant.parts',
                  message:
                      'Chat-completions replay drops provider-executed or dynamic assistant tool calls.',
                ),
              );
              continue;
            }

            encodedToolCalls.add({
              'id': toolCallId,
              'type': 'function',
              'function': {
                'name': toolName,
                'arguments': encodeOpenAIJsonString(input),
              },
            });
          case ReasoningPromptPart():
          case ReasoningFilePromptPart():
          case CustomPromptPart():
          case ToolApprovalRequestPromptPart():
          case ToolApprovalResponsePromptPart():
          case ImagePromptPart():
          case FilePromptPart():
          case ToolResultPromptPart():
            warnings.add(
              ModelWarning(
                type: ModelWarningType.unsupported,
                field: 'prompt.assistant.parts',
                message:
                    'Chat-completions replay dropped unsupported assistant part: ${part.runtimeType}.',
              ),
            );
        }
      }

      if (textParts.isEmpty && encodedToolCalls.isEmpty) {
        return const [];
      }

      final encodedText = textParts.join();
      return [
        {
          'role': 'assistant',
          'content': encodedText,
          if (encodedToolCalls.isNotEmpty) 'tool_calls': encodedToolCalls,
        },
      ];
    }

    if (message is ToolPromptMessage) {
      final encoded = <Map<String, Object?>>[];

      for (final part in message.parts) {
        switch (part) {
          case ToolResultPromptPart(
              :final toolCallId,
              :final toolName,
              :final toolOutput,
            ):
            if (toolName.startsWith('mcp.')) {
              warnings.add(
                const ModelWarning(
                  type: ModelWarningType.unsupported,
                  field: 'prompt.tool.parts',
                  message:
                      'Chat-completions replay drops provider-native MCP tool results.',
                ),
              );
              continue;
            }

            encoded.add({
              'role': 'tool',
              'tool_call_id': toolCallId,
              'content': toolCodec.encodeToolOutput(toolOutput),
            });
          case ToolApprovalResponsePromptPart():
            warnings.add(
              const ModelWarning(
                type: ModelWarningType.unsupported,
                field: 'prompt.tool.parts',
                message:
                    'Chat-completions replay does not support tool approval responses.',
              ),
            );
          case TextPromptPart():
          case ReasoningPromptPart():
          case ReasoningFilePromptPart():
          case CustomPromptPart():
          case ToolCallPromptPart():
          case ToolApprovalRequestPromptPart():
          case ImagePromptPart():
          case FilePromptPart():
            warnings.add(
              ModelWarning(
                type: ModelWarningType.unsupported,
                field: 'prompt.tool.parts',
                message:
                    'Chat-completions replay dropped unsupported tool prompt part: ${part.runtimeType}.',
              ),
            );
        }
      }

      return encoded;
    }

    throw UnsupportedError(
      'Unsupported prompt message type: ${message.runtimeType}.',
    );
  }

  Map<String, Object?> _encodeUserPromptMessage(UserPromptMessage message) {
    if (message.parts.every((part) => part is TextPromptPart)) {
      return {
        'role': 'user',
        'content': _joinTextParts(
          role: 'user',
          parts: message.parts,
        ),
      };
    }

    final content = <Map<String, Object?>>[];
    for (var index = 0; index < message.parts.length; index++) {
      final part = message.parts[index];
      switch (part) {
        case TextPromptPart(:final text):
          content.add({
            'type': 'text',
            'text': text,
          });
        case ImagePromptPart(
            :final mediaType,
            :final uri,
            :final bytes,
            :final providerOptions,
          ):
          content.add(
            _encodeImageContentPart(
              mediaType: mediaType,
              uri: uri,
              bytes: bytes,
              providerOptions: providerOptions,
            ),
          );
        case FilePromptPart():
          content.add(
            _encodeFileContentPart(
              part,
              index: index,
            ),
          );
        case ReasoningPromptPart():
        case ReasoningFilePromptPart():
        case CustomPromptPart():
        case ToolCallPromptPart():
        case ToolApprovalRequestPromptPart():
        case ToolResultPromptPart():
        case ToolApprovalResponsePromptPart():
          throw UnsupportedError(
            'Unsupported user prompt part for chat-completions requests: ${part.runtimeType}.',
          );
      }
    }

    return {
      'role': 'user',
      'content': content,
    };
  }

  Map<String, Object?> _encodeImageContentPart({
    required String mediaType,
    Uri? uri,
    List<int>? bytes,
    ProviderPromptPartOptions? providerOptions,
  }) {
    final imageDetail = resolveOpenAIImageDetail(
      providerOptions,
      path: 'image.providerOptions',
    );
    final imageUrl = uri?.toString() ??
        (bytes == null
            ? null
            : 'data:${normalizeOpenAIImageMediaTypeForDataUrl(mediaType)};base64,'
                '${base64Encode(bytes)}');
    if (imageUrl == null) {
      throw UnsupportedError(
        'User image prompt parts need either a URI or bytes.',
      );
    }

    return {
      'type': 'image_url',
      'image_url': {
        'url': imageUrl,
        if (imageDetail != null) 'detail': imageDetail,
      },
    };
  }

  Map<String, Object?> _encodeFileContentPart(
    FilePromptPart part, {
    required int index,
  }) {
    if (part.mediaType.startsWith('image/')) {
      return _encodeImageContentPart(
        mediaType: part.mediaType,
        uri: part.uri,
        bytes: part.bytes,
        providerOptions: part.providerOptions,
      );
    }

    if (part.mediaType.startsWith('audio/')) {
      if (part.uri != null) {
        throw UnsupportedError(
          'OpenAI-family chat-completions audio file prompt parts do not support URIs. Provide bytes instead.',
        );
      }

      final bytes = part.bytes;
      if (bytes == null) {
        throw UnsupportedError(
          'OpenAI-family chat-completions audio file prompt parts need bytes.',
        );
      }

      return {
        'type': 'input_audio',
        'input_audio': {
          'data': base64Encode(bytes),
          'format': _encodeAudioFormat(part.mediaType),
        },
      };
    }

    if (part.mediaType == 'application/pdf') {
      if (_openAIFileId(data: part.data) case final fileId?) {
        return {
          'type': 'file',
          'file': {
            'file_id': fileId,
          },
        };
      }

      if (part.uri != null) {
        throw UnsupportedError(
          'OpenAI-family chat-completions PDF file prompt parts do not support URIs. Provide bytes instead.',
        );
      }

      final bytes = part.bytes;
      if (bytes == null) {
        throw UnsupportedError(
          'OpenAI-family chat-completions PDF file prompt parts need bytes.',
        );
      }

      return {
        'type': 'file',
        'file': {
          'filename': part.filename ?? 'part-$index.pdf',
          'file_data': 'data:application/pdf;base64,${base64Encode(bytes)}',
        },
      };
    }

    throw UnsupportedError(
      'OpenAI-family chat-completions requests do not support file prompt media type ${part.mediaType}.',
    );
  }

  String _joinTextParts({
    required String role,
    required List<PromptPart> parts,
  }) {
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is! TextPromptPart) {
        throw UnsupportedError(
          'OpenAI-family chat-completions requests only support text $role prompt parts for now. Received ${part.runtimeType}.',
        );
      }

      if (buffer.isNotEmpty) {
        buffer.write('\n\n');
      }
      buffer.write(part.text);
    }

    return buffer.toString();
  }

  String _encodeAudioFormat(String mediaType) {
    return switch (mediaType) {
      'audio/wav' => 'wav',
      'audio/mpeg' => 'mp3',
      'audio/mp3' => 'mp3',
      _ => throw UnsupportedError(
          'OpenAI-family chat-completions requests do not support audio file media type $mediaType.',
        ),
    };
  }

  String? _openAIFileId({
    required FileData data,
  }) {
    return resolveOpenAIFileId(
      data: data,
      providerNamespace: providerNamespace,
      context: '$providerNamespace file prompt part',
    );
  }
}
