import 'dart:convert';

final class OpenAIJsonDecodeResult {
  final Object? value;
  final FormatException? error;

  const OpenAIJsonDecodeResult({
    required this.value,
    this.error,
  });
}

OpenAIJsonDecodeResult tryDecodeOpenAIJsonValue(String value) {
  try {
    return OpenAIJsonDecodeResult(
      value: jsonDecode(value),
    );
  } on FormatException catch (error) {
    return OpenAIJsonDecodeResult(
      value: value,
      error: error,
    );
  } catch (error) {
    return OpenAIJsonDecodeResult(
      value: value,
      error: FormatException(error.toString()),
    );
  }
}
