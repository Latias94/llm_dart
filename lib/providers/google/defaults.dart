/// Provider-owned defaults for the compatibility-era Google surface.
abstract final class GoogleDefaults {
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/';
  static const String defaultModel = 'gemini-1.5-flash';
  static const int maxInlineDataSize = 20 * 1024 * 1024;
}
