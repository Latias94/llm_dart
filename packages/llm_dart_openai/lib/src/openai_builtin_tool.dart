enum OpenAIBuiltInToolType {
  webSearch,
  fileSearch,
  computerUse,
  imageGeneration,
  mcp,
  codeInterpreter,
}

abstract interface class OpenAIBuiltInTool {
  OpenAIBuiltInToolType get type;

  Map<String, Object?> toJson();
}
