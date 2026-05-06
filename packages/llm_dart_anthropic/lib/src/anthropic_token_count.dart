import 'package:llm_dart_provider/llm_dart_provider.dart';

final class AnthropicTokenCountRequest {
  final List<PromptMessage> prompt;
  final List<FunctionToolDefinition> tools;
  final ToolChoice? toolChoice;
  final CallOptions callOptions;

  AnthropicTokenCountRequest({
    required List<PromptMessage> prompt,
    List<FunctionToolDefinition> tools = const [],
    this.toolChoice,
    this.callOptions = const CallOptions(),
  })  : prompt = List.unmodifiable(prompt),
        tools = List.unmodifiable(tools) {
    GenerateTextRequest(
      prompt: this.prompt,
      tools: this.tools,
      toolChoice: toolChoice,
    );
  }
}

final class AnthropicTokenCountResult {
  final int inputTokens;
  final List<ModelWarning> warnings;

  AnthropicTokenCountResult({
    required this.inputTokens,
    List<ModelWarning> warnings = const [],
  }) : warnings = List.unmodifiable(warnings);
}
