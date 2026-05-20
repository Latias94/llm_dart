import 'openai_assistants_message_request_models.dart';
import 'openai_assistants_tool_resources_models.dart';
import 'openai_json_value.dart';

final class OpenAICreateThreadRequest {
  final List<OpenAICreateThreadMessageRequest> messages;
  final OpenAIAssistantToolResources? toolResources;
  final Map<String, String>? metadata;
  final Map<String, Object?> extra;

  const OpenAICreateThreadRequest({
    this.messages = const [],
    this.toolResources,
    this.metadata,
    this.extra = const {},
  });

  Map<String, Object?> toJson() {
    return {
      if (messages.isNotEmpty)
        'messages': messages.map((message) => message.toJson()).toList(),
      if (toolResources != null) 'tool_resources': toolResources!.toJson(),
      if (metadata != null) 'metadata': Map.unmodifiable(metadata!),
      ...extra,
    };
  }
}

final class OpenAIModifyThreadRequest {
  final OpenAIAssistantToolResources? toolResources;
  final Map<String, String>? metadata;
  final Map<String, Object?> extra;

  const OpenAIModifyThreadRequest({
    this.toolResources,
    this.metadata,
    this.extra = const {},
  });

  Map<String, Object?> toJson() {
    return {
      if (toolResources != null) 'tool_resources': toolResources!.toJson(),
      if (metadata != null) 'metadata': Map.unmodifiable(metadata!),
      ...extra,
    };
  }
}

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

final class OpenAIThreadDeleteResult {
  final String id;
  final String object;
  final bool deleted;

  const OpenAIThreadDeleteResult({
    required this.id,
    this.object = 'thread.deleted',
    required this.deleted,
  });

  factory OpenAIThreadDeleteResult.fromJson(Map<String, Object?> json) {
    return OpenAIThreadDeleteResult(
      id: openAIRequiredNonEmptyString(json['id'], path: 'thread_delete.id'),
      object:
          openAIOptionalString(json['object'], path: 'thread_delete.object') ??
              'thread.deleted',
      deleted:
          openAIRequiredBool(json['deleted'], path: 'thread_delete.deleted'),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'object': object,
      'deleted': deleted,
    };
  }
}
