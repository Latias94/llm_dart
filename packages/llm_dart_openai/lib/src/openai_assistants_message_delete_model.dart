import 'openai_json_value.dart';

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
