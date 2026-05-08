/// Modular DeepSeek Provider
///
/// This library provides a modular implementation of the DeepSeek provider
///
/// **Key Benefits:**
/// - Single Responsibility: Each module handles one capability
/// - Easier Testing: Modules can be tested independently
/// - Better Maintainability: Changes isolated to specific modules
/// - Cleaner Code: Smaller, focused classes
/// - Reusability: Modules can be reused across providers
///
/// **Usage:**
/// ```dart
/// import 'package:llm_dart/providers/deepseek/deepseek.dart';
///
/// final provider = DeepSeekProvider(DeepSeekConfig(
///   apiKey: 'your-api-key',
///   model: 'deepseek-chat',
/// ));
///
/// // Use chat capability
/// final response = await provider.chat(messages);
/// ```
library;

import 'config.dart';
import 'defaults.dart';
import 'provider.dart';

// Core exports
export 'config.dart';
export 'defaults.dart';
export 'client.dart';
export 'provider.dart';

// Capability modules
export 'chat.dart';
export 'models.dart';

// Error handling
export 'error_handler.dart';

/// Create a DeepSeek provider with default configuration
DeepSeekProvider createDeepSeekProvider({
  required String apiKey,
  String? model,
  String? baseUrl,
  int? maxTokens,
  double? temperature,
  String? systemPrompt,
  Duration? timeout,
  bool? stream,
  double? topP,
  int? topK,
}) {
  final config = DeepSeekConfig(
    apiKey: apiKey,
    model: model ?? DeepSeekDefaults.defaultModel,
    baseUrl: baseUrl ?? DeepSeekDefaults.baseUrl,
    maxTokens: maxTokens,
    temperature: temperature,
    systemPrompt: systemPrompt,
    timeout: timeout,
    topP: topP,
    topK: topK,
  );

  return DeepSeekProvider(config);
}
