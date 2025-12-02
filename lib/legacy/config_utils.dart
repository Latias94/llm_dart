@Deprecated(
  'Legacy configuration utilities. '
  'Use HttpHeaderUtils / HttpConfigUtils from package:llm_dart_provider_utils '
  'and configure provider-specific behavior in the new provider subpackages '
  'instead. This shim will be removed in a future release.',
)

/// Legacy configuration utilities.
///
/// New code should use `HttpHeaderUtils` and `HttpConfigUtils` directly, and
/// implement message/parameter conversion logic inside each provider subpackage.
///
/// This file only exists to provide an explicit import path for code that still
/// depends on the legacy `ConfigUtils`:
/// `import 'package:llm_dart/legacy/config_utils.dart';`. New code should not
/// depend on this path.
library;

export '../utils/config_utils.dart' show ConfigUtils;
