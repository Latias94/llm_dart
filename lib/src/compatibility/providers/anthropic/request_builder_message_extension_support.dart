import '../../../../models/chat_models.dart';

final class AnthropicMessageExtensionSupport {
  const AnthropicMessageExtensionSupport();

  AnthropicMessageExtensionContent extractContent(ChatMessage message) {
    final anthropicData = message.getExtension<Map<String, dynamic>>(
      'anthropic',
    );
    if (anthropicData == null) {
      return const AnthropicMessageExtensionContent.absent();
    }

    final contentBlocks = <Map<String, dynamic>>[];
    Map<String, dynamic>? cacheControl;

    for (final block in _rawContentBlocks(anthropicData)) {
      if (isCacheMarker(block)) {
        cacheControl = block['cache_control'] as Map<String, dynamic>?;
        continue;
      }
      if (isToolsBlock(block)) {
        continue;
      }
      contentBlocks.add(block);
    }

    return AnthropicMessageExtensionContent.present(
      contentBlocks: contentBlocks,
      cacheControl: cacheControl,
    );
  }

  List<Map<String, dynamic>> rawContentBlocksFor(ChatMessage message) {
    final anthropicData = message.getExtension<Map<String, dynamic>>(
      'anthropic',
    );
    if (anthropicData == null) {
      return const [];
    }

    return _rawContentBlocks(anthropicData);
  }

  bool isCacheMarker(Map<String, dynamic> block) {
    return block['cache_control'] != null && block['text'] == '';
  }

  bool isToolsBlock(Map<String, dynamic> block) {
    return block['type'] == 'tools';
  }

  List<Map<String, dynamic>> _rawContentBlocks(
    Map<String, dynamic> anthropicData,
  ) {
    final blocks = anthropicData['contentBlocks'] as List<dynamic>?;
    if (blocks == null) {
      return const [];
    }

    return [
      for (final block in blocks)
        if (block is Map<String, dynamic>) block,
    ];
  }
}

final class AnthropicMessageExtensionContent {
  final bool hasExtension;
  final List<Map<String, dynamic>> contentBlocks;
  final Map<String, dynamic>? cacheControl;

  const AnthropicMessageExtensionContent.absent()
      : hasExtension = false,
        contentBlocks = const [],
        cacheControl = null;

  const AnthropicMessageExtensionContent.present({
    required this.contentBlocks,
    this.cacheControl,
  }) : hasExtension = true;
}
