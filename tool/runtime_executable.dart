import 'dart:io';

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
