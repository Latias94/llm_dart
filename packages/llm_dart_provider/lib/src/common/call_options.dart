import 'provider_cancellation.dart';
import 'provider_options.dart';

final class CallOptions {
  final Duration? timeout;
  final Map<String, String>? headers;
  final int? maxRetries;
  final ProviderInvocationOptions? providerOptions;
  final ProviderCancellation? cancellation;

  const CallOptions({
    this.timeout,
    this.headers,
    this.maxRetries,
    this.providerOptions,
    this.cancellation,
  }) : assert(maxRetries == null || maxRetries >= 0);
}
