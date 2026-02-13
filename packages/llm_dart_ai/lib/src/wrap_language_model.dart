import 'package:llm_dart_core/llm_dart_core.dart';

import 'middleware.dart';
import 'wrap_language_model_with_middleware.dart';

/// Wraps a chat model with default per-call request overrides (headers/body).
///
/// This is equivalent to applying [DefaultCallOptionsMiddleware] via
/// [wrapLanguageModelWithMiddleware].
ChatCapability wrapLanguageModel(
  ChatCapability model, {
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
}) {
  if (defaultCallOptions.isEmpty) return model;
  return wrapLanguageModelWithMiddleware(
    model,
    middlewares: [
      DefaultCallOptionsMiddleware(defaultCallOptions),
    ],
  );
}
