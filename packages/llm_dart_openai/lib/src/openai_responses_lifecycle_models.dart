import 'openai_json_value.dart';

final class OpenAIRawResponse {
  final Map<String, Object?> json;

  OpenAIRawResponse(Map<String, Object?> json) : json = Map.unmodifiable(json);

  factory OpenAIRawResponse.fromJson(Map<String, Object?> json) {
    return OpenAIRawResponse(json);
  }

  String? get id => openAIOptionalString(json['id'], path: 'response.id');

  String? get status =>
      openAIOptionalString(json['status'], path: 'response.status');

  String? get model =>
      openAIOptionalString(json['model'], path: 'response.model');

  String? get outputText =>
      openAIOptionalString(
        json['output_text'],
        path: 'response.output_text',
      ) ??
      _extractOutputText(json);

  Object? operator [](String key) => json[key];

  Map<String, Object?> toJson() => json;
}

final class OpenAIResponseInputItemsList {
  final String object;
  final List<OpenAIResponseInputItem> data;
  final String? firstId;
  final String? lastId;
  final bool hasMore;

  const OpenAIResponseInputItemsList({
    this.object = 'list',
    required this.data,
    this.firstId,
    this.lastId,
    required this.hasMore,
  });

  factory OpenAIResponseInputItemsList.fromJson(Map<String, Object?> json) {
    return OpenAIResponseInputItemsList(
      object: openAIOptionalString(
            json['object'],
            path: 'input_items.object',
          ) ??
          'list',
      data: openAIRequiredList(json['data'], path: 'input_items.data')
          .asMap()
          .entries
          .map(
            (entry) => OpenAIResponseInputItem.fromJson(
              openAIRequiredMap(
                entry.value,
                path: 'input_items.data[${entry.key}]',
              ),
            ),
          )
          .toList(growable: false),
      firstId: openAIOptionalString(
        json['first_id'],
        path: 'input_items.first_id',
      ),
      lastId: openAIOptionalString(
        json['last_id'],
        path: 'input_items.last_id',
      ),
      hasMore: openAIRequiredBool(
        json['has_more'],
        path: 'input_items.has_more',
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'object': object,
      'data': data.map((item) => item.toJson()).toList(growable: false),
      if (firstId != null) 'first_id': firstId,
      if (lastId != null) 'last_id': lastId,
      'has_more': hasMore,
    };
  }
}

final class OpenAIResponseInputItem {
  final String id;
  final String type;
  final String? role;
  final List<Map<String, Object?>>? content;
  final Map<String, Object?> json;

  OpenAIResponseInputItem({
    required this.id,
    required this.type,
    this.role,
    this.content,
    Map<String, Object?>? json,
  }) : json = Map.unmodifiable(
          json ??
              {
                'id': id,
                'type': type,
                if (role != null) 'role': role,
                if (content != null) 'content': content,
              },
        );

  factory OpenAIResponseInputItem.fromJson(Map<String, Object?> json) {
    return OpenAIResponseInputItem(
      id: openAIRequiredNonEmptyString(json['id'], path: 'input_item.id'),
      type: openAIRequiredNonEmptyString(
        json['type'],
        path: 'input_item.type',
      ),
      role: openAIOptionalString(json['role'], path: 'input_item.role'),
      content: openAIOptionalList(json['content'], path: 'input_item.content')
          ?.asMap()
          .entries
          .map(
            (entry) => openAIRequiredMap(
              entry.value,
              path: 'input_item.content[${entry.key}]',
            ),
          )
          .toList(growable: false),
      json: json,
    );
  }

  Map<String, Object?> toJson() => json;
}

final class OpenAIResponseDeleteResult {
  final String id;
  final String object;
  final bool deleted;

  const OpenAIResponseDeleteResult({
    required this.id,
    this.object = 'response.deleted',
    required this.deleted,
  });

  factory OpenAIResponseDeleteResult.fromJson(Map<String, Object?> json) {
    return OpenAIResponseDeleteResult(
      id: openAIRequiredNonEmptyString(
        json['id'],
        path: 'response_delete.id',
      ),
      object: openAIOptionalString(
            json['object'],
            path: 'response_delete.object',
          ) ??
          'response.deleted',
      deleted: openAIRequiredBool(
        json['deleted'],
        path: 'response_delete.deleted',
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

String? _extractOutputText(Map<String, Object?> json) {
  final output = json['output'];
  if (output is! List) {
    return null;
  }

  for (final item in output) {
    final itemJson = openAIOptionalMap(item, path: 'response.output[]');
    if (itemJson == null || itemJson['type'] != 'message') {
      continue;
    }

    final content = itemJson['content'];
    if (content is! List) {
      continue;
    }

    for (final part in content) {
      final partJson = openAIOptionalMap(
        part,
        path: 'response.output[].content[]',
      );
      if (partJson == null || partJson['type'] != 'output_text') {
        continue;
      }

      final text = openAIOptionalString(
        partJson['text'],
        path: 'response.output[].content[].text',
      );
      if (text != null) {
        return text;
      }
    }
  }

  return null;
}
