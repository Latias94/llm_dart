/// Header utilities shared across providers.
library;

import 'package:llm_dart_core/utils/header_utils.dart' as core;

export 'package:llm_dart_core/utils/header_utils.dart'
    show removeHeaderIgnoreCase, setHeaderCaseInsensitive;

/// Merge headers with case-insensitive key matching.
///
/// For `User-Agent`, this concatenates values as:
/// `overrides['User-Agent'] + base['User-Agent']` (space-separated).
///
/// This mirrors the behavior used by `HttpConfigUtils`.
Map<String, String> mergeHeadersCaseInsensitive(
  Map<String, String> base,
  Map<String, String> overrides,
) =>
    core.mergeHeadersCaseInsensitive(
      base,
      overrides,
      mergeUserAgent: true,
    );
