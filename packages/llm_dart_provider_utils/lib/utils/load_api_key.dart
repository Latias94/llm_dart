import 'package:llm_dart_core/llm_dart_core.dart';

import 'environment_stub.dart' if (dart.library.io) 'environment_io.dart';

/// Loads an API key from a parameter or environment variable.
///
/// Mirrors Vercel AI SDK's `loadApiKey(...)`.
String loadApiKey({
  required Object? apiKey,
  required String environmentVariableName,
  String apiKeyParameterName = 'apiKey',
  required String description,
  String? Function(String name)? environmentLookup,
}) {
  if (apiKey is String) {
    return apiKey;
  }

  if (apiKey != null) {
    throw LoadApiKeyError(
      message: '$description API key must be a string.',
    );
  }

  final lookup = environmentLookup ?? getEnvironmentVariable;
  final supported = environmentLookup != null || environmentVariablesSupported;

  if (!supported) {
    throw LoadApiKeyError(
      message:
          "$description API key is missing. Pass it using the '$apiKeyParameterName' parameter. "
          'Environment variables is not supported in this environment.',
    );
  }

  final loaded = lookup(environmentVariableName);
  if (loaded == null || loaded.isEmpty) {
    throw LoadApiKeyError(
      message:
          "$description API key is missing. Pass it using the '$apiKeyParameterName' parameter "
          'or the $environmentVariableName environment variable.',
    );
  }

  return loaded;
}
