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
/// import 'package:llm_dart/providers/phind/phind.dart';
///
/// final provider = PhindProvider(PhindConfig(
///   apiKey: 'your-api-key',
///   model: 'Phind-70B',
/// ));
///
/// // Use chat capability for coding questions
/// final response = await provider.chat([
///   ChatMessage.user('How do I implement a binary search in Dart?')
/// ]);
///
/// // Use streaming for real-time code generation
/// await for (final event in provider.chatStream([
///   ChatMessage.user('Write a Flutter widget for a todo list')
/// ])) {
///   if (event is TextDeltaEvent) {
///     print(event.text);
///   }
/// }
/// ```
library;

import 'config.dart';
import 'provider.dart';

// Core exports
export 'config.dart';
export 'client.dart';
export 'provider.dart';

// Capability modules
export 'chat.dart';

/// Create a Phind provider with default settings
PhindProvider createPhindProvider({
  required String apiKey,
  String model = 'Phind-70B',
  String baseUrl = 'https://https.extension.phind.com/agent/',
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
}) {
  final config = PhindConfig(
    apiKey: apiKey,
    model: model,
    baseUrl: baseUrl,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return PhindProvider(config);
}

