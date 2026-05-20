import 'openai_builtin_tool.dart';

final class OpenAIComputerUseTool implements OpenAIBuiltInTool {
  final int displayWidth;
  final int displayHeight;
  final String environment;
  final Map<String, Object?>? parameters;

  const OpenAIComputerUseTool({
    required this.displayWidth,
    required this.displayHeight,
    required this.environment,
    this.parameters,
  });

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.computerUse;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'computer_use_preview',
      'display_width': displayWidth,
      'display_height': displayHeight,
      'environment': environment,
      if (parameters != null) ...parameters!,
    };
  }
}
