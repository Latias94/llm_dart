import 'package:dio/dio.dart' as dio;
import 'package:llm_dart_core/llm_dart_core.dart';

class DioCancelTokenBinding {
  final dio.CancelToken? dioCancelToken;
  final void Function() _dispose;

  const DioCancelTokenBinding._(this.dioCancelToken, this._dispose);

  void dispose() => _dispose();

  static DioCancelTokenBinding bind(CancelToken? token) {
    if (token == null) {
      return const DioCancelTokenBinding._(null, _noop);
    }

    final dioToken = dio.CancelToken();

    if (token.isCancelled) {
      dioToken.cancel(token.reason);
      return DioCancelTokenBinding._(dioToken, _noop);
    }

    final remove = token.addListener((reason) {
      if (!dioToken.isCancelled) {
        dioToken.cancel(reason);
      }
    });

    return DioCancelTokenBinding._(dioToken, remove);
  }
}

Future<T> withDioCancelToken<T>(
  CancelToken? token,
  Future<T> Function(dio.CancelToken? dioToken) run,
) async {
  final binding = DioCancelTokenBinding.bind(token);
  try {
    return await run(binding.dioCancelToken);
  } finally {
    binding.dispose();
  }
}

Stream<T> withDioCancelTokenStream<T>(
  CancelToken? token,
  Stream<T> Function(dio.CancelToken? dioToken) run,
) async* {
  final binding = DioCancelTokenBinding.bind(token);
  try {
    yield* run(binding.dioCancelToken);
  } finally {
    binding.dispose();
  }
}

void _noop() {}
