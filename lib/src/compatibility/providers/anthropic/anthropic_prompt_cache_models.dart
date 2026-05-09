import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';

/// Anthropic-specific text block with caching support
class AnthropicTextBlock implements ContentBlock {
  final AnthropicCacheControl? cacheControl;
  String? _text;

  AnthropicTextBlock({this.cacheControl, String? text}) : _text = text;

  /// Set the text content for this block
  void setText(String text) {
    _text = text;
  }

  @override
  String get displayText => _text ?? '';

  @override
  String get providerId => 'anthropic';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        'text': _text ?? '',
        if (cacheControl != null) 'cache_control': cacheControl!.toJson(),
      };
}

/// Anthropic-specific tools block that can be cached
class AnthropicToolsBlock implements ContentBlock {
  final List<Tool> tools;

  AnthropicToolsBlock(this.tools);

  @override
  String get displayText => '[${tools.length} tools defined]';

  @override
  String get providerId => 'anthropic';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tools',
        'tools': tools.map((tool) => tool.toJson()).toList(),
      };
}

/// Anthropic message builder for provider-specific features
class AnthropicMessageBuilder {
  final MessageBuilder _builder;
  bool _cacheEnabled = false;
  AnthropicCacheTtl? _cacheTtl;

  AnthropicMessageBuilder._(this._builder);

  /// Enable caching for ALL text content in this message
  AnthropicMessageBuilder cache({AnthropicCacheTtl? ttl}) {
    _cacheEnabled = true;
    _cacheTtl = ttl;
    return this;
  }

  /// Direct content block
  AnthropicMessageBuilder contentBlock(Map<String, dynamic> blockData) {
    final type = blockData['type'] as String;

    switch (type) {
      case 'text':
        return _addTextBlock(blockData);
      case 'tools':
        return _addToolsBlock(blockData);
      default:
        _builder.text(blockData['text']?.toString() ?? '');
        return this;
    }
  }

  /// Multiple content blocks
  AnthropicMessageBuilder contentBlocks(List<Map<String, dynamic>> blocks) {
    for (final block in blocks) {
      contentBlock(block);
    }
    return this;
  }

  AnthropicMessageBuilder _addTextBlock(Map<String, dynamic> blockData) {
    final text = blockData['text'] as String;
    final ttl = _cacheTtlFromBlock(blockData);

    if (ttl != null || _hasEphemeralCache(blockData)) {
      cache(ttl: ttl);
    }

    _builder.text(text);
    return this;
  }

  AnthropicMessageBuilder _addToolsBlock(Map<String, dynamic> blockData) {
    final tools = _toolsFromBlock(blockData);
    final ttl = _cacheTtlFromBlock(blockData);

    if (ttl != null || _hasEphemeralCache(blockData)) {
      cache(ttl: ttl);
    }

    _builder.tools(tools);
    return this;
  }

  List<Tool> _toolsFromBlock(Map<String, dynamic> blockData) {
    final toolsData = blockData['tools'] as List<dynamic>;
    final tools = <Tool>[];

    for (final toolData in toolsData) {
      if (toolData is Map<String, dynamic>) {
        final function = toolData['function'] as Map<String, dynamic>;
        tools.add(Tool(
          toolType: toolData['type'] as String? ?? 'function',
          function: FunctionTool(
            name: function['name'] as String,
            description: function['description'] as String,
            parameters: ParametersSchema.fromJson(
              function['parameters'] as Map<String, dynamic>,
            ),
          ),
        ));
      }
    }

    return tools;
  }

  AnthropicCacheTtl? _cacheTtlFromBlock(Map<String, dynamic> blockData) {
    final cacheData = blockData['cache_control'] as Map<String, dynamic>?;
    if (cacheData == null || cacheData['type'] != 'ephemeral') {
      return null;
    }

    return AnthropicCacheTtl.fromString(cacheData['ttl'] as String?);
  }

  bool _hasEphemeralCache(Map<String, dynamic> blockData) {
    final cacheData = blockData['cache_control'] as Map<String, dynamic>?;
    return cacheData != null && cacheData['type'] == 'ephemeral';
  }
}

/// Extension to add Anthropic-specific functionality to MessageBuilder
///
/// **Content Handling:**
/// When using `.anthropicConfig().cache()` followed by `.text()`, content is handled as follows:
/// - The `.cache()` method prepares caching for the next `.text()` call
/// - The following `.text()` call applies the text content to the cached block
/// - Cached content appears in message.extensions['anthropic'] for provider-specific processing
/// - During API conversion, cached text blocks are sent with appropriate cache_control
///
/// **Example:**
/// ```dart
/// final message = MessageBuilder.system()
///     .text('System instructions')
///     .anthropicConfig((anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
///     .text('More content')
///     .build();
/// // All text content gets cache_control applied in _buildRequestBody
/// ```
extension AnthropicMessageBuilderExtension on MessageBuilder {
  /// Configure Anthropic-specific features
  MessageBuilder anthropicConfig(
      void Function(AnthropicMessageBuilder) configure) {
    final anthropicBuilder = AnthropicMessageBuilder._(this);
    configure(anthropicBuilder);

    if (anthropicBuilder._cacheEnabled) {
      final cacheMarker = AnthropicTextBlock(
        text: '',
        cacheControl: AnthropicCacheControl.ephemeral(
          ttl: anthropicBuilder._cacheTtl?.value,
        ),
      );
      addBlock(cacheMarker);
      addProviderExtension(const _AnthropicCachedToolsExtension());
    }
    return this;
  }
}

final class _AnthropicCachedToolsExtension extends MessageProviderExtension {
  const _AnthropicCachedToolsExtension();

  @override
  String get providerId => 'anthropic';

  @override
  Iterable<ContentBlock> buildContentBlocks(
    MessageProviderExtensionContext context,
  ) sync* {
    if (!_hasCacheMarker(context.providerBlocks)) {
      return;
    }

    for (final toolsBlock in context.universalBlocksOfType<ToolsBlock>()) {
      yield AnthropicToolsBlock(toolsBlock.tools);
    }
  }

  bool _hasCacheMarker(List<ContentBlock> providerBlocks) {
    return providerBlocks.any((block) {
      final json = block.toJson();
      return json['cache_control'] != null && json['text'] == '';
    });
  }
}

/// Anthropic cache control
class AnthropicCacheControl {
  final String type;
  final String? ttl;

  const AnthropicCacheControl.ephemeral({this.ttl}) : type = 'ephemeral';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'type': type};
    if (ttl != null) {
      json['ttl'] = ttl;
    }
    return json;
  }
}

/// Cache TTL options for Anthropic
enum AnthropicCacheTtl {
  fiveMinutes(300, '5m'),
  oneHour(3600, '1h');

  const AnthropicCacheTtl(this.seconds, this.value);
  final int seconds;
  final String value;

  /// Create from string value
  static AnthropicCacheTtl? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case '5m':
        return AnthropicCacheTtl.fiveMinutes;
      case '1h':
        return AnthropicCacheTtl.oneHour;
      default:
        return null;
    }
  }
}
