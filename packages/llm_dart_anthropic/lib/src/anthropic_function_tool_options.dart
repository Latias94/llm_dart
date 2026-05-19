import 'anthropic_request_json.dart';

final class AnthropicFunctionToolOptions {
  final bool? deferLoading;
  final bool? eagerInputStreaming;
  final List<AnthropicToolAllowedCaller>? allowedCallers;
  final List<AnthropicToolInputExample>? inputExamples;

  const AnthropicFunctionToolOptions({
    this.deferLoading,
    this.eagerInputStreaming,
    this.allowedCallers,
    this.inputExamples,
  });

  AnthropicFunctionToolOptions copyWith({
    bool? deferLoading,
    bool? eagerInputStreaming,
    List<AnthropicToolAllowedCaller>? allowedCallers,
    List<AnthropicToolInputExample>? inputExamples,
  }) {
    return AnthropicFunctionToolOptions(
      deferLoading: deferLoading ?? this.deferLoading,
      eagerInputStreaming: eagerInputStreaming ?? this.eagerInputStreaming,
      allowedCallers: allowedCallers ?? this.allowedCallers,
      inputExamples: inputExamples ?? this.inputExamples,
    );
  }

  bool get usesAdvancedToolUse {
    return (allowedCallers != null && allowedCallers!.isNotEmpty) ||
        (inputExamples != null && inputExamples!.isNotEmpty);
  }
}

final class AnthropicToolInputExample {
  final Map<String, Object?> input;

  AnthropicToolInputExample(Map<String, Object?> input)
      : input = Map.unmodifiable(
          normalizeAnthropicJsonObject(
            input,
            path: 'inputExamples[].input',
          ),
        );
}

enum AnthropicToolAllowedCaller {
  direct('direct'),
  codeExecution20250825('code_execution_20250825'),
  codeExecution20260120('code_execution_20260120');

  final String value;

  const AnthropicToolAllowedCaller(this.value);
}
