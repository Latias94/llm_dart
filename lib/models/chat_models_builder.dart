part of 'chat_models.dart';

/// Simple interface for provider-specific blocks
abstract class ContentBlock {
  String get displayText;
  String get providerId;
  Map<String, dynamic> toJson();
}

/// Context provided to provider extensions during message building.
class MessageProviderExtensionContext {
  final String providerId;
  final List<ContentBlock> allBlocks;
  final List<ContentBlock> universalBlocks;
  final List<ContentBlock> providerBlocks;

  const MessageProviderExtensionContext({
    required this.providerId,
    required this.allBlocks,
    required this.universalBlocks,
    required this.providerBlocks,
  });

  Iterable<T> universalBlocksOfType<T extends ContentBlock>() {
    return universalBlocks.whereType<T>();
  }
}

/// Provider-owned extension point for projecting universal blocks.
abstract class MessageProviderExtension {
  const MessageProviderExtension();

  String get providerId;

  Object get extensionId => runtimeType;

  Iterable<ContentBlock> buildContentBlocks(
    MessageProviderExtensionContext context,
  );
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
  final List<MessageProviderExtension> _providerExtensions = [];
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

  // Method for providers to add build-time extension logic
  void addProviderExtension(MessageProviderExtension extension) {
    _providerExtensions.removeWhere(
      (registered) =>
          registered.providerId == extension.providerId &&
          registered.extensionId == extension.extensionId,
    );
    _providerExtensions.add(extension);
  }

  // Build ChatMessage with extensions
  ChatMessage build() {
    final textBlocks = _blocks.where(
      (block) => block is! ToolsBlock && block.displayText.trim().isNotEmpty,
    );
    final content = textBlocks.map((block) => block.displayText).join('\n');

    final extensions = <String, dynamic>{};
    final providerGroups = <String, List<ContentBlock>>{};
    final universalBlocks = <ContentBlock>[];

    for (final block in _blocks) {
      if (block.providerId == 'universal') {
        universalBlocks.add(block);
        continue;
      }

      providerGroups.putIfAbsent(block.providerId, () => []).add(block);
    }

    for (final extension in _providerExtensions) {
      final providerBlocks = providerGroups[extension.providerId] ?? const [];
      final additionalBlocks = extension
          .buildContentBlocks(
            MessageProviderExtensionContext(
              providerId: extension.providerId,
              allBlocks: List.unmodifiable(_blocks),
              universalBlocks: List.unmodifiable(universalBlocks),
              providerBlocks: List.unmodifiable(providerBlocks),
            ),
          )
          .toList(growable: false);

      if (additionalBlocks.isNotEmpty) {
        providerGroups
            .putIfAbsent(extension.providerId, () => [])
            .addAll(additionalBlocks);
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
