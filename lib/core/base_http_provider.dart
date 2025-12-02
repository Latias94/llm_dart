import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart'
    as provider_utils;

/// Legacy HTTP provider base class.
///
/// To preserve backwards compatibility, this package still exposes a
/// `BaseHttpProvider` type alias that points to the implementation in
/// `llm_dart_provider_utils`. This avoids divergent behavior between
/// two different base HTTP provider definitions.
/// New code should depend directly on the HTTP utilities in
/// `llm_dart_provider_utils`.
@Deprecated(
  'Use DioClientFactory and BaseProviderDioStrategy in '
  'llm_dart_provider_utils instead of BaseHttpProvider.',
)
typedef BaseHttpProvider = provider_utils.BaseHttpProvider;
