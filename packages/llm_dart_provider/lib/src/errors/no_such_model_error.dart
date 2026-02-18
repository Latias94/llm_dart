import 'package:llm_dart_core/llm_dart_core.dart';

/// Error thrown when a provider cannot resolve a model id.
///
/// Mirrors Vercel AI SDK's `NoSuchModelError` from `@ai-sdk/provider`.
class NoSuchModelError extends InvalidRequestError {
  final String modelId;
  final String modelType;

  NoSuchModelError({
    required this.modelId,
    required this.modelType,
    String? message,
  }) : super(message ?? 'No such $modelType: $modelId');
}
