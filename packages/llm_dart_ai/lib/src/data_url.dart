import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

/// Converts a data URL of type `text/*` to a text string.
///
/// Mirrors Vercel AI SDK's `getTextFromDataUrl(...)`.
String getTextFromDataUrl(String dataUrl) {
  final comma = dataUrl.indexOf(',');
  if (comma <= 0) {
    throw InvalidArgumentError(
      argument: 'dataUrl',
      value: dataUrl,
      message: 'Invalid data URL format.',
    );
  }

  final header = dataUrl.substring(0, comma);
  final payload = dataUrl.substring(comma + 1);

  if (!header.startsWith('data:') || payload.isEmpty) {
    throw InvalidArgumentError(
      argument: 'dataUrl',
      value: dataUrl,
      message: 'Invalid data URL format.',
    );
  }

  try {
    final bytes = base64.decode(payload);
    // JS `atob` returns a Latin1-ish string (one code unit per byte).
    return String.fromCharCodes(bytes);
  } catch (e) {
    throw InvalidArgumentError(
      argument: 'dataUrl',
      value: dataUrl,
      cause: e,
      message: 'Error decoding data URL.',
    );
  }
}
