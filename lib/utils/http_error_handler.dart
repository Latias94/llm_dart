/// Backwards-compatible re-export of HTTP error mapping utilities.
///
/// The canonical implementations live in `llm_dart_core`. This file is kept
/// only so that existing imports from `utils/http_error_handler.dart` continue
/// to work without duplicating logic.
library;

export '../core/llm_error.dart' show HttpErrorMapper, DioErrorHandler;
