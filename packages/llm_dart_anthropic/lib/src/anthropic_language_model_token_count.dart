import 'anthropic_api.dart';
import 'anthropic_token_count.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';

AnthropicTokenCountResult decodeAnthropicLanguageModelTokenCountResponse({
  required Object? body,
  required List<ModelWarning> warnings,
}) {
  final json = decodeAnthropicJsonObject(body);
  return AnthropicTokenCountResult(
    inputTokens: _requiredAnthropicInputTokens(json['input_tokens']),
    warnings: warnings,
  );
}

int _requiredAnthropicInputTokens(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  throw StateError(
    'Expected Anthropic input_tokens to be an int but received ${value.runtimeType}.',
  );
}
