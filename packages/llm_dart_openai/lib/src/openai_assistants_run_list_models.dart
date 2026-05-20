import 'openai_assistants_lifecycle_model_support.dart';
import 'openai_assistants_run_response_model.dart';
import 'openai_json_value.dart';

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
