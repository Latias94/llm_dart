/// IO-only Dio adapter subentrypoint.
///
/// Import this only on `dart:io` platforms. The main
/// `package:llm_dart_transport/llm_dart_transport.dart` entrypoint stays
/// Web-safe and does not export `package:dio/io.dart`.
library;

export 'package:dio/io.dart';
