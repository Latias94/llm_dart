import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

final class StreamingToolInputState {
  final String toolName;
  final bool providerExecuted;
  final bool isDynamic;
  final String? title;
  final StringBuffer _buffer;

  ProviderMetadata? providerMetadata;

  StreamingToolInputState({
    required this.toolName,
    required this.providerExecuted,
    required this.isDynamic,
    required this.title,
    this.providerMetadata,
    String initialText = '',
  }) : _buffer = StringBuffer(initialText);

  String get text => _buffer.toString();

  Object? get input => decodeStreamingToolInputValue(text);

  void append(String value) {
    _buffer.write(value);
  }

  void mergeProviderMetadata(ProviderMetadata? metadata) {
    providerMetadata = ProviderMetadata.mergeNullable(
      providerMetadata,
      metadata,
    );
  }
}

Object? decodeStreamingToolInputValue(String inputText) {
  final trimmed = inputText.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  try {
    return jsonDecode(trimmed);
  } on FormatException {
    return inputText;
  }
}

String? stringifyStreamingToolValue(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is String) {
    return value;
  }

  try {
    return jsonEncode(value);
  } on JsonUnsupportedObjectError {
    return value.toString();
  }
}
