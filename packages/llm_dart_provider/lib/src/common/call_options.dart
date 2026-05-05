import 'provider_cancellation.dart';
import 'provider_options.dart';

final class CallOptions {
  final Duration? timeout;
  final Map<String, String>? headers;
  final ProviderInvocationOptions? providerOptions;
  final ProviderCancellation? cancellation;

  const CallOptions({
    this.timeout,
    this.headers,
    this.providerOptions,
    this.cancellation,
  });
}
