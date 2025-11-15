/// Backwards-compatible re-export of HTTP error mapping utilities.
///
/// The canonical implementations live in the `llm_dart_provider_utils`
/// package. This file is kept only so that existing imports from
/// `utils/http_error_handler.dart` continue to work without duplicating logic.
library;

export 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart'
    show HttpErrorMapper, DioErrorHandler;
