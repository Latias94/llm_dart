part of 'tool_models.dart';

/// Tool choice determines how the LLM uses available tools.
/// The behavior is standardized across different LLM providers.
///
/// **API References:**
/// - OpenAI: https://platform.openai.com/docs/guides/tools
/// - Anthropic: https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/overview
/// - xAI: https://docs.x.ai/docs/guides/function-calling
sealed class ToolChoice {
  const ToolChoice();

  Map<String, dynamic> toJson();

  /// Convert to OpenAI format
  Map<String, dynamic> toOpenAIJson() => toJson();

  /// Convert to Anthropic format
  String toAnthropicJson() {
    return switch (this) {
      AutoToolChoice() => 'auto',
      AnyToolChoice() => 'any',
      NoneToolChoice() => 'none',
      SpecificToolChoice(toolName: final name) =>
        '{"type": "tool", "name": "$name"}',
    };
  }

  /// Convert to xAI format (OpenAI-compatible)
  Map<String, dynamic> toXAIJson() => toOpenAIJson();
}

/// Model can use any tool, but it must use at least one.
/// This is useful when you want to force the model to use tools.
///
/// Maps to:
/// - OpenAI: `{"type": "required"}`
/// - Anthropic: `"any"` or `{"type": "any", "disable_parallel_tool_use": true}`
/// - xAI: `{"type": "required"}`
class AnyToolChoice extends ToolChoice {
  /// Whether to disable parallel tool use (Anthropic only)
  final bool? disableParallelToolUse;

  const AnyToolChoice({this.disableParallelToolUse});

  @override
  Map<String, dynamic> toJson() => {'type': 'required'};

  @override
  String toAnthropicJson() {
    if (disableParallelToolUse == true) {
      return '{"type": "any", "disable_parallel_tool_use": true}';
    }
    return 'any';
  }
}

/// Model can use any tool, and may elect to use none.
/// This is the default behavior and gives the model flexibility.
///
/// Maps to:
/// - OpenAI: `{"type": "auto"}`
/// - Anthropic: `"auto"` or `{"type": "auto", "disable_parallel_tool_use": true}`
/// - xAI: `{"type": "auto"}`
class AutoToolChoice extends ToolChoice {
  /// Whether to disable parallel tool use (Anthropic only)
  final bool? disableParallelToolUse;

  const AutoToolChoice({this.disableParallelToolUse});

  @override
  Map<String, dynamic> toJson() => {'type': 'auto'};

  @override
  String toAnthropicJson() {
    if (disableParallelToolUse == true) {
      return '{"type": "auto", "disable_parallel_tool_use": true}';
    }
    return 'auto';
  }
}

/// Model must use the specified tool and only the specified tool.
/// The string parameter is the name of the required tool.
/// This is useful when you want the model to call a specific function.
///
/// Maps to:
/// - OpenAI: `{"type": "function", "function": {"name": "tool_name"}}`
/// - Anthropic: `{"type": "tool", "name": "tool_name"}` or with disable_parallel_tool_use
/// - xAI: `{"type": "function", "function": {"name": "tool_name"}}`
class SpecificToolChoice extends ToolChoice {
  final String toolName;

  /// Whether to disable parallel tool use (Anthropic only)
  final bool? disableParallelToolUse;

  const SpecificToolChoice(this.toolName, {this.disableParallelToolUse});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'function',
        'function': {'name': toolName},
      };

  @override
  String toAnthropicJson() {
    if (disableParallelToolUse == true) {
      return '{"type": "tool", "name": "$toolName", "disable_parallel_tool_use": true}';
    }
    return '{"type": "tool", "name": "$toolName"}';
  }
}

/// Explicitly disables the use of tools.
/// The model will not use any tools even if they are provided.
///
/// Maps to:
/// - OpenAI: `{"type": "none"}`
/// - Anthropic: `"none"`
/// - xAI: `{"type": "none"}`
class NoneToolChoice extends ToolChoice {
  const NoneToolChoice();

  @override
  Map<String, dynamic> toJson() => {'type': 'none'};

  @override
  String toAnthropicJson() => 'none';
}
