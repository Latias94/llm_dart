part of 'openai_assistant_support.dart';

final class _OpenAIAssistantSerializationSupport {
  static const _toolSupport = _OpenAIAssistantToolSupport();

  const _OpenAIAssistantSerializationSupport();

  Map<String, dynamic> getAssistantStats(Assistant assistant) {
    final metadata = assistant.metadata ?? {};

    return {
      'created_at': assistant.createdAt,
      'total_conversations':
          int.tryParse(metadata['total_conversations'] ?? '0') ?? 0,
      'total_messages': int.tryParse(metadata['total_messages'] ?? '0') ?? 0,
      'last_used': metadata['last_used'],
      'usage_count': int.tryParse(metadata['usage_count'] ?? '0') ?? 0,
      'average_response_time':
          double.tryParse(metadata['avg_response_time'] ?? '0') ?? 0.0,
    };
  }

  Map<String, dynamic> exportAssistant(Assistant assistant) {
    return {
      'name': assistant.name,
      'description': assistant.description,
      'model': assistant.model,
      'instructions': assistant.instructions,
      'tools': assistant.tools.map((tool) => tool.toJson()).toList(),
      'tool_resources': assistant.toolResources?.toJson(),
      'metadata': assistant.metadata,
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  CreateAssistantRequest buildImportRequest(Map<String, dynamic> config) {
    return CreateAssistantRequest(
      model: config['model'] as String,
      name: config['name'] as String?,
      description: config['description'] as String?,
      instructions: config['instructions'] as String?,
      tools: (config['tools'] as List?)
          ?.map(
            (tool) => _toolSupport.parseToolFromJson(
              tool as Map<String, dynamic>,
            ),
          )
          .toList(),
      toolResources: config['tool_resources'] != null
          ? ToolResources.fromJson(
              config['tool_resources'] as Map<String, dynamic>,
            )
          : null,
      metadata: {
        ...?(config['metadata'] as Map<String, String>?),
        'imported_at': DateTime.now().toIso8601String(),
      },
    );
  }
}
