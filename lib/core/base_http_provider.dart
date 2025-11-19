/// Legacy HTTP provider base class.
///
/// This type is kept only so that existing imports from `core/base_http_provider.dart`
/// continue to compile. New implementations should prefer the HTTP utilities
/// from the `llm_dart_provider_utils` package (`DioClientFactory`,
/// `BaseProviderDioStrategy`, `HttpResponseHandler`, etc.).
@Deprecated(
  'Use DioClientFactory and BaseProviderDioStrategy in '
  'llm_dart_provider_utils instead of BaseHttpProvider.',
)
abstract class BaseHttpProvider {}
