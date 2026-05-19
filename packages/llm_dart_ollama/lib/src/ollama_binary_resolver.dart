import 'dart:async';

typedef OllamaBinaryResolver = FutureOr<List<int>?> Function(
  Uri uri, {
  required String mediaType,
  String? filename,
});
