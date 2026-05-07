part of 'request_builder.dart';

ProcessedMessages _processAnthropicMessages(List<ChatMessage> messages) {
  const systemSupport = _AnthropicSystemMessageSupport();
  const contentSupport = _AnthropicMessageContentSupport();

  final anthropicMessages = <Map<String, dynamic>>[];
  final systemContentBlocks = <Map<String, dynamic>>[];
  final systemMessages = <String>[];

  for (final message in messages) {
    if (message.role == ChatRole.system) {
      final result = systemSupport.process(message);
      systemContentBlocks.addAll(result.contentBlocks);
      systemMessages.addAll(result.plainMessages);
    } else {
      anthropicMessages.add(contentSupport.convert(message));
    }
  }

  return ProcessedMessages(
    anthropicMessages: anthropicMessages,
    systemContentBlocks: systemContentBlocks,
    systemMessages: systemMessages,
  );
}
