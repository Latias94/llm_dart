import 'provider_options.dart';

final class CallOptions {
  final Duration? timeout;
  final Map<String, String>? headers;
  final ProviderInvocationOptions? providerOptions;

  const CallOptions({
    this.timeout,
    this.headers,
    this.providerOptions,
  });
}
