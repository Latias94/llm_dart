import 'package:llm_dart_provider/llm_dart_provider.dart';

final class AnthropicProjectedToolCall {
  final String toolCallId;
  final String toolName;
  final Object? input;
  final String encodedInput;
  final bool providerExecuted;
  final bool isDynamic;
  final String? title;
  final ProviderMetadata? providerMetadata;

  const AnthropicProjectedToolCall({
    required this.toolCallId,
    required this.toolName,
    required this.input,
    required this.encodedInput,
    this.providerExecuted = false,
    this.isDynamic = false,
    this.title,
    this.providerMetadata,
  });
}

final class AnthropicFinishedToolInputProjection {
  final AnthropicProjectedToolCall? toolCall;
  final ToolInputErrorEvent? errorEvent;

  const AnthropicFinishedToolInputProjection.toolCall(
    AnthropicProjectedToolCall projectedToolCall,
  )   : toolCall = projectedToolCall,
        errorEvent = null;

  const AnthropicFinishedToolInputProjection.error(
    ToolInputErrorEvent projectedError,
  )   : toolCall = null,
        errorEvent = projectedError;

  bool get hasToolCall => toolCall != null;
}
