library;

// Core exports
export 'config.dart';
export 'client.dart';
export 'provider.dart';

// Capability modules
export 'chat.dart';

// Re-export the Vercel AI-style facade from the Groq subpackage so
// existing imports continue to work while new code can depend on the
// subpackage directly.
export 'package:llm_dart_groq/llm_dart_groq.dart'
    show GroqProviderSettings, Groq, createGroq, groq;
