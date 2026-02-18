import 'package:llm_dart_core/llm_dart_core.dart';

import 'environment_stub.dart' if (dart.library.io) 'environment_io.dart';

/// Loads a required string setting from a parameter or environment variable.
///
/// Mirrors Vercel AI SDK's `loadSetting(...)`.
String loadSetting({
  required Object? settingValue,
  required String environmentVariableName,
  required String settingName,
  required String description,
  String? Function(String name)? environmentLookup,
}) {
  if (settingValue is String) {
    return settingValue;
  }

  if (settingValue != null) {
    throw LoadSettingError(
      message: '$description setting must be a string.',
    );
  }

  final lookup = environmentLookup ?? getEnvironmentVariable;
  final supported = environmentLookup != null || environmentVariablesSupported;

  if (!supported) {
    throw LoadSettingError(
      message: '$description setting is missing. '
          "Pass it using the '$settingName' parameter. "
          'Environment variables is not supported in this environment.',
    );
  }

  final loaded = lookup(environmentVariableName);
  if (loaded == null || loaded.isEmpty) {
    throw LoadSettingError(
      message: '$description setting is missing. '
          "Pass it using the '$settingName' parameter "
          'or the $environmentVariableName environment variable.',
    );
  }

  return loaded;
}
