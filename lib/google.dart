/// Focused Google provider entrypoint.
///
/// Exports provider-owned Google types plus the short `google(...)` factory.
/// Import `core.dart` / `transport.dart` for shared layers.
library;

export 'package:llm_dart_google/llm_dart_google.dart' hide google;
export 'src/facade/ai.dart' show google;
