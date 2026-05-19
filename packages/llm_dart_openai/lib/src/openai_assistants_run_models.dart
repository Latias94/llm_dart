import 'openai_assistants_lifecycle_model_support.dart';
import 'openai_assistants_message_models.dart';
import 'openai_assistants_models.dart';
import 'openai_assistants_thread_lifecycle_models.dart';
import 'openai_json_value.dart';

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
    return openAIAssistantsPaginationQueryParameters(
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
