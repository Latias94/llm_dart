import 'openai_builtin_tool.dart';

final class OpenAIFileSearchTool implements OpenAIBuiltInTool {
  final List<String>? vectorStoreIds;
  final Map<String, Object?>? parameters;

  const OpenAIFileSearchTool({
    this.vectorStoreIds,
    this.parameters,
  });

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.fileSearch;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'file_search',
      if (vectorStoreIds != null && vectorStoreIds!.isNotEmpty)
        'vector_store_ids': List<String>.unmodifiable(vectorStoreIds!),
      if (parameters != null) ...parameters!,
    };
  }
}
