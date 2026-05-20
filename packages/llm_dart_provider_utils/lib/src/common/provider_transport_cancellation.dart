import 'dart:async';

import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

TransportCancellation? bindProviderCancellationToTransport(
  ProviderCancellation? cancellation,
) {
  if (cancellation == null) {
    return null;
  }

  final transportCancellation = TransportCancellation(source: cancellation);
  if (cancellation.isCancelled) {
    transportCancellation.cancel(cancellation.reason);
    return transportCancellation;
  }

  unawaited(
    cancellation.whenCancelled.then(transportCancellation.cancel),
  );
  return transportCancellation;
}

Object normalizeTransportCancellation(
  Object error,
  Object? source,
) {
  if (error is! TransportCancelledException) {
    return error;
  }

  final cancellation = source is ProviderCancellation ? source : null;
  return ProviderCancelledException(
    error.reason ?? cancellation?.reason,
  );
}
