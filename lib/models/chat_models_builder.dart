part of 'chat_models.dart';

/// Simple interface for provider-specific blocks
abstract class ContentBlock {
  String get displayText;
  String get providerId;
  Map<String, dynamic> toJson();
}

/// Universal text block that works with all providers
class UniversalTextBlock implements ContentBlock {
  final String text;

  UniversalTextBlock(this.text);

  @override
  String get displayText => text;

  @override
  String get providerId => 'universal';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        'text': text,
      };
}

/// Tools block for storing tools in messages
/// This allows tools to be cached and processed by providers
class ToolsBlock implements ContentBlock {
  final List<Tool> tools;

  ToolsBlock(this.tools);

  @override
  String get displayText => '[${tools.length} tools defined]';

  @override
  String get providerId => 'universal';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tools',
        'tools': tools.map((tool) => tool.toJson()).toList(),
      };
}

/// Message builder for creating messages with provider-specific extensions
class MessageBuilder {
  final ChatRole _role;
  final List<ContentBlock> _blocks = [];
  String? _name;

  MessageBuilder._(this._role);

  // Factory methods
  static MessageBuilder system() => MessageBuilder._(ChatRole.system);
  static MessageBuilder user() => MessageBuilder._(ChatRole.user);
  static MessageBuilder assistant() => MessageBuilder._(ChatRole.assistant);

  // Universal methods
  MessageBuilder text(String text) {
    _blocks.add(UniversalTextBlock(text));
    return this;
  }

  MessageBuilder name(String name) {
    _name = name;
    return this;
  }

  /// Add tools to this message
  MessageBuilder tools(List<Tool> tools) {
    addBlock(ToolsBlock(tools));
    return this;
  }

  // Method for providers to add blocks
  void addBlock(ContentBlock block) {
    _blocks.add(block);
  }

  // Build ChatMessage with extensions
  ChatMessage build() {
    final textBlocks = _blocks.where(
      (block) => block is! ToolsBlock && block.displayText.trim().isNotEmpty,
    );
    final content = textBlocks.map((block) => block.displayText).join('\n');

    final extensions = <String, dynamic>{};
    final providerGroups = <String, List<ContentBlock>>{};
    final universalTools = <ToolsBlock>[];

    for (final block in _blocks) {
      if (block.providerId == 'universal') {
        if (block is ToolsBlock) {
          universalTools.add(block);
        }
        continue;
      }

      providerGroups.putIfAbsent(block.providerId, () => []).add(block);
    }

    if (providerGroups.containsKey('anthropic') && universalTools.isNotEmpty) {
      final anthropicBlocks = providerGroups['anthropic']!;
      final hasCacheMarker = anthropicBlocks.any((block) {
        final json = block.toJson();
        return json['cache_control'] != null && json['text'] == '';
      });

      if (hasCacheMarker) {
        for (final toolsBlock in universalTools) {
          anthropicBlocks.add(_AnthropicToolsBlockWrapper(toolsBlock.tools));
        }
      }
    }

    for (final entry in providerGroups.entries) {
      extensions[entry.key] = {
        'contentBlocks': entry.value.map((block) => block.toJson()).toList(),
      };
    }

    return ChatMessage(
      role: _role,
      messageType: const TextMessage(),
      content: content,
      name: _name,
      extensions: extensions,
    );
  }
}

/// Internal wrapper to make ToolsBlock appear as anthropic-specific
class _AnthropicToolsBlockWrapper implements ContentBlock {
  final List<Tool> tools;

  _AnthropicToolsBlockWrapper(this.tools);

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
