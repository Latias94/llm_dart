import 'package:llm_dart_core/llm_dart_core.dart';

/// Minimal OpenAI configuration placeholder.
///
/// This will be replaced by the full implementation migrated from
/// the main llm_dart package. For now it keeps the basic shape so
/// that the package compiles during the refactor.
class OpenAIConfig {
  final String apiKey;
  final String baseUrl;
  final String model;
  final LLMConfig? originalConfig;

  const OpenAIConfig({
    required this.apiKey,
    this.baseUrl = '',
    this.model = '',
    this.originalConfig,
  });
}
