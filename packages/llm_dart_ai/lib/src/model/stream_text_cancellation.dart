import 'dart:async';

import 'package:llm_dart_provider/llm_dart_provider.dart';

Stream<T> cancelOnProviderCancellation<T>(
  Stream<T> source,
  ProviderCancellation? cancellation,
) {
  if (cancellation == null) {
    return source;
  }

  StreamSubscription<T>? subscription;
  late StreamController<T> controller;
  var completed = false;

  void failWithCancellation(Object? reason) {
    if (completed) {
      return;
    }
    completed = true;

    final error = ProviderCancelledException(reason);
    final stackTrace = StackTrace.current;

    Future<void> emitError() async {
      if (!controller.isClosed) {
        controller.addError(error, stackTrace);
        await controller.close();
      }
    }

    final cancelFuture = subscription?.cancel();
    if (cancelFuture == null) {
      unawaited(emitError());
    } else {
      unawaited(cancelFuture.whenComplete(emitError));
    }
  }

  controller = StreamController<T>(
    onListen: () {
      if (cancellation.isCancelled) {
        failWithCancellation(cancellation.reason);
        return;
      }

      subscription = source.listen(
        (event) {
          if (cancellation.isCancelled) {
            failWithCancellation(cancellation.reason);
            return;
          }

          if (!completed) {
            controller.add(event);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (completed) {
            return;
          }
          completed = true;
          controller.addError(error, stackTrace);
          unawaited(controller.close());
        },
        onDone: () {
          if (completed) {
            return;
          }
          completed = true;
          unawaited(controller.close());
        },
      );

      unawaited(
        cancellation.whenCancelled.then(failWithCancellation),
      );
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    onCancel: () async {
      completed = true;
      await subscription?.cancel();
    },
  );

  return controller.stream;
}

bool isProviderCancellation(Object error) {
  return ProviderCancellation.isCancel(error);
}

String? providerCancellationReason(
  ProviderCancellation? cancellation,
  Object error,
) {
  if (error is ProviderCancelledException) {
    return error.reason?.toString();
  }

  return cancellation?.reason?.toString();
}
