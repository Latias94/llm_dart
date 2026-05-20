import 'openai_assistants_message_request_models.dart';
import 'openai_assistants_tool_resources_models.dart';

final class OpenAICreateThreadRequest {
  final List<OpenAICreateThreadMessageRequest> messages;
  final OpenAIAssistantToolResources? toolResources;
  final Map<String, String>? metadata;
  final Map<String, Object?> extra;

  const OpenAICreateThreadRequest({
    this.messages = const [],
    this.toolResources,
    this.metadata,
    this.extra = const {},
  });

  Map<String, Object?> toJson() {
    return {
      if (messages.isNotEmpty)
        'messages': messages.map((message) => message.toJson()).toList(),
      if (toolResources != null) 'tool_resources': toolResources!.toJson(),
      if (metadata != null) 'metadata': Map.unmodifiable(metadata!),
      ...extra,
    };
  }
}

final class OpenAIModifyThreadRequest {
  final OpenAIAssistantToolResources? toolResources;
  final Map<String, String>? metadata;
  final Map<String, Object?> extra;

  const OpenAIModifyThreadRequest({
    this.toolResources,
    this.metadata,
    this.extra = const {},
  });

  Map<String, Object?> toJson() {
    return {
      if (toolResources != null) 'tool_resources': toolResources!.toJson(),
      if (metadata != null) 'metadata': Map.unmodifiable(metadata!),
      ...extra,
    };
  }
}
