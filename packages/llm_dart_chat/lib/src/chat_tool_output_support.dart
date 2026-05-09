import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

ToolUiPartState chatToolOutputState(ToolOutput output) {
  if (output.denied) {
    return ToolUiPartState.outputDenied;
  }

  return output.isError
      ? ToolUiPartState.outputError
      : ToolUiPartState.outputAvailable;
}

String chatStringifyToolOutputValue(ToolOutput output) {
  final value = output.value;
  if (value is String) {
    return value;
  }

  try {
    return jsonEncode(value);
  } catch (_) {
    return '$value';
  }
}
