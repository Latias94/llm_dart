part of 'anthropic_prompt_cache_models.dart';

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
