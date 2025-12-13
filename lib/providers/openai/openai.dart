/// Modular OpenAI Provider
///
/// This library provides a modular implementation of the OpenAI provider
/// as well as a Vercel AI SDK-style facade that lives in the
/// `llm_dart_openai` subpackage. This file now primarily acts as a
/// backwards-compatible shim that re-exports the canonical OpenAI facade
/// and helper types.
library;

// Core exports (backwards-compatible shims around llm_dart_openai).
export 'config.dart';
export 'client.dart';
export 'provider.dart';

// Capability modules
export 'chat.dart';
export 'embeddings.dart';
export 'audio.dart';
export 'images.dart';
export 'files.dart';
export 'models.dart';
export 'moderation.dart';
export 'assistants.dart';
export 'completion.dart';
export 'responses.dart';
export 'builtin_tools.dart';

// Re-export the Vercel AI-style facade from the OpenAI subpackage so
// existing imports continue to work:
//
//   import 'package:llm_dart/providers/openai/openai.dart';
//
// while new code can also depend directly on llm_dart_openai.
export 'package:llm_dart_openai/llm_dart_openai.dart'
    show
        OpenAIProviderSettings,
        OpenAI,
        OpenAIResponsesModel,
        OpenAITools,
        OpenAIProviderDefinedTools,
        createOpenAI,
        openai;
