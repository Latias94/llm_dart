import 'environment_stub.dart' if (dart.library.io) 'environment_io.dart';

/// Loads an optional string setting from a parameter or environment variable.
///
/// Mirrors Vercel AI SDK's `loadOptionalSetting(...)`.
String? loadOptionalSetting({
  required Object? settingValue,
  required String environmentVariableName,
  String? Function(String name)? environmentLookup,
}) {
  if (settingValue is String) {
    return settingValue;
  }

  if (settingValue != null) {
    return null;
  }

  final lookup = environmentLookup ?? getEnvironmentVariable;
  final supported = environmentLookup != null || environmentVariablesSupported;
  if (!supported) return null;

  final loaded = lookup(environmentVariableName);
  if (loaded == null || loaded.isEmpty) return null;
  return loaded;
}
