import 'openai_assistants_lifecycle_model_support.dart';
import 'openai_assistants_run_step_response_model.dart';
import '../common/openai_json_value.dart';

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
    return openAIAssistantsPaginationQueryParameters(
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
