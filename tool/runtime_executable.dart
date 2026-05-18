import 'dart:io';

const toolAnalyticsEnvironment = {
  'DART_SUPPRESS_ANALYTICS': 'true',
  'FLUTTER_SUPPRESS_ANALYTICS': 'true',
};

String resolveToolExecutable(String executable) {
  if (Platform.isWindows) {
    return switch (executable) {
      'dart' => Platform.resolvedExecutable,
      'flutter' => 'flutter.bat',
      _ => executable,
    };
  }

  return switch (executable) {
    'flutter.bat' => 'flutter',
    _ => executable,
  };
}

List<String> resolveToolArguments(
  String executable,
  List<String> arguments,
) {
  if (!isDartToolExecutable(executable) || arguments.isEmpty) {
    return arguments;
  }

  if (arguments.first == '--suppress-analytics' ||
      arguments.first.startsWith('--packages=')) {
    return arguments;
  }

  if (arguments.first.endsWith('.dart')) {
    return ['--suppress-analytics', 'run', ...arguments];
  }

  return ['--suppress-analytics', ...arguments];
}

Map<String, String> buildToolProcessEnvironment([
  Map<String, String>? overrides,
]) {
  final environment = {
    ...toolAnalyticsEnvironment,
    if (overrides != null) ...overrides,
  };
  return Map.unmodifiable(environment);
}

bool isDartToolExecutable(String executable) {
  final normalized = executable.replaceAll('\\', '/').toLowerCase();
  final name = normalized.split('/').last;
  return name == 'dart' || name == 'dart.exe' || name == 'dart.bat';
}
