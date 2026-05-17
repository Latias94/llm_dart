import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'ollama_chat_binary_part_encoder.dart';
import 'ollama_tool_codec.dart';

final class OllamaChatPromptProjectionCodec {
  final OllamaToolCodec toolCodec;

  const OllamaChatPromptProjectionCodec({
    this.toolCodec = const OllamaToolCodec(),
  });

  Future<List<Map<String, Object?>>> encodePrompt({
    required List<PromptMessage> prompt,
    required OllamaChatBinaryPartEncoder binaryEncoder,
    required List<ModelWarning> warnings,
  }) async {
    final messages = <Map<String, Object?>>[];
    for (final message in prompt) {
      messages.addAll(
        await encodePromptMessage(
          message,
          binaryEncoder: binaryEncoder,
          warnings: warnings,
        ),
      );
    }
    return messages;
  }

  Future<List<Map<String, Object?>>> encodePromptMessage(
    PromptMessage message, {
    required OllamaChatBinaryPartEncoder binaryEncoder,
    required List<ModelWarning> warnings,
  }) async {
    return switch (message) {
      SystemPromptMessage() => [
          {
            'role': 'system',
            'content': _collectTextParts(
              message.parts,
              messageRole: 'system',
              warnings: warnings,
            ),
          },
        ],
      UserPromptMessage() => [
          await _encodeUserMessage(
            message,
            binaryEncoder: binaryEncoder,
            warnings: warnings,
          ),
        ],
      AssistantPromptMessage() => [_encodeAssistantMessage(message)],
      ToolPromptMessage() => _encodeToolMessage(message, warnings: warnings),
    };
  }

  Future<Map<String, Object?>> _encodeUserMessage(
    UserPromptMessage message, {
    required OllamaChatBinaryPartEncoder binaryEncoder,
    required List<ModelWarning> warnings,
  }) async {
    final textParts = <String>[];
    final images = <String>[];

    for (final part in message.parts) {
      switch (part) {
        case TextPromptPart(:final text):
          textParts.add(text);
        case ImagePromptPart(
            :final mediaType,
            :final uri,
            :final bytes,
          ):
          images.add(
            await binaryEncoder.encodeBase64(
              mediaType: mediaType,
              uri: uri,
              bytes: bytes,
              promptPartKind: 'image',
            ),
          );
        case FilePromptPart(
              mediaType: final mediaType,
              filename: final filename,
              uri: final uri,
              bytes: final bytes,
            )
            when mediaType.startsWith('image/'):
          images.add(
            await binaryEncoder.encodeBase64(
              mediaType: mediaType,
              filename: filename,
              uri: uri,
              bytes: bytes,
              promptPartKind: 'image file',
            ),
          );
        case FilePromptPart():
          throw UnsupportedError(
            'Ollama only supports image multimodal file prompt parts on the current modern chat path.',
          );
        case ReasoningPromptPart(:final text):
          warnings.add(
            const ModelWarning(
              type: ModelWarningType.compatibility,
              field: 'prompt',
              message:
                  'Ollama does not have a dedicated user reasoning-input field. The reasoning text has been appended to the user content.',
            ),
          );
          textParts.add(text);
        default:
          throw UnsupportedError(
            'Ollama user prompt part ${part.runtimeType} is not supported yet.',
          );
      }
    }

    return {
      'role': 'user',
      'content': textParts.join('\n'),
      if (images.isNotEmpty) 'images': images,
    };
  }

  Map<String, Object?> _encodeAssistantMessage(AssistantPromptMessage message) {
    final textParts = <String>[];
    final reasoningParts = <String>[];
    final toolCalls = <Map<String, Object?>>[];

    for (final part in message.parts) {
      switch (part) {
        case TextPromptPart(:final text):
          textParts.add(text);
        case ReasoningPromptPart(:final text):
          reasoningParts.add(text);
        case ToolCallPromptPart(
            toolName: final toolName,
            input: final input,
          ):
          toolCalls.add(
            toolCodec.encodeAssistantToolCall(
              index: toolCalls.length,
              toolName: toolName,
              input: input,
            ),
          );
        default:
          throw UnsupportedError(
            'Ollama assistant prompt part ${part.runtimeType} is not supported yet.',
          );
      }
    }

    return {
      'role': 'assistant',
      'content': textParts.join('\n'),
      if (reasoningParts.isNotEmpty) 'thinking': reasoningParts.join('\n'),
      if (toolCalls.isNotEmpty) 'tool_calls': toolCalls,
    };
  }

  List<Map<String, Object?>> _encodeToolMessage(
    ToolPromptMessage message, {
    required List<ModelWarning> warnings,
  }) {
    final encodedMessages = <Map<String, Object?>>[];

    for (final part in message.parts) {
      switch (part) {
        case ToolResultPromptPart(
            toolName: final toolName,
            toolOutput: final toolOutput,
          ):
          if (toolOutput.isError) {
            _addWarningOnce(
              warnings,
              const ModelWarning(
                type: ModelWarningType.compatibility,
                field: 'prompt',
                message:
                    'Ollama does not support replaying tool error state separately. The tool result has been sent as a plain tool content message.',
              ),
            );
          }
          encodedMessages.add({
            'role': 'tool',
            'tool_name': toolName,
            'content': toolCodec.stringifyToolOutput(toolOutput),
          });
        default:
          throw UnsupportedError(
            'Ollama tool prompt part ${part.runtimeType} is not supported yet.',
          );
      }
    }

    return encodedMessages;
  }

  String _collectTextParts(
    List<PromptPart> parts, {
    required String messageRole,
    required List<ModelWarning> warnings,
  }) {
    final textParts = <String>[];

    for (final part in parts) {
      switch (part) {
        case TextPromptPart(:final text):
          textParts.add(text);
        case ReasoningPromptPart(:final text):
          warnings.add(
            ModelWarning(
              type: ModelWarningType.compatibility,
              field: 'prompt',
              message:
                  'Ollama does not support replaying $messageRole reasoning as a separate prompt field. The reasoning text has been appended to the message content.',
            ),
          );
          textParts.add(text);
        default:
          throw UnsupportedError(
            'Ollama $messageRole prompt part ${part.runtimeType} is not supported yet.',
          );
      }
    }

    return textParts.join('\n');
  }

  void _addWarningOnce(List<ModelWarning> warnings, ModelWarning warning) {
    if (warnings.contains(warning)) return;
    warnings.add(warning);
  }
}
