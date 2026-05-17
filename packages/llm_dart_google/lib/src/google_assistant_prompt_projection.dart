import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_binary_part_encoder.dart';
import 'google_language_model_policy.dart';
import 'google_prompt_replay_metadata.dart';
import 'google_server_tool_replay.dart';

final class GoogleAssistantPromptProjection {
  final GoogleBinaryPartEncoder binaryEncoder;

  const GoogleAssistantPromptProjection({
    this.binaryEncoder = const GoogleBinaryPartEncoder(),
  });

  Map<String, Object?>? encodePart(
    PromptPart part, {
    required GoogleLanguageModelPolicy policy,
  }) {
    final providerMetadata = googlePromptPartProviderMetadata(part);
    final metadata = resolveGooglePromptPartMetadata(providerMetadata);

    if (part is TextPromptPart) {
      if (part.text.isEmpty) {
        return null;
      }

      return {
        'text': part.text,
        ...metadata.encodeThoughtFields(),
      };
    }

    if (part is ReasoningPromptPart) {
      if (part.text.isEmpty) {
        return null;
      }

      return {
        'text': part.text,
        ...metadata.encodeThoughtFields(forceThought: true),
      };
    }

    if (part is ReasoningFilePromptPart) {
      return binaryEncoder.encodeAssistantInlineDataPart(
        mediaType: part.mediaType,
        data: part.data,
        metadata: metadata,
        forceThought: true,
      );
    }

    if (part is FilePromptPart) {
      return binaryEncoder.encodeAssistantInlineDataPart(
        mediaType: part.mediaType,
        data: part.data,
        metadata: metadata,
      );
    }

    if (part is ToolCallPromptPart) {
      return {
        'functionCall': {
          if (shouldReplayGoogleFunctionCallId(
            policy,
            metadata.functionCallId,
          ))
            'id': metadata.functionCallId,
          'name': part.toolName,
          'args': normalizeJsonValue(part.input) ?? const <String, Object?>{},
        },
        ...metadata.encodeThoughtFields(),
      };
    }

    if (part is ToolApprovalRequestPromptPart) {
      return null;
    }

    if (part is CustomPromptPart) {
      if (part.kind == GoogleToolCallReplay.kind) {
        final replay = GoogleToolCallReplay.parseData(
          part.data,
          providerMetadata: providerMetadata,
        );
        return {
          'toolCall': replay.toToolCallJson(),
          ...metadata.encodeThoughtFields(),
        };
      }

      if (part.kind == GoogleToolResponseReplay.kind) {
        final replay = GoogleToolResponseReplay.parseData(
          part.data,
          providerMetadata: providerMetadata,
        );
        return {
          'toolResponse': replay.toToolResponseJson(),
          ...metadata.encodeThoughtFields(),
        };
      }

      return null;
    }

    throw UnsupportedError(
      'Google assistant prompt part ${part.runtimeType} is not supported yet.',
    );
  }
}
