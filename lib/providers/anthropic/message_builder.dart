import '../../models/content_block.dart';

/// Anthropic cache control configuration
class AnthropicCacheControl {
  final String type;
  final AnthropicCacheTtl? ttl;

  const AnthropicCacheControl.ephemeral({this.ttl}) : type = 'ephemeral';

  Map<String, dynamic> toJson() => {
        'type': type,
        if (ttl != null) 'ttl': ttl!.seconds,
      };
}

/// Anthropic cache time-to-live options
enum AnthropicCacheTtl {
  fiveMinutes(300),
  oneHour(3600);

  const AnthropicCacheTtl(this.seconds);
  final int seconds;
}

/// Anthropic-specific text content block
class AnthropicTextBlock implements ContentBlock {
  final String text;
  final AnthropicCacheControl? cacheControl;

  const AnthropicTextBlock(this.text, {this.cacheControl});

  @override
  String get displayText => text;

  @override
  String get providerId => 'anthropic';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        'text': text,
        if (cacheControl != null) 'cache_control': cacheControl!.toJson(),
      };
}

/// Anthropic tool use content block
class AnthropicToolUseBlock implements ContentBlock {
  final String id;
  final String name;
  final Map<String, dynamic> input;

  const AnthropicToolUseBlock({
    required this.id,
    required this.name,
    required this.input,
  });

  @override
  String get displayText => '[Tool: $name]';

  @override
  String get providerId => 'anthropic';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tool_use',
        'id': id,
        'name': name,
        'input': input,
      };
}

/// Anthropic tool result content block
class AnthropicToolResultBlock implements ContentBlock {
  final String toolUseId;
  final String content;
  final bool isError;

  const AnthropicToolResultBlock({
    required this.toolUseId,
    required this.content,
    this.isError = false,
  });

  @override
  String get displayText => content;

  @override
  String get providerId => 'anthropic';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tool_result',
        'tool_use_id': toolUseId,
        'content': content,
        'is_error': isError,
      };
}

/// Anthropic-specific message builder for advanced content features
class AnthropicMessageBuilder {
  final void Function(ContentBlock) _addBlock;

  AnthropicMessageBuilder._(this._addBlock);

  /// Create an Anthropic message builder
  factory AnthropicMessageBuilder(void Function(ContentBlock) addBlock) =>
      AnthropicMessageBuilder._(addBlock);

  /// Add cached text with optional TTL
  AnthropicMessageBuilder cachedText(String text, {AnthropicCacheTtl? ttl}) {
    final cacheControl =
        ttl != null ? AnthropicCacheControl.ephemeral(ttl: ttl) : null;

    _addBlock(AnthropicTextBlock(text, cacheControl: cacheControl));
    return this;
  }

  /// Add tool use content
  AnthropicMessageBuilder toolUse({
    required String id,
    required String name,
    required Map<String, dynamic> input,
  }) {
    _addBlock(AnthropicToolUseBlock(
      id: id,
      name: name,
      input: input,
    ));
    return this;
  }

  /// Add tool result content
  AnthropicMessageBuilder toolResult({
    required String toolUseId,
    required String content,
    bool isError = false,
  }) {
    _addBlock(AnthropicToolResultBlock(
      toolUseId: toolUseId,
      content: content,
      isError: isError,
    ));
    return this;
  }

  /// Add content from raw content block data
  AnthropicMessageBuilder contentBlock(Map<String, dynamic> blockData) {
    final type = blockData['type'] as String;

    switch (type) {
      case 'text':
        final text = blockData['text'] as String;
        final cacheData = blockData['cache_control'] as Map<String, dynamic>?;
        AnthropicCacheTtl? ttl;

        if (cacheData != null) {
          final ttlSeconds = cacheData['ttl'] as int?;
          if (ttlSeconds != null) {
            ttl = AnthropicCacheTtl.values.firstWhere(
              (t) => t.seconds == ttlSeconds,
              orElse: () => AnthropicCacheTtl.fiveMinutes,
            );
          }
        }

        return cachedText(text, ttl: ttl);

      case 'tool_use':
        return toolUse(
          id: blockData['id'] as String,
          name: blockData['name'] as String,
          input: blockData['input'] as Map<String, dynamic>,
        );

      case 'tool_result':
        return toolResult(
          toolUseId: blockData['tool_use_id'] as String,
          content: blockData['content'] as String,
          isError: blockData['is_error'] as bool? ?? false,
        );

      default:
        // For unknown types, add as text block
        _addBlock(AnthropicTextBlock(blockData['text']?.toString() ?? ''));
        return this;
    }
  }

  /// Add multiple content blocks from raw data
  AnthropicMessageBuilder contentBlocks(List<Map<String, dynamic>> blocks) {
    for (final block in blocks) {
      contentBlock(block);
    }
    return this;
  }
}
