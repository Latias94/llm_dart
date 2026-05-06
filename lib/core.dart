/// Focused core entrypoint for shared contracts, model specs, serialization,
/// and UI projection.
///
/// New code should prefer this entrypoint over
/// `package:llm_dart_core/llm_dart_core.dart`.
library;

export 'package:llm_dart_ai/llm_dart_ai.dart';

export 'core/cancellation.dart'
    show TransportCancellation, TransportCancelledException;
