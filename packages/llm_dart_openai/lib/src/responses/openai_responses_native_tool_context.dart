import '../tools/openai_native_tools.dart';

final class OpenAIResponsesNativeToolContext {
  static const empty = OpenAIResponsesNativeToolContext();

  final bool hasLocalShell;
  final bool hasShell;
  final bool hasApplyPatch;
  final Set<String> customToolNames;

  const OpenAIResponsesNativeToolContext({
    this.hasLocalShell = false,
    this.hasShell = false,
    this.hasApplyPatch = false,
    this.customToolNames = const {},
  });

  bool isCustomToolName(String toolName) => customToolNames.contains(toolName);

  factory OpenAIResponsesNativeToolContext.fromBuiltInTools(
    List<OpenAIBuiltInTool>? builtInTools,
  ) {
    var hasLocalShell = false;
    var hasShell = false;
    var hasApplyPatch = false;
    final customToolNames = <String>{};

    for (final tool in builtInTools ?? const <OpenAIBuiltInTool>[]) {
      switch (tool) {
        case OpenAILocalShellTool():
          hasLocalShell = true;
        case OpenAIShellTool():
          hasShell = true;
        case OpenAIApplyPatchTool():
          hasApplyPatch = true;
        case OpenAICustomTool(:final name):
          customToolNames.add(name);
        default:
          break;
      }
    }

    if (!hasLocalShell &&
        !hasShell &&
        !hasApplyPatch &&
        customToolNames.isEmpty) {
      return empty;
    }

    return OpenAIResponsesNativeToolContext(
      hasLocalShell: hasLocalShell,
      hasShell: hasShell,
      hasApplyPatch: hasApplyPatch,
      customToolNames: Set.unmodifiable(customToolNames),
    );
  }
}
