import 'chat_models.dart';
import 'content_block.dart';
import '../providers/anthropic/message_builder.dart';
import '../providers/openai/message_builder.dart';

/// Universal text content block that works with all providers
class UniversalTextBlock implements ContentBlock {
  final String text;

  const UniversalTextBlock(this.text);

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

/// Main message builder for creating ChatMessage instances with provider-specific content
class MessageBuilder {
  final ChatRole _role;
  final List<ContentBlock> _blocks = [];
  String? _name;

  MessageBuilder._(this._role);

  /// Create a system message builder
  static MessageBuilder system() => MessageBuilder._(ChatRole.system);

  /// Create a user message builder
  static MessageBuilder user() => MessageBuilder._(ChatRole.user);

  /// Create an assistant message builder
  static MessageBuilder assistant() => MessageBuilder._(ChatRole.assistant);

  /// Add universal text content that works with all providers
  MessageBuilder text(String text) {
    _blocks.add(UniversalTextBlock(text));
    return this;
  }

  /// Set the message name (useful for system messages)
  MessageBuilder name(String name) {
    _name = name;
    return this;
  }

  /// Configure Anthropic-specific content using a callback
  MessageBuilder anthropic(void Function(AnthropicMessageBuilder) configure) {
    final anthropicBuilder = AnthropicMessageBuilder(_addBlock);
    configure(anthropicBuilder);
    return this;
  }

  /// Configure OpenAI-specific content using a callback
  MessageBuilder openai(void Function(OpenAIMessageBuilder) configure) {
    final openaiBuilder = OpenAIMessageBuilder(_addBlock);
    configure(openaiBuilder);
    return this;
  }

  /// Internal method for provider-specific builders to add blocks
  void _addBlock(ContentBlock block) {
    _blocks.add(block);
  }

  /// Build the final ChatMessage with extensions containing provider-specific data
  ChatMessage build() {
    // Create universal text content from all blocks
    final content = _blocks.map((block) => block.displayText).join('\n');

    // Group blocks by provider ID
    final extensions = <String, dynamic>{};
    final providerGroups = <String, List<ContentBlock>>{};

    for (final block in _blocks) {
      if (block.providerId == 'universal') continue;

      providerGroups.putIfAbsent(block.providerId, () => []).add(block);
    }

    // Create extensions for each provider
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