import 'openai_assistants_lifecycle_model_support.dart';
import 'openai_json_value.dart';

final class OpenAIThreadRun {
  final String id;
  final String object;
  final DateTime createdAt;
  final String threadId;
  final String assistantId;
  final String status;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime? cancelledAt;
  final DateTime? failedAt;
  final DateTime? completedAt;
  final Map<String, Object?>? lastError;
  final Map<String, Object?>? requiredAction;
  final String? model;
  final String? instructions;
  final List<Map<String, Object?>> tools;
  final Map<String, Object?>? incompleteDetails;
  final Map<String, Object?>? usage;
  final Map<String, String>? metadata;
  final Map<String, Object?> json;

  OpenAIThreadRun({
    required this.id,
    this.object = 'thread.run',
    required this.createdAt,
    required this.threadId,
    required this.assistantId,
    required this.status,
    this.startedAt,
    this.expiresAt,
    this.cancelledAt,
    this.failedAt,
    this.completedAt,
    this.lastError,
    this.requiredAction,
    this.model,
    this.instructions,
    this.tools = const [],
    this.incompleteDetails,
    this.usage,
    this.metadata,
    Map<String, Object?>? json,
  }) : json = Map.unmodifiable(
          json ??
              {
                'id': id,
                'object': object,
                'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
                'thread_id': threadId,
                'assistant_id': assistantId,
                'status': status,
                if (startedAt != null)
                  'started_at': startedAt.millisecondsSinceEpoch ~/ 1000,
                if (expiresAt != null)
                  'expires_at': expiresAt.millisecondsSinceEpoch ~/ 1000,
                if (cancelledAt != null)
                  'cancelled_at': cancelledAt.millisecondsSinceEpoch ~/ 1000,
                if (failedAt != null)
                  'failed_at': failedAt.millisecondsSinceEpoch ~/ 1000,
                if (completedAt != null)
                  'completed_at': completedAt.millisecondsSinceEpoch ~/ 1000,
                if (lastError != null) 'last_error': lastError,
                if (requiredAction != null) 'required_action': requiredAction,
                if (model != null) 'model': model,
                if (instructions != null) 'instructions': instructions,
                if (tools.isNotEmpty)
                  'tools': openAIAssistantsCopyMapList(tools),
                if (incompleteDetails != null)
                  'incomplete_details': incompleteDetails,
                if (usage != null) 'usage': usage,
                if (metadata != null) 'metadata': metadata,
              },
        );

  factory OpenAIThreadRun.fromJson(Map<String, Object?> json) {
    return OpenAIThreadRun(
      id: openAIRequiredNonEmptyString(json['id'], path: 'thread_run.id'),
      object: openAIOptionalString(json['object'], path: 'thread_run.object') ??
          'thread.run',
      createdAt: openAIRequiredEpochSecondsDateTime(
        json['created_at'],
        path: 'thread_run.created_at',
      ),
      threadId: openAIRequiredNonEmptyString(
        json['thread_id'],
        path: 'thread_run.thread_id',
      ),
      assistantId: openAIRequiredNonEmptyString(
        json['assistant_id'],
        path: 'thread_run.assistant_id',
      ),
      status: openAIRequiredNonEmptyString(
        json['status'],
        path: 'thread_run.status',
      ),
      startedAt: openAIOptionalEpochSecondsDateTime(
        json['started_at'],
        path: 'thread_run.started_at',
      ),
      expiresAt: openAIOptionalEpochSecondsDateTime(
        json['expires_at'],
        path: 'thread_run.expires_at',
      ),
      cancelledAt: openAIOptionalEpochSecondsDateTime(
        json['cancelled_at'],
        path: 'thread_run.cancelled_at',
      ),
      failedAt: openAIOptionalEpochSecondsDateTime(
        json['failed_at'],
        path: 'thread_run.failed_at',
      ),
      completedAt: openAIOptionalEpochSecondsDateTime(
        json['completed_at'],
        path: 'thread_run.completed_at',
      ),
      lastError: openAIOptionalMap(
        json['last_error'],
        path: 'thread_run.last_error',
      ),
      requiredAction: openAIOptionalMap(
        json['required_action'],
        path: 'thread_run.required_action',
      ),
      model: openAIOptionalString(json['model'], path: 'thread_run.model'),
      instructions: openAIOptionalString(
        json['instructions'],
        path: 'thread_run.instructions',
      ),
      tools: openAIAssistantsMapListFromJson(
        json['tools'],
        path: 'thread_run.tools',
      ),
      incompleteDetails: openAIOptionalMap(
        json['incomplete_details'],
        path: 'thread_run.incomplete_details',
      ),
      usage: openAIOptionalMap(json['usage'], path: 'thread_run.usage'),
      metadata: openAIOptionalStringMap(
        json['metadata'],
        path: 'thread_run.metadata',
      ),
      json: json,
    );
  }

  Map<String, Object?> toJson() => json;
}
