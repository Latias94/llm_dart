/// Anthropic provider-native text editor tool options.
///
/// This mirrors the optional parameters for newer Anthropic text editor tools
/// such as `text_editor_20250728` (e.g. `max_characters`).
library;

class AnthropicTextEditorToolOptions {
  /// Optional maximum number of characters to view in the file.
  final int? maxCharacters;

  const AnthropicTextEditorToolOptions({this.maxCharacters})
      : assert(maxCharacters == null || maxCharacters > 0);

  Map<String, dynamic> toJson() => {
        if (maxCharacters != null) 'max_characters': maxCharacters,
      };

  factory AnthropicTextEditorToolOptions.fromJson(Map<String, dynamic> json) {
    final raw = json['max_characters'] ?? json['maxCharacters'];
    int? parseInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return null;
    }

    return AnthropicTextEditorToolOptions(
      maxCharacters: parseInt(raw),
    );
  }
}
