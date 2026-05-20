import 'openai_assistants_lifecycle_model_support.dart';
import 'openai_assistants_message_response_model.dart';
import '../common/openai_json_value.dart';

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
