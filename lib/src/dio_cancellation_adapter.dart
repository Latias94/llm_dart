import 'dart:async';

import 'package:dio/dio.dart' as dio;

import '../core/cancellation.dart';

dio.CancelToken? bindDioCancellation(TransportCancellation? cancellation) {
  if (cancellation == null) {
    return null;
  }

  final cancelToken = dio.CancelToken();
  unawaited(
    cancellation.whenCancelled.then((reason) {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel(reason);
      }
    }),
  );
  return cancelToken;
}
