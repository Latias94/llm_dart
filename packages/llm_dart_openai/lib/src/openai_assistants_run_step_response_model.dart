import 'openai_json_value.dart';

final class OpenAIRunStep {
  final String id;
  final String object;
  final DateTime createdAt;
  final String runId;
  final String assistantId;
  final String threadId;
  final String type;
  final String status;
  final DateTime? cancelledAt;
  final DateTime? completedAt;
  final DateTime? expiredAt;
  final DateTime? failedAt;
  final Map<String, Object?>? lastError;
  final Map<String, Object?> stepDetails;
  final Map<String, Object?>? usage;
  final Map<String, String>? metadata;
  final Map<String, Object?> json;

  OpenAIRunStep({
    required this.id,
    this.object = 'thread.run.step',
    required this.createdAt,
    required this.runId,
    required this.assistantId,
    required this.threadId,
    required this.type,
    required this.status,
    this.cancelledAt,
    this.completedAt,
    this.expiredAt,
    this.failedAt,
    this.lastError,
    required this.stepDetails,
    this.usage,
    this.metadata,
    Map<String, Object?>? json,
  }) : json = Map.unmodifiable(
          json ??
              {
                'id': id,
                'object': object,
                'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
                'run_id': runId,
                'assistant_id': assistantId,
                'thread_id': threadId,
                'type': type,
                'status': status,
                if (cancelledAt != null)
                  'cancelled_at': cancelledAt.millisecondsSinceEpoch ~/ 1000,
                if (completedAt != null)
                  'completed_at': completedAt.millisecondsSinceEpoch ~/ 1000,
                if (expiredAt != null)
                  'expired_at': expiredAt.millisecondsSinceEpoch ~/ 1000,
                if (failedAt != null)
                  'failed_at': failedAt.millisecondsSinceEpoch ~/ 1000,
                if (lastError != null) 'last_error': lastError,
                'step_details': stepDetails,
                if (usage != null) 'usage': usage,
                if (metadata != null) 'metadata': metadata,
              },
        );

  factory OpenAIRunStep.fromJson(Map<String, Object?> json) {
    return OpenAIRunStep(
      id: openAIRequiredNonEmptyString(json['id'], path: 'run_step.id'),
      object: openAIOptionalString(json['object'], path: 'run_step.object') ??
          'thread.run.step',
      createdAt: openAIRequiredEpochSecondsDateTime(
        json['created_at'],
        path: 'run_step.created_at',
      ),
      runId: openAIRequiredNonEmptyString(
        json['run_id'],
        path: 'run_step.run_id',
      ),
      assistantId: openAIRequiredNonEmptyString(
        json['assistant_id'],
        path: 'run_step.assistant_id',
      ),
      threadId: openAIRequiredNonEmptyString(
        json['thread_id'],
        path: 'run_step.thread_id',
      ),
      type: openAIRequiredNonEmptyString(json['type'], path: 'run_step.type'),
      status: openAIRequiredNonEmptyString(
        json['status'],
        path: 'run_step.status',
      ),
      cancelledAt: openAIOptionalEpochSecondsDateTime(
        json['cancelled_at'],
        path: 'run_step.cancelled_at',
      ),
      completedAt: openAIOptionalEpochSecondsDateTime(
        json['completed_at'],
        path: 'run_step.completed_at',
      ),
      expiredAt: openAIOptionalEpochSecondsDateTime(
        json['expired_at'],
        path: 'run_step.expired_at',
      ),
      failedAt: openAIOptionalEpochSecondsDateTime(
        json['failed_at'],
        path: 'run_step.failed_at',
      ),
      lastError: openAIOptionalMap(
        json['last_error'],
        path: 'run_step.last_error',
      ),
      stepDetails: openAIRequiredMap(
        json['step_details'],
        path: 'run_step.step_details',
      ),
      usage: openAIOptionalMap(json['usage'], path: 'run_step.usage'),
      metadata: openAIOptionalStringMap(
        json['metadata'],
        path: 'run_step.metadata',
      ),
      json: json,
    );
  }

  Map<String, Object?> toJson() => json;
}
