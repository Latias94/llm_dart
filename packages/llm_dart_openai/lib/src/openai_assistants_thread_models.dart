import 'openai_assistants_models.dart';
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
      if (attachments.isNotEmpty) 'attachments': _copyMapList(attachments),
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
    return _paginationQueryParameters(
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
                'content': _copyMapList(content),
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
                  'attachments': _copyMapList(attachments),
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
      content: _mapListFromJson(
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
      attachments: _mapListFromJson(
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

final class OpenAICreateRunRequest {
  final String assistantId;
  final String? model;
  final String? instructions;
  final String? additionalInstructions;
  final List<OpenAICreateThreadMessageRequest> additionalMessages;
  final List<OpenAIAssistantTool>? tools;
  final Map<String, String>? metadata;
  final double? temperature;
  final double? topP;
  final OpenAIAssistantResponseFormat? responseFormat;
  final Object? toolChoice;
  final Map<String, Object?>? truncationStrategy;
  final int? maxPromptTokens;
  final int? maxCompletionTokens;
  final bool? parallelToolCalls;
  final Map<String, Object?> extra;

  const OpenAICreateRunRequest({
    required this.assistantId,
    this.model,
    this.instructions,
    this.additionalInstructions,
    this.additionalMessages = const [],
    this.tools,
    this.metadata,
    this.temperature,
    this.topP,
    this.responseFormat,
    this.toolChoice,
    this.truncationStrategy,
    this.maxPromptTokens,
    this.maxCompletionTokens,
    this.parallelToolCalls,
    this.extra = const {},
  });

  Map<String, Object?> toJson() {
    return {
      'assistant_id': assistantId,
      if (model != null) 'model': model,
      if (instructions != null) 'instructions': instructions,
      if (additionalInstructions != null)
        'additional_instructions': additionalInstructions,
      if (additionalMessages.isNotEmpty)
        'additional_messages':
            additionalMessages.map((message) => message.toJson()).toList(),
      if (tools != null)
        'tools': tools!.map((tool) => tool.toJson()).toList(growable: false),
      if (metadata != null) 'metadata': Map.unmodifiable(metadata!),
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'top_p': topP,
      if (responseFormat != null) 'response_format': responseFormat!.toJson(),
      if (toolChoice != null) 'tool_choice': toolChoice,
      if (truncationStrategy != null)
        'truncation_strategy': Map.unmodifiable(truncationStrategy!),
      if (maxPromptTokens != null) 'max_prompt_tokens': maxPromptTokens,
      if (maxCompletionTokens != null)
        'max_completion_tokens': maxCompletionTokens,
      if (parallelToolCalls != null) 'parallel_tool_calls': parallelToolCalls,
      ...extra,
    };
  }
}

final class OpenAIModifyRunRequest {
  final Map<String, String>? metadata;
  final Map<String, Object?> extra;

  const OpenAIModifyRunRequest({
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

final class OpenAICreateThreadAndRunRequest {
  final String assistantId;
  final OpenAICreateThreadRequest? thread;
  final String? model;
  final String? instructions;
  final List<OpenAIAssistantTool>? tools;
  final Map<String, String>? metadata;
  final double? temperature;
  final double? topP;
  final OpenAIAssistantResponseFormat? responseFormat;
  final Object? toolChoice;
  final Map<String, Object?>? truncationStrategy;
  final int? maxPromptTokens;
  final int? maxCompletionTokens;
  final bool? parallelToolCalls;
  final Map<String, Object?> extra;

  const OpenAICreateThreadAndRunRequest({
    required this.assistantId,
    this.thread,
    this.model,
    this.instructions,
    this.tools,
    this.metadata,
    this.temperature,
    this.topP,
    this.responseFormat,
    this.toolChoice,
    this.truncationStrategy,
    this.maxPromptTokens,
    this.maxCompletionTokens,
    this.parallelToolCalls,
    this.extra = const {},
  });

  Map<String, Object?> toJson() {
    return {
      'assistant_id': assistantId,
      if (thread != null) 'thread': thread!.toJson(),
      if (model != null) 'model': model,
      if (instructions != null) 'instructions': instructions,
      if (tools != null)
        'tools': tools!.map((tool) => tool.toJson()).toList(growable: false),
      if (metadata != null) 'metadata': Map.unmodifiable(metadata!),
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'top_p': topP,
      if (responseFormat != null) 'response_format': responseFormat!.toJson(),
      if (toolChoice != null) 'tool_choice': toolChoice,
      if (truncationStrategy != null)
        'truncation_strategy': Map.unmodifiable(truncationStrategy!),
      if (maxPromptTokens != null) 'max_prompt_tokens': maxPromptTokens,
      if (maxCompletionTokens != null)
        'max_completion_tokens': maxCompletionTokens,
      if (parallelToolCalls != null) 'parallel_tool_calls': parallelToolCalls,
      ...extra,
    };
  }
}

final class OpenAIRunToolOutput {
  final String toolCallId;
  final String output;
  final Map<String, Object?> extra;

  const OpenAIRunToolOutput({
    required this.toolCallId,
    required this.output,
    this.extra = const {},
  });

  Map<String, Object?> toJson() {
    return {
      'tool_call_id': toolCallId,
      'output': output,
      ...extra,
    };
  }
}

final class OpenAISubmitToolOutputsRequest {
  final List<OpenAIRunToolOutput> toolOutputs;
  final Map<String, Object?> extra;

  const OpenAISubmitToolOutputsRequest({
    required this.toolOutputs,
    this.extra = const {},
  });

  Map<String, Object?> toJson() {
    return {
      'tool_outputs':
          toolOutputs.map((output) => output.toJson()).toList(growable: false),
      ...extra,
    };
  }
}

final class OpenAIListRunsQuery {
  final int? limit;
  final String? order;
  final String? after;
  final String? before;

  const OpenAIListRunsQuery({
    this.limit,
    this.order,
    this.after,
    this.before,
  });

  Map<String, String> toQueryParameters() {
    return _paginationQueryParameters(
      limit: limit,
      order: order,
      after: after,
      before: before,
      limitParameterName: 'limit',
      limitErrorMessage: 'OpenAI run list limit must be >= 1.',
    );
  }
}

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
                if (tools.isNotEmpty) 'tools': _copyMapList(tools),
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
      tools: _mapListFromJson(json['tools'], path: 'thread_run.tools'),
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

final class OpenAIListRunsResponse {
  final String object;
  final List<OpenAIThreadRun> data;
  final String? firstId;
  final String? lastId;
  final bool hasMore;

  const OpenAIListRunsResponse({
    this.object = 'list',
    required this.data,
    this.firstId,
    this.lastId,
    required this.hasMore,
  });

  factory OpenAIListRunsResponse.fromJson(Map<String, Object?> json) {
    return OpenAIListRunsResponse(
      object:
          openAIOptionalString(json['object'], path: 'thread_runs.object') ??
              'list',
      data: openAIRequiredList(json['data'], path: 'thread_runs.data')
          .asMap()
          .entries
          .map(
            (entry) => OpenAIThreadRun.fromJson(
              openAIRequiredMap(
                entry.value,
                path: 'thread_runs.data[${entry.key}]',
              ),
            ),
          )
          .toList(growable: false),
      firstId:
          openAIOptionalString(json['first_id'], path: 'thread_runs.first_id'),
      lastId:
          openAIOptionalString(json['last_id'], path: 'thread_runs.last_id'),
      hasMore:
          openAIRequiredBool(json['has_more'], path: 'thread_runs.has_more'),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'object': object,
      'data': data.map((run) => run.toJson()).toList(growable: false),
      if (firstId != null) 'first_id': firstId,
      if (lastId != null) 'last_id': lastId,
      'has_more': hasMore,
    };
  }
}

final class OpenAIListRunStepsQuery {
  final int? limit;
  final String? order;
  final String? after;
  final String? before;
  final List<String>? include;

  const OpenAIListRunStepsQuery({
    this.limit,
    this.order,
    this.after,
    this.before,
    this.include,
  });

  Map<String, String> toQueryParameters() {
    return _paginationQueryParameters(
      limit: limit,
      order: order,
      after: after,
      before: before,
      limitParameterName: 'limit',
      limitErrorMessage: 'OpenAI run step list limit must be >= 1.',
      extra: {
        if (include != null && include!.isNotEmpty)
          'include': include!.join(','),
      },
    );
  }
}

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

final class OpenAIListRunStepsResponse {
  final String object;
  final List<OpenAIRunStep> data;
  final String? firstId;
  final String? lastId;
  final bool hasMore;

  const OpenAIListRunStepsResponse({
    this.object = 'list',
    required this.data,
    this.firstId,
    this.lastId,
    required this.hasMore,
  });

  factory OpenAIListRunStepsResponse.fromJson(Map<String, Object?> json) {
    return OpenAIListRunStepsResponse(
      object: openAIOptionalString(json['object'], path: 'run_steps.object') ??
          'list',
      data: openAIRequiredList(json['data'], path: 'run_steps.data')
          .asMap()
          .entries
          .map(
            (entry) => OpenAIRunStep.fromJson(
              openAIRequiredMap(
                entry.value,
                path: 'run_steps.data[${entry.key}]',
              ),
            ),
          )
          .toList(growable: false),
      firstId:
          openAIOptionalString(json['first_id'], path: 'run_steps.first_id'),
      lastId: openAIOptionalString(json['last_id'], path: 'run_steps.last_id'),
      hasMore: openAIRequiredBool(json['has_more'], path: 'run_steps.has_more'),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'object': object,
      'data': data.map((step) => step.toJson()).toList(growable: false),
      if (firstId != null) 'first_id': firstId,
      if (lastId != null) 'last_id': lastId,
      'has_more': hasMore,
    };
  }
}

Map<String, String> _paginationQueryParameters({
  int? limit,
  String? order,
  String? after,
  String? before,
  required String limitParameterName,
  required String limitErrorMessage,
  Map<String, String> extra = const {},
}) {
  if (limit != null && limit < 1) {
    throw ArgumentError.value(limit, limitParameterName, limitErrorMessage);
  }

  return {
    if (limit != null) 'limit': '$limit',
    if (order != null && order.isNotEmpty) 'order': order,
    if (after != null && after.isNotEmpty) 'after': after,
    if (before != null && before.isNotEmpty) 'before': before,
    ...extra,
  };
}

List<Map<String, Object?>> _mapListFromJson(
  Object? value, {
  required String path,
}) {
  final list = openAIOptionalList(value, path: path);
  if (list == null) {
    return const [];
  }
  return list
      .asMap()
      .entries
      .map(
        (entry) => openAIRequiredMap(
          entry.value,
          path: '$path[${entry.key}]',
        ),
      )
      .toList(growable: false);
}

List<Map<String, Object?>> _copyMapList(List<Map<String, Object?>> items) {
  return items.map((item) => Map<String, Object?>.unmodifiable(item)).toList(
        growable: false,
      );
}
