// The Phind provider facade is prompt-first and re-exports the
// dedicated `llm_dart_phind` subpackage.

/// Modular Phind Provider
///
/// This library provides a modular implementation of the Phind provider
/// following the same architecture pattern as other providers.
///
/// **Key Features:**
/// - Specialized for coding and development tasks
/// - Phind-70B model with coding expertise
/// - Unique API format handling
/// - Modular architecture for easy maintenance
/// - Support for code generation and reasoning
///
/// **Usage:**
/// ```dart
/// import 'package:llm_dart/llm_dart.dart';
/// import 'package:llm_dart/providers/phind/phind.dart';
///
/// final provider = PhindProvider(PhindConfig(
///   apiKey: 'your-api-key',
///   model: 'Phind-70B',
/// ));
///
/// // Use chat capability for coding questions
/// final response = await provider.chat([
///   ModelMessage.userText('How do I implement a binary search in Dart?')
/// ]);
///
/// // Use streaming for real-time code generation
/// await for (final event in provider.chatStream([
///   ModelMessage.userText('Write a Flutter widget for a todo list')
/// ])) {
///   if (event is TextDeltaEvent) {
///     print(event.text);
///   }
/// }
/// ```
library;

// Core exports
export 'config.dart';
export 'client.dart';
export 'provider.dart';

// Capability modules
export 'chat.dart';

// Vercel AI-style facade exports (model-centric API).
export 'package:llm_dart_phind/llm_dart_phind.dart'
    show PhindProviderSettings, Phind, createPhind, phind;
