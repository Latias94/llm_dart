import 'openai_native_tools.dart';

final class OpenAIResponsesNativeToolContext {
  static const empty = OpenAIResponsesNativeToolContext();

  final bool hasLocalShell;
  final bool hasShell;
  final bool hasApplyPatch;

  const OpenAIResponsesNativeToolContext({
    this.hasLocalShell = false,
    this.hasShell = false,
    this.hasApplyPatch = false,
  });

  factory OpenAIResponsesNativeToolContext.fromBuiltInTools(
    List<OpenAIBuiltInTool>? builtInTools,
  ) {
    var hasLocalShell = false;
    var hasShell = false;
    var hasApplyPatch = false;

    for (final tool in builtInTools ?? const <OpenAIBuiltInTool>[]) {
      switch (tool) {
        case OpenAILocalShellTool():
          hasLocalShell = true;
        case OpenAIShellTool():
          hasShell = true;
        case OpenAIApplyPatchTool():
          hasApplyPatch = true;
        default:
          break;
      }
    }

    if (!hasLocalShell && !hasShell && !hasApplyPatch) {
      return empty;
    }

    return OpenAIResponsesNativeToolContext(
      hasLocalShell: hasLocalShell,
      hasShell: hasShell,
      hasApplyPatch: hasApplyPatch,
    );
  }
}
