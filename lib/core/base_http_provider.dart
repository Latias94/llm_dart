/// Legacy HTTP provider base class.
///
/// NOTE: New provider implementations should prefer the HTTP utilities in the
/// `llm_dart_provider_utils` package (`DioClientFactory` and
/// `BaseProviderDioStrategy`, `HttpResponseHandler`, etc.) instead of
/// extending this class. This type is kept only for backwards compatibility
/// with older code and may be removed in a future major release.
@Deprecated(
  'Use DioClientFactory and BaseProviderDioStrategy in '
  'llm_dart_provider_utils instead of BaseHttpProvider.',
)
abstract class BaseHttpProvider {}

