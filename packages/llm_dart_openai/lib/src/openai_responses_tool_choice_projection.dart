import 'package:llm_dart_provider/llm_dart_provider.dart';

final class OpenAIResponsesToolChoiceProjection {
  const OpenAIResponsesToolChoiceProjection();

  Map<String, Object?>? encode(
    ToolChoice? toolChoice, {
    required bool hasFunctionTools,
  }) {
    if (!hasFunctionTools || toolChoice == null) {
      return null;
    }

    return switch (toolChoice) {
      AutoToolChoice() => const {'type': 'auto'},
      RequiredToolChoice() => const {'type': 'required'},
      NoneToolChoice() => const {'type': 'none'},
      SpecificToolChoice(toolName: final toolName) => {
          'type': 'function',
          'function': {
            'name': toolName,
          },
        },
    };
  }
}
