import 'dart:async';

import 'package:dio/dio.dart';

import '../common/transport_cancellation.dart';

/// Binds shared transport cancellation to a Dio cancel token.
CancelToken? bindDioCancellation(TransportCancellation? cancellation) {
  if (cancellation == null) {
    return null;
  }

  final cancelToken = CancelToken();
  unawaited(
    cancellation.whenCancelled.then((reason) {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel(reason);
      }
    }),
  );
  return cancelToken;
}
