/// Anthropic provider-native computer use tool options.
///
/// This mirrors the shape required by Anthropic computer tools such as:
/// - `computer_20241022`
/// - `computer_20250124`
/// - `computer_20251124`
library;

class AnthropicComputerToolOptions {
  /// The width of the display being controlled by the model in pixels.
  final int displayWidthPx;

  /// The height of the display being controlled by the model in pixels.
  final int displayHeightPx;

  /// The display number to control (only relevant for X11 environments).
  final int displayNumber;

  /// Whether to enable zoom action (only supported by some tool versions).
  final bool? enableZoom;

  const AnthropicComputerToolOptions({
    required this.displayWidthPx,
    required this.displayHeightPx,
    this.displayNumber = 1,
    this.enableZoom,
  })  : assert(displayWidthPx > 0),
        assert(displayHeightPx > 0),
        assert(displayNumber >= 0);

  Map<String, dynamic> toJson() => {
        'display_width_px': displayWidthPx,
        'display_height_px': displayHeightPx,
        'display_number': displayNumber,
        if (enableZoom != null) 'enable_zoom': enableZoom,
      };

  factory AnthropicComputerToolOptions.fromJson(Map<String, dynamic> json) {
    int readInt(String key, {String? fallbackKey}) {
      final v = json[key] ?? (fallbackKey == null ? null : json[fallbackKey]);
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    }

    bool? readBool(String key, {String? fallbackKey}) {
      final v = json[key] ?? (fallbackKey == null ? null : json[fallbackKey]);
      if (v is bool) return v;
      return null;
    }

    return AnthropicComputerToolOptions(
      displayWidthPx:
          readInt('display_width_px', fallbackKey: 'displayWidthPx'),
      displayHeightPx:
          readInt('display_height_px', fallbackKey: 'displayHeightPx'),
      displayNumber: readInt('display_number', fallbackKey: 'displayNumber'),
      enableZoom: readBool('enable_zoom', fallbackKey: 'enableZoom'),
    );
  }
}
