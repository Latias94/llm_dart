import '../../../../models/chat_models.dart';
import 'request_builder_message_extension_support.dart';
import 'request_builder_models.dart';

final class AnthropicSystemMessageSupport {
  const AnthropicSystemMessageSupport();

  static const _extensionSupport = AnthropicMessageExtensionSupport();

  SystemMessageResult process(ChatMessage message) {
    final extensionContent = _extensionSupport.extractContent(message);

    if (!extensionContent.hasExtension) {
      return SystemMessageResult(
        contentBlocks: const [],
        plainMessages: [message.content],
      );
    }

    final contentBlocks = <Map<String, dynamic>>[
      ...extensionContent.contentBlocks,
    ];

    if (message.content.isNotEmpty && extensionContent.cacheControl != null) {
      contentBlocks.add({
        'type': 'text',
        'text': message.content,
        'cache_control': extensionContent.cacheControl,
      });
    }

    return SystemMessageResult(
      contentBlocks: contentBlocks,
      plainMessages: const [],
      cacheControl: extensionContent.cacheControl,
    );
  }
}
