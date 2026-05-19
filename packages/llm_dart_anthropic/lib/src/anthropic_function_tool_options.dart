import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_request_json.dart';

final class AnthropicFunctionToolOptions implements ProviderToolOptions {
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

final class AnthropicFunctionToolOptionsJsonCodec
    implements ProviderToolOptionsJsonCodec<AnthropicFunctionToolOptions> {
  static const typeId = 'anthropic.functionToolOptions';

  const AnthropicFunctionToolOptionsJsonCodec();

  @override
  String get type => typeId;

  @override
  bool canEncode(ProviderToolOptions options) {
    return options is AnthropicFunctionToolOptions;
  }

  @override
  Map<String, Object?> encode(ProviderToolOptions options) {
    final typed = options as AnthropicFunctionToolOptions;
    return {
      if (typed.deferLoading != null) 'deferLoading': typed.deferLoading,
      if (typed.eagerInputStreaming != null)
        'eagerInputStreaming': typed.eagerInputStreaming,
      if (typed.allowedCallers != null && typed.allowedCallers!.isNotEmpty)
        'allowedCallers': [
          for (final caller in typed.allowedCallers!) caller.value,
        ],
      if (typed.inputExamples != null && typed.inputExamples!.isNotEmpty)
        'inputExamples': [
          for (final example in typed.inputExamples!)
            {
              'input': example.input,
            },
        ],
    };
  }

  @override
  AnthropicFunctionToolOptions decode(Map<String, Object?> json) {
    return AnthropicFunctionToolOptions(
      deferLoading: _asNullableBool(json['deferLoading'], 'deferLoading'),
      eagerInputStreaming: _asNullableBool(
        json['eagerInputStreaming'],
        'eagerInputStreaming',
      ),
      allowedCallers: _decodeAllowedCallers(json['allowedCallers']),
      inputExamples: _decodeInputExamples(json['inputExamples']),
    );
  }

  List<AnthropicToolAllowedCaller>? _decodeAllowedCallers(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! List) {
      throw const FormatException('allowedCallers must be a JSON array.');
    }

    return [
      for (var index = 0; index < value.length; index++)
        _decodeAllowedCaller(value[index], index),
    ];
  }

  AnthropicToolAllowedCaller _decodeAllowedCaller(Object? value, int index) {
    if (value is! String) {
      throw FormatException('allowedCallers[$index] must be a string.');
    }

    for (final caller in AnthropicToolAllowedCaller.values) {
      if (caller.value == value) {
        return caller;
      }
    }

    throw FormatException('Unsupported allowedCallers[$index] "$value".');
  }

  List<AnthropicToolInputExample>? _decodeInputExamples(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! List) {
      throw const FormatException('inputExamples must be a JSON array.');
    }

    return [
      for (var index = 0; index < value.length; index++)
        _decodeInputExample(value[index], index),
    ];
  }

  AnthropicToolInputExample _decodeInputExample(Object? value, int index) {
    if (value is! Map) {
      throw FormatException('inputExamples[$index] must be a JSON object.');
    }
    final map = value.map((key, nested) {
      if (key is! String) {
        throw FormatException('inputExamples[$index] keys must be strings.');
      }
      return MapEntry(key, nested);
    });
    final input = map['input'];
    if (input is! Map<String, Object?>) {
      throw FormatException(
          'inputExamples[$index].input must be a JSON object.');
    }

    return AnthropicToolInputExample(input);
  }

  bool? _asNullableBool(Object? value, String path) {
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value;
    }
    throw FormatException('$path must be a bool.');
  }
}

const anthropicFunctionToolOptionsJsonCodec =
    AnthropicFunctionToolOptionsJsonCodec();
