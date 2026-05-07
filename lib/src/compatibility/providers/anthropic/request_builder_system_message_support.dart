part of 'request_builder.dart';

final class _AnthropicSystemMessageSupport {
  const _AnthropicSystemMessageSupport();

  static const _extensionSupport = _AnthropicMessageExtensionSupport();

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
