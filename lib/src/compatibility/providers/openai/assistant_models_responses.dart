import 'assistant_models_entities.dart';

/// Response for listing assistants
class ListAssistantsResponse {
  /// The object type, which is always "list".
  final String object;

  /// The list of assistants.
  final List<Assistant> data;

  /// The identifier of the first assistant in the list.
  final String? firstId;

  /// The identifier of the last assistant in the list.
  final String? lastId;

  /// Whether there are more assistants available.
  final bool hasMore;

  const ListAssistantsResponse({
    this.object = 'list',
    required this.data,
    this.firstId,
    this.lastId,
    required this.hasMore,
  });

  factory ListAssistantsResponse.fromJson(Map<String, dynamic> json) {
    return ListAssistantsResponse(
      object: json['object'] as String? ?? 'list',
      data: (json['data'] as List)
          .map((item) => Assistant.fromJson(item as Map<String, dynamic>))
          .toList(),
      firstId: json['first_id'] as String?,
      lastId: json['last_id'] as String?,
      hasMore: json['has_more'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'object': object,
      'data': data.map((assistant) => assistant.toJson()).toList(),
      if (firstId != null) 'first_id': firstId,
      if (lastId != null) 'last_id': lastId,
      'has_more': hasMore,
    };
  }
}

/// Response for deleting an assistant
class DeleteAssistantResponse {
  /// The identifier of the deleted assistant.
  final String id;

  /// The object type, which is always "assistant.deleted".
  final String object;

  /// Whether the assistant was successfully deleted.
  final bool deleted;

  const DeleteAssistantResponse({
    required this.id,
    this.object = 'assistant.deleted',
    required this.deleted,
  });

  factory DeleteAssistantResponse.fromJson(Map<String, dynamic> json) {
    return DeleteAssistantResponse(
      id: json['id'] as String,
      object: json['object'] as String? ?? 'assistant.deleted',
      deleted: json['deleted'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'object': object, 'deleted': deleted};
  }
}

/// Query parameters for listing assistants
class ListAssistantsQuery {
  /// A limit on the number of objects to be returned.
  final int? limit;

  /// Sort order by the created_at timestamp of the objects.
  final String? order;

  /// A cursor for use in pagination.
  final String? after;

  /// A cursor for use in pagination.
  final String? before;

  const ListAssistantsQuery({this.limit, this.order, this.after, this.before});

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};

    if (limit != null) params['limit'] = limit;
    if (order != null) params['order'] = order;
    if (after != null) params['after'] = after;
    if (before != null) params['before'] = before;

    return params;
  }
}
