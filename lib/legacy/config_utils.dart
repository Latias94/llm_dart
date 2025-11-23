/// Legacy configuration utilities.
///
/// New code should use `HttpHeaderUtils` and `HttpConfigUtils` directly, and
/// implement message/parameter conversion logic inside each provider subpackage.
///
/// This file only exists to provide an explicit import path for code that still
/// depends on the legacy `ConfigUtils`:
/// `import 'package:llm_dart/legacy/config_utils.dart';`.
library;

export '../utils/config_utils.dart' show ConfigUtils;
