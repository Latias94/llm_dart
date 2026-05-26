/// Provider call execution kit.
///
/// This explicit entrypoint is for provider adapters that need shared
/// transport execution, cancellation mapping, stream decoding, and model-error
/// projection policy while keeping provider-specific codecs local.
library;

export 'src/provider_call_kit.dart';
