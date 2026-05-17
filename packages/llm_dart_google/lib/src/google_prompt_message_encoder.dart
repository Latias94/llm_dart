import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_assistant_prompt_projection.dart';
import 'google_language_model_policy.dart';
import 'google_tool_prompt_projection.dart';
import 'google_user_prompt_projection.dart';

final class GooglePromptMessageEncoder {
  final GoogleUserPromptProjection userProjection;
  final GoogleAssistantPromptProjection assistantProjection;
  final GoogleToolPromptProjection toolProjection;

  const GooglePromptMessageEncoder({
    this.userProjection = const GoogleUserPromptProjection(),
    this.assistantProjection = const GoogleAssistantPromptProjection(),
    this.toolProjection = const GoogleToolPromptProjection(),
  });

  Map<String, Object?>? encodeMessage(
    PromptMessage message, {
    required String modelId,
  }) {
    final policy = GoogleLanguageModelPolicy(modelId);
    if (message case UserPromptMessage(:final parts)) {
      return {
        'role': 'user',
        'parts': [
          for (final part in parts) userProjection.encodePart(part),
        ],
      };
    }

    if (message case AssistantPromptMessage(:final parts)) {
      final encodedParts = [
        for (final part in parts)
          if (assistantProjection.encodePart(
            part,
            policy: policy,
          )
              case final encodedPart?)
            encodedPart,
      ];
      if (encodedParts.isEmpty) {
        return null;
      }

      return {
        'role': 'model',
        'parts': encodedParts,
      };
    }

    if (message case ToolPromptMessage(:final parts)) {
      final encodedParts = [
        for (final part in parts)
          if (toolProjection.encodePart(
            part,
            policy: policy,
          )
              case final encodedPart?)
            encodedPart,
      ];
      if (encodedParts.isEmpty) {
        return null;
      }

      return {
        'role': 'user',
        'parts': encodedParts,
      };
    }

    throw UnsupportedError(
      'Unsupported Google prompt message type: ${message.runtimeType}.',
    );
  }
}
