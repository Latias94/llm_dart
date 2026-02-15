import 'package:llm_dart_core/llm_dart_core.dart';

dynamic convertToolChoiceToOpenAIParam(ToolChoice toolChoice) {
  return switch (toolChoice) {
    AutoToolChoice() => 'auto',
    NoneToolChoice() => 'none',
    AnyToolChoice() => 'required',
    SpecificToolChoice() => toolChoice.toJson(),
  };
}

/// Best-effort: inject OpenAI-style tool control fields into callOptions.body.
///
/// This is primarily useful for OpenAI-compatible providers (Chat Completions
/// and Responses APIs) that accept:
/// - `tool_choice` (`auto` / `none` / `required` / specific tool object), and
/// - `parallel_tool_calls` (bool).
LLMCallOptions applyOpenAIToolControlsToCallOptions(
  LLMCallOptions callOptions, {
  ToolChoice? toolChoice,
  bool? parallelToolCalls,
}) {
  if (toolChoice == null && parallelToolCalls == null) return callOptions;

  final body = <String, dynamic>{};
  if (toolChoice != null) {
    body['tool_choice'] = convertToolChoiceToOpenAIParam(toolChoice);
  }
  if (parallelToolCalls != null) {
    body['parallel_tool_calls'] = parallelToolCalls;
  }

  if (body.isEmpty) return callOptions;
  return callOptions.mergedWith(LLMCallOptions(body: body));
}
