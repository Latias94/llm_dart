import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:llm_dart_core/llm_dart_core.dart';

/// Returns a stable, human-readable error message.
///
/// Mirrors Vercel AI SDK's `getErrorMessage(...)` behavior.
String getErrorMessage(Object? error) {
  if (error == null) return 'unknown error';
  if (error is String) return error;

  if (error is LLMError) return error.message;

  if (error is dio.DioException) {
    final msg = error.message;
    if (msg != null && msg.trim().isNotEmpty) return msg;
    return error.toString();
  }

  if (error is Error || error is Exception) {
    return error.toString();
  }

  try {
    return jsonEncode(error);
  } catch (_) {
    return error.toString();
  }
}
