import '../../../../models/chat_models.dart';
import 'request_builder_message_content_support.dart';
import 'request_builder_models.dart';
import 'request_builder_system_message_support.dart';

ProcessedMessages processAnthropicMessages(List<ChatMessage> messages) {
  const systemSupport = AnthropicSystemMessageSupport();
  const contentSupport = AnthropicMessageContentSupport();

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
