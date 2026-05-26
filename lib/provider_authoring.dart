/// Root provider-authoring facade.
///
/// Import this only for custom provider implementations or advanced tests that
/// need provider prompt/request/stream contracts. Applications should prefer
/// `package:llm_dart/llm_dart.dart` or `package:llm_dart/core.dart`.
/// Import `package:llm_dart_provider_utils/provider_call_kit.dart` directly
/// when provider implementations need shared transport call execution.
library;

export 'package:llm_dart_ai/provider_authoring.dart';
