/// Legacy OpenAI-compatible provider defaults.
///
/// New code should prefer `OpenAICompatibleProviderProfiles` from the
/// `llm_dart_openai_compatible` package to get more fine-grained information
/// about models and capabilities.
///
/// This file only provides an explicit import path for legacy code that still
/// uses `OpenAICompatibleDefaults`:
/// `import 'package:llm_dart/legacy/openai_compatible_defaults.dart';`.
library;

export '../core/provider_defaults.dart' show OpenAICompatibleDefaults;
