import 'openai_assistants_message_request_models.dart';
import 'openai_assistants_response_format_models.dart';
import 'openai_assistants_thread_lifecycle_models.dart';
import 'openai_assistants_tool_models.dart';

final class OpenAICreateRunRequest {
  final String assistantId;
  final String? model;
  final String? instructions;
  final String? additionalInstructions;
  final List<OpenAICreateThreadMessageRequest> additionalMessages;
  final List<OpenAIAssistantTool>? tools;
  final Map<String, String>? metadata;
  final double? temperature;
  final double? topP;
  final OpenAIAssistantResponseFormat? responseFormat;
  final Object? toolChoice;
  final Map<String, Object?>? truncationStrategy;
  final int? maxPromptTokens;
  final int? maxCompletionTokens;
  final bool? parallelToolCalls;
  final Map<String, Object?> extra;

  const OpenAICreateRunRequest({
    required this.assistantId,
    this.model,
    this.instructions,
    this.additionalInstructions,
    this.additionalMessages = const [],
    this.tools,
    this.metadata,
    this.temperature,
    this.topP,
    this.responseFormat,
    this.toolChoice,
    this.truncationStrategy,
    this.maxPromptTokens,
    this.maxCompletionTokens,
    this.parallelToolCalls,
    this.extra = const {},
  });

  Map<String, Object?> toJson() {
    return {
      'assistant_id': assistantId,
      if (model != null) 'model': model,
      if (instructions != null) 'instructions': instructions,
      if (additionalInstructions != null)
        'additional_instructions': additionalInstructions,
      if (additionalMessages.isNotEmpty)
        'additional_messages':
            additionalMessages.map((message) => message.toJson()).toList(),
      if (tools != null)
        'tools': tools!.map((tool) => tool.toJson()).toList(growable: false),
      if (metadata != null) 'metadata': Map.unmodifiable(metadata!),
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'top_p': topP,
      if (responseFormat != null) 'response_format': responseFormat!.toJson(),
      if (toolChoice != null) 'tool_choice': toolChoice,
      if (truncationStrategy != null)
        'truncation_strategy': Map.unmodifiable(truncationStrategy!),
      if (maxPromptTokens != null) 'max_prompt_tokens': maxPromptTokens,
      if (maxCompletionTokens != null)
        'max_completion_tokens': maxCompletionTokens,
      if (parallelToolCalls != null) 'parallel_tool_calls': parallelToolCalls,
      ...extra,
    };
  }
}

final class OpenAIModifyRunRequest {
  final Map<String, String>? metadata;
  final Map<String, Object?> extra;

  const OpenAIModifyRunRequest({
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

final class OpenAICreateThreadAndRunRequest {
  final String assistantId;
  final OpenAICreateThreadRequest? thread;
  final String? model;
  final String? instructions;
  final List<OpenAIAssistantTool>? tools;
  final Map<String, String>? metadata;
  final double? temperature;
  final double? topP;
  final OpenAIAssistantResponseFormat? responseFormat;
  final Object? toolChoice;
  final Map<String, Object?>? truncationStrategy;
  final int? maxPromptTokens;
  final int? maxCompletionTokens;
  final bool? parallelToolCalls;
  final Map<String, Object?> extra;

  const OpenAICreateThreadAndRunRequest({
    required this.assistantId,
    this.thread,
    this.model,
    this.instructions,
    this.tools,
    this.metadata,
    this.temperature,
    this.topP,
    this.responseFormat,
    this.toolChoice,
    this.truncationStrategy,
    this.maxPromptTokens,
    this.maxCompletionTokens,
    this.parallelToolCalls,
    this.extra = const {},
  });

  Map<String, Object?> toJson() {
    return {
      'assistant_id': assistantId,
      if (thread != null) 'thread': thread!.toJson(),
      if (model != null) 'model': model,
      if (instructions != null) 'instructions': instructions,
      if (tools != null)
        'tools': tools!.map((tool) => tool.toJson()).toList(growable: false),
      if (metadata != null) 'metadata': Map.unmodifiable(metadata!),
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'top_p': topP,
      if (responseFormat != null) 'response_format': responseFormat!.toJson(),
      if (toolChoice != null) 'tool_choice': toolChoice,
      if (truncationStrategy != null)
        'truncation_strategy': Map.unmodifiable(truncationStrategy!),
      if (maxPromptTokens != null) 'max_prompt_tokens': maxPromptTokens,
      if (maxCompletionTokens != null)
        'max_completion_tokens': maxCompletionTokens,
      if (parallelToolCalls != null) 'parallel_tool_calls': parallelToolCalls,
      ...extra,
    };
  }
}

final class OpenAIRunToolOutput {
  final String toolCallId;
  final String output;
  final Map<String, Object?> extra;

  const OpenAIRunToolOutput({
    required this.toolCallId,
    required this.output,
    this.extra = const {},
  });

  Map<String, Object?> toJson() {
    return {
      'tool_call_id': toolCallId,
      'output': output,
      ...extra,
    };
  }
}

final class OpenAISubmitToolOutputsRequest {
  final List<OpenAIRunToolOutput> toolOutputs;
  final Map<String, Object?> extra;

  const OpenAISubmitToolOutputsRequest({
    required this.toolOutputs,
    this.extra = const {},
  });

  Map<String, Object?> toJson() {
    return {
      'tool_outputs':
          toolOutputs.map((output) => output.toJson()).toList(growable: false),
      ...extra,
    };
  }
}
