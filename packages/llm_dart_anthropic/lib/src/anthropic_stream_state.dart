import 'package:llm_dart_provider/llm_dart_provider.dart';

final class AnthropicMessagesStreamState {
  final Map<int, AnthropicStreamContentBlockState> contentBlocksByIndex = {};
  final Map<String, AnthropicStreamToolDescriptor> toolDescriptorsById = {};

  String? responseId;
  String? responseModelId;
  String? rawFinishReason;
  String? stopSequence;
  Map<String, Object?>? rawUsage;
  Map<String, Object?>? container;
  Map<String, Object?>? contextManagement;
  bool emittedResponseMetadata = false;
}

sealed class AnthropicStreamContentBlockState {
  ProviderMetadata? get providerMetadata;
}

final class AnthropicStreamTextBlockState
    extends AnthropicStreamContentBlockState {
  final String id;

  @override
  final ProviderMetadata? providerMetadata;

  AnthropicStreamTextBlockState({
    required this.id,
    this.providerMetadata,
  });
}

final class AnthropicStreamReasoningBlockState
    extends AnthropicStreamContentBlockState {
  final String id;

  @override
  final ProviderMetadata? providerMetadata;

  AnthropicStreamReasoningBlockState({
    required this.id,
    this.providerMetadata,
  });
}

final class AnthropicStreamToolBlockState
    extends AnthropicStreamContentBlockState {
  final String toolCallId;
  final String toolName;
  final bool providerExecuted;
  final bool isDynamic;
  final String? title;

  @override
  final ProviderMetadata? providerMetadata;

  final StringBuffer inputBuffer = StringBuffer();

  AnthropicStreamToolBlockState({
    required this.toolCallId,
    required this.toolName,
    required this.providerExecuted,
    required this.isDynamic,
    required this.title,
    required this.providerMetadata,
  });
}

final class AnthropicStreamToolDescriptor {
  final String toolName;
  final ProviderMetadata? providerMetadata;
  final bool providerExecuted;
  final bool isDynamic;
  final String? title;

  const AnthropicStreamToolDescriptor({
    required this.toolName,
    required this.providerMetadata,
    required this.providerExecuted,
    required this.isDynamic,
    required this.title,
  });
}
