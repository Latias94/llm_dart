import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'provider_options.dart';

final class CallOptions {
  final Duration? timeout;
  final Map<String, String>? headers;
  final ProviderInvocationOptions? providerOptions;
  final TransportCancellation? cancellation;

  const CallOptions({
    this.timeout,
    this.headers,
    this.providerOptions,
    this.cancellation,
  });
}
