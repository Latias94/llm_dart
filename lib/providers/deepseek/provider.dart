import 'package:llm_dart_deepseek/llm_dart_deepseek.dart' as deepseek;

/// Backwards-compatible alias for the DeepSeek provider.
///
/// The actual implementation now lives in the `llm_dart_deepseek`
/// subpackage. This typedef ensures existing imports using the main
/// package path continue to work.
typedef DeepSeekProvider = deepseek.DeepSeekProvider;
