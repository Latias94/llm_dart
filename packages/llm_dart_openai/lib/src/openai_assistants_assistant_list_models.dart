import 'openai_assistants_assistant_model.dart';
import 'openai_assistants_lifecycle_model_support.dart';
import 'openai_json_value.dart';

final class OpenAIListAssistantsQuery {
  final int? limit;
  final String? order;
  final String? after;
  final String? before;

  const OpenAIListAssistantsQuery({
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
      limitErrorMessage: 'OpenAI assistant list limit must be >= 1.',
    );
  }
}

final class OpenAIListAssistantsResponse {
  final String object;
  final List<OpenAIAssistant> data;
  final String? firstId;
  final String? lastId;
  final bool hasMore;

  const OpenAIListAssistantsResponse({
    this.object = 'list',
    required this.data,
    this.firstId,
    this.lastId,
    required this.hasMore,
  });

  factory OpenAIListAssistantsResponse.fromJson(Map<String, Object?> json) {
    return OpenAIListAssistantsResponse(
      object: openAIOptionalString(json['object'], path: 'assistants.object') ??
          'list',
      data: openAIRequiredList(json['data'], path: 'assistants.data')
          .asMap()
          .entries
          .map(
            (entry) => OpenAIAssistant.fromJson(
              openAIRequiredMap(
                entry.value,
                path: 'assistants.data[${entry.key}]',
              ),
            ),
          )
          .toList(growable: false),
      firstId:
          openAIOptionalString(json['first_id'], path: 'assistants.first_id'),
      lastId: openAIOptionalString(json['last_id'], path: 'assistants.last_id'),
      hasMore:
          openAIRequiredBool(json['has_more'], path: 'assistants.has_more'),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'object': object,
      'data': data.map((assistant) => assistant.toJson()).toList(),
      if (firstId != null) 'first_id': firstId,
      if (lastId != null) 'last_id': lastId,
      'has_more': hasMore,
    };
  }
}

final class OpenAIDeleteAssistantResponse {
  final String id;
  final String object;
  final bool deleted;

  const OpenAIDeleteAssistantResponse({
    required this.id,
    this.object = 'assistant.deleted',
    required this.deleted,
  });

  factory OpenAIDeleteAssistantResponse.fromJson(Map<String, Object?> json) {
    return OpenAIDeleteAssistantResponse(
      id: openAIRequiredNonEmptyString(json['id'], path: 'assistant_delete.id'),
      object: openAIOptionalString(
            json['object'],
            path: 'assistant_delete.object',
          ) ??
          'assistant.deleted',
      deleted:
          openAIRequiredBool(json['deleted'], path: 'assistant_delete.deleted'),
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
