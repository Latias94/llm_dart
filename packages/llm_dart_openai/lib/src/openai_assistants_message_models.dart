import 'openai_assistants_lifecycle_model_support.dart';
import 'openai_json_value.dart';

final class OpenAICreateThreadMessageRequest {
  final String role;
  final Object content;
  final List<Map<String, Object?>> attachments;
  final Map<String, String>? metadata;
  final Map<String, Object?> extra;

  const OpenAICreateThreadMessageRequest({
    this.role = 'user',
    required this.content,
    this.attachments = const [],
    this.metadata,
    this.extra = const {},
  });

  Map<String, Object?> toJson() {
    return {
      'role': role,
      'content': content,
      if (attachments.isNotEmpty)
        'attachments': openAIAssistantsCopyMapList(attachments),
      if (metadata != null) 'metadata': Map.unmodifiable(metadata!),
      ...extra,
    };
  }
}

final class OpenAIModifyThreadMessageRequest {
  final Map<String, String>? metadata;
  final Map<String, Object?> extra;

  const OpenAIModifyThreadMessageRequest({
    this.metadata,
    this.extra = const {},
  });

  Map<String, Object?> toJson() {
    return {
      if (metadata != null) 'metadata': Map.unmodifiable(metadata!),
      ...extra,
    };
  }
}

final class OpenAIListThreadMessagesQuery {
  final int? limit;
  final String? order;
  final String? after;
  final String? before;
  final String? runId;

  const OpenAIListThreadMessagesQuery({
    this.limit,
    this.order,
    this.after,
    this.before,
    this.runId,
  });

  Map<String, String> toQueryParameters() {
    return openAIAssistantsPaginationQueryParameters(
      limit: limit,
      order: order,
      after: after,
      before: before,
      limitParameterName: 'limit',
      limitErrorMessage: 'OpenAI thread message list limit must be >= 1.',
      extra: {
        if (runId != null && runId!.isNotEmpty) 'run_id': runId!,
      },
    );
  }
}

final class OpenAIThreadMessage {
  final String id;
  final String object;
  final DateTime createdAt;
  final String threadId;
  final String role;
  final List<Map<String, Object?>> content;
  final String? assistantId;
  final String? runId;
  final String? status;
  final DateTime? completedAt;
  final DateTime? incompleteAt;
  final Map<String, Object?>? incompleteDetails;
  final List<Map<String, Object?>> attachments;
  final Map<String, String>? metadata;
  final Map<String, Object?> json;

  OpenAIThreadMessage({
    required this.id,
    this.object = 'thread.message',
    required this.createdAt,
    required this.threadId,
    required this.role,
    this.content = const [],
    this.assistantId,
    this.runId,
    this.status,
    this.completedAt,
    this.incompleteAt,
    this.incompleteDetails,
    this.attachments = const [],
    this.metadata,
    Map<String, Object?>? json,
  }) : json = Map.unmodifiable(
          json ??
              {
                'id': id,
                'object': object,
                'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
                'thread_id': threadId,
                'role': role,
                'content': openAIAssistantsCopyMapList(content),
                if (assistantId != null) 'assistant_id': assistantId,
                if (runId != null) 'run_id': runId,
                if (status != null) 'status': status,
                if (completedAt != null)
                  'completed_at': completedAt.millisecondsSinceEpoch ~/ 1000,
                if (incompleteAt != null)
                  'incomplete_at': incompleteAt.millisecondsSinceEpoch ~/ 1000,
                if (incompleteDetails != null)
                  'incomplete_details': incompleteDetails,
                if (attachments.isNotEmpty)
                  'attachments': openAIAssistantsCopyMapList(attachments),
                if (metadata != null) 'metadata': metadata,
              },
        );

  factory OpenAIThreadMessage.fromJson(Map<String, Object?> json) {
    return OpenAIThreadMessage(
      id: openAIRequiredNonEmptyString(json['id'], path: 'thread_message.id'),
      object: openAIOptionalString(
            json['object'],
            path: 'thread_message.object',
          ) ??
          'thread.message',
      createdAt: openAIRequiredEpochSecondsDateTime(
        json['created_at'],
        path: 'thread_message.created_at',
      ),
      threadId: openAIRequiredNonEmptyString(
        json['thread_id'],
        path: 'thread_message.thread_id',
      ),
      role: openAIRequiredNonEmptyString(
        json['role'],
        path: 'thread_message.role',
      ),
      content: openAIAssistantsMapListFromJson(
        json['content'],
        path: 'thread_message.content',
      ),
      assistantId: openAIOptionalString(
        json['assistant_id'],
        path: 'thread_message.assistant_id',
      ),
      runId:
          openAIOptionalString(json['run_id'], path: 'thread_message.run_id'),
      status: openAIOptionalString(
        json['status'],
        path: 'thread_message.status',
      ),
      completedAt: openAIOptionalEpochSecondsDateTime(
        json['completed_at'],
        path: 'thread_message.completed_at',
      ),
      incompleteAt: openAIOptionalEpochSecondsDateTime(
        json['incomplete_at'],
        path: 'thread_message.incomplete_at',
      ),
      incompleteDetails: openAIOptionalMap(
        json['incomplete_details'],
        path: 'thread_message.incomplete_details',
      ),
      attachments: openAIAssistantsMapListFromJson(
        json['attachments'],
        path: 'thread_message.attachments',
      ),
      metadata: openAIOptionalStringMap(
        json['metadata'],
        path: 'thread_message.metadata',
      ),
      json: json,
    );
  }

  Map<String, Object?> toJson() => json;
}

final class OpenAIListThreadMessagesResponse {
  final String object;
  final List<OpenAIThreadMessage> data;
  final String? firstId;
  final String? lastId;
  final bool hasMore;

  const OpenAIListThreadMessagesResponse({
    this.object = 'list',
    required this.data,
    this.firstId,
    this.lastId,
    required this.hasMore,
  });

  factory OpenAIListThreadMessagesResponse.fromJson(
    Map<String, Object?> json,
  ) {
    return OpenAIListThreadMessagesResponse(
      object: openAIOptionalString(
            json['object'],
            path: 'thread_messages.object',
          ) ??
          'list',
      data: openAIRequiredList(json['data'], path: 'thread_messages.data')
          .asMap()
          .entries
          .map(
            (entry) => OpenAIThreadMessage.fromJson(
              openAIRequiredMap(
                entry.value,
                path: 'thread_messages.data[${entry.key}]',
              ),
            ),
          )
          .toList(growable: false),
      firstId: openAIOptionalString(
        json['first_id'],
        path: 'thread_messages.first_id',
      ),
      lastId: openAIOptionalString(
        json['last_id'],
        path: 'thread_messages.last_id',
      ),
      hasMore: openAIRequiredBool(
        json['has_more'],
        path: 'thread_messages.has_more',
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'object': object,
      'data': data.map((message) => message.toJson()).toList(growable: false),
      if (firstId != null) 'first_id': firstId,
      if (lastId != null) 'last_id': lastId,
      'has_more': hasMore,
    };
  }
}

final class OpenAIThreadMessageDeleteResult {
  final String id;
  final String object;
  final bool deleted;

  const OpenAIThreadMessageDeleteResult({
    required this.id,
    this.object = 'thread.message.deleted',
    required this.deleted,
  });

  factory OpenAIThreadMessageDeleteResult.fromJson(Map<String, Object?> json) {
    return OpenAIThreadMessageDeleteResult(
      id: openAIRequiredNonEmptyString(
        json['id'],
        path: 'thread_message_delete.id',
      ),
      object: openAIOptionalString(
            json['object'],
            path: 'thread_message_delete.object',
          ) ??
          'thread.message.deleted',
      deleted: openAIRequiredBool(
        json['deleted'],
        path: 'thread_message_delete.deleted',
      ),
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
