library;

/// Legacy exports for `llm_dart_ai`.
///
/// Import this library only if you need backwards-compatible helper aliases
/// such as `*FromPromptIr` / `*FromPrompt`.
///
/// These aliases are deprecated and planned to be removed in `0.12.0-alpha.1`.
///
/// Prefer importing `package:llm_dart_ai/llm_dart_ai.dart` for the current
/// Vercel-style task APIs.
export 'src/generate_text.dart';
export 'src/tool_types.dart';
export 'src/tool_set.dart';
export 'src/tool_loop.dart';
export 'src/stream_text.dart';
export 'src/stream_parts.dart';
export 'src/embed.dart';
export 'src/generate_object.dart';
export 'src/generate_image.dart';
export 'src/generate_speech.dart';
export 'src/transcribe.dart';
export 'src/types.dart';
export 'src/prompt.dart';
