import 'openai_builtin_tool.dart';

final class OpenAIWebSearchTool implements OpenAIBuiltInTool {
  const OpenAIWebSearchTool();

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.webSearch;

  @override
  Map<String, Object?> toJson() {
    return const {
      'type': 'web_search_preview',
    };
  }
}
