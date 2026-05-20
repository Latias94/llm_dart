enum OpenAIBuiltInToolType {
  webSearch,
  fileSearch,
  computerUse,
  imageGeneration,
  mcp,
  codeInterpreter,
  localShell,
  shell,
  applyPatch,
  toolSearch,
  custom,
}

abstract interface class OpenAIBuiltInTool {
  OpenAIBuiltInToolType get type;

  Map<String, Object?> toJson();
}
