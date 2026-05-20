import 'openai_assistants_tool_resources_models.dart';
import 'openai_json_value.dart';

final class OpenAIThread {
  final String id;
  final String object;
  final DateTime createdAt;
  final OpenAIAssistantToolResources? toolResources;
  final Map<String, String>? metadata;
  final Map<String, Object?> json;

  OpenAIThread({
    required this.id,
    this.object = 'thread',
    required this.createdAt,
    this.toolResources,
    this.metadata,
    Map<String, Object?>? json,
  }) : json = Map.unmodifiable(
          json ??
              {
                'id': id,
                'object': object,
                'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
                if (toolResources != null)
                  'tool_resources': toolResources.toJson(),
                if (metadata != null) 'metadata': metadata,
              },
        );

  factory OpenAIThread.fromJson(Map<String, Object?> json) {
    return OpenAIThread(
      id: openAIRequiredNonEmptyString(json['id'], path: 'thread.id'),
      object: openAIOptionalString(json['object'], path: 'thread.object') ??
          'thread',
      createdAt: openAIRequiredEpochSecondsDateTime(
        json['created_at'],
        path: 'thread.created_at',
      ),
      toolResources: json['tool_resources'] == null
          ? null
          : OpenAIAssistantToolResources.fromJson(
              openAIRequiredMap(
                json['tool_resources'],
                path: 'thread.tool_resources',
              ),
            ),
      metadata: openAIOptionalStringMap(
        json['metadata'],
        path: 'thread.metadata',
      ),
      json: json,
    );
  }

  Map<String, Object?> toJson() => json;
}
