import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

/// Parses a provider's namespaced `providerOptions` entry.
///
/// This is a Dart counterpart to Vercel AI SDK's `parseProviderOptions(...)`.
///
/// Returns `null` when the namespace is absent.
Future<T?> parseProviderOptions<T>({
  required String provider,
  required ProviderOptions? providerOptions,
  required FutureOr<T> Function(Object raw) parse,
}) async {
  final raw = providerOptions?[provider];
  if (raw == null) return null;

  try {
    return await Future<T>.value(parse(raw));
  } catch (e) {
    throw InvalidArgumentError(
      argument: 'providerOptions',
      message: 'invalid $provider provider options',
      value: e,
      cause: e,
    );
  }
}
