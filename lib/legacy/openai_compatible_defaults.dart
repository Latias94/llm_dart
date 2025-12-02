@Deprecated(
  'Legacy OpenAI-compatible provider defaults. '
  'Use OpenAICompatibleProviderProfiles from '
  'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart '
  'for model- and provider-specific configuration. '
  'This shim will be removed in a future release.',
)

/// Legacy OpenAI-compatible provider defaults.
///
/// New code should prefer `OpenAICompatibleProviderProfiles` from the
/// `llm_dart_openai_compatible` package to get more fine-grained information
/// about models and capabilities.
///
/// This file only provides an explicit import path for legacy code that still
/// uses `OpenAICompatibleDefaults`: New code should not depend on this path.
/// `import 'package:llm_dart/legacy/openai_compatible_defaults.dart';`.
library;

// This legacy entry point previously re-exported OpenAICompatibleDefaults
// from core-level provider defaults. The defaults have been removed in favor
// of the richer OpenAICompatibleProviderProfiles in the
// llm_dart_openai_compatible package. The file is kept only to avoid breaking
// imports; it no longer exports any symbols.
