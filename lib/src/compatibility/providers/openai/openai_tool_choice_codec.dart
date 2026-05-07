import '../../../../models/tool_models.dart';

/// OpenAI-compatible tool choice codec for Chat Completions and Responses
/// request payloads.
final class OpenAIToolChoiceCodec {
  const OpenAIToolChoiceCodec();

  Map<String, dynamic> toJson(ToolChoice toolChoice) {
    return switch (toolChoice) {
      AutoToolChoice() => {'type': 'auto'},
      AnyToolChoice() => {'type': 'required'},
      NoneToolChoice() => {'type': 'none'},
      SpecificToolChoice(toolName: final toolName) => {
          'type': 'function',
          'function': {'name': toolName},
        },
    };
  }
}
