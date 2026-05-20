import 'openai_assistants_lifecycle_model_support.dart';

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
      if (attachments.isNotEmpty)
        'attachments': openAIAssistantsCopyMapList(attachments),
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
