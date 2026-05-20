import 'openai_json_value.dart';

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
