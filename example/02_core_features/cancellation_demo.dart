// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;

Future<void> main() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Set OPENAI_API_KEY to run this example.');
    return;
  }

  final model = llm.AI.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');

  print('Cancellation with the stable shared text-call surface.\n');

  await demonstrateStreamingCancellation(model);
  await demonstrateGenerateCancellation(model);
  await demonstrateSharedCancellation(model);
  await demonstratePreCancelledRequest(model);
  await demonstrateModelListingBoundary(apiKey);
}

Future<void> demonstrateStreamingCancellation(core.LanguageModel model) async {
  print('1. streamTextCall(...) cancellation');

  final cancelToken = llm.TransportCancellation();
  var sawVisibleText = false;
  var sawAbortEvent = false;
  var sawCancellationError = false;

  final timer = Timer(
    const Duration(milliseconds: 1200),
    () {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel('Timer-triggered fallback cancellation');
      }
    },
  );

  final stream = core.streamTextCall(
    model: model,
    prompt: [
      core.UserPromptMessage.text(
        'Write a long multi-section essay about the history of computing, '
        'starting before electronic computers and continuing into modern AI.',
      ),
    ],
    callOptions: core.CallOptions(
      cancellation: cancelToken,
    ),
  );

  try {
    await for (final event in stream) {
      switch (event) {
        case core.TextDeltaEvent(:final delta):
          sawVisibleText = true;
          stdout.write(delta);
          if (!cancelToken.isCancelled) {
            stdout.writeln('\n[cancel after first visible chunk]');
            cancelToken.cancel('User stopped reading after the first chunk');
          }
        case core.AbortEvent(:final reason):
          sawAbortEvent = true;
          stdout.writeln('\n[abort event] ${reason ?? 'no explicit reason'}');
        case core.ErrorEvent(:final error):
          if (_isTransportCancelled(error)) {
            sawCancellationError = true;
            stdout.writeln(
              '\n[stream error event] ${error.code}: ${error.message}',
            );
          } else {
            stderr.writeln('\n[stream error] $error');
          }
        case core.FinishEvent(:final finishReason):
          stdout.writeln('\n[finish=$finishReason]');
        default:
          break;
      }
    }

    try {
      await stream.result;
      stdout.writeln('[warning] stream completed before cancellation');
    } on core.ModelError catch (error) {
      if (_isTransportCancelled(error)) {
        stdout.writeln('[stream.result cancelled] ${error.message}');
      } else {
        rethrow;
      }
    }

    print('Visible text received: $sawVisibleText');
    print('Abort event received: $sawAbortEvent');
    print('Cancellation error fallback received: $sawCancellationError\n');
  } catch (error) {
    print('Streaming cancellation demo failed: $error\n');
  } finally {
    timer.cancel();
  }
}

Future<void> demonstrateGenerateCancellation(core.LanguageModel model) async {
  print('2. generateTextCall(...) cancellation');

  final cancelToken = llm.TransportCancellation();

  try {
    final future = core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text(
          'Write a detailed tutorial about event loops, isolates, futures, '
          'streams, and cancellation in Dart with many sections.',
        ),
      ],
      callOptions: core.CallOptions(
        cancellation: cancelToken,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 150));
    cancelToken.cancel('User navigated away before the response finished');

    final result = await future;
    print('[warning] request completed before cancellation: ${result.text}\n');
  } on llm.TransportCancelledException catch (error) {
    print('Caught TransportCancelledException');
    print('Reason: ${llm.CancellationHelper.getCancellationReason(error)}\n');
  } catch (error) {
    if (llm.CancellationHelper.isCancelled(error)) {
      print(
        'Cancelled via helper: '
        '${llm.CancellationHelper.getCancellationReason(error)}\n',
      );
    } else {
      print('Generate cancellation demo failed: $error\n');
    }
  }
}

Future<void> demonstrateSharedCancellation(core.LanguageModel model) async {
  print('3. Shared cancellation token');

  final sharedToken = llm.TransportCancellation();
  final prompts = [
    'Write a long explanation of how Flutter builds widgets.',
    'Write a long explanation of how Dart futures are scheduled.',
    'Write a long explanation of why API boundaries matter in SDK design.',
  ];

  try {
    final requests = prompts
        .map(
          (prompt) => core.generateTextCall(
            model: model,
            prompt: [
              core.UserPromptMessage.text(prompt),
            ],
            callOptions: core.CallOptions(
              cancellation: sharedToken,
            ),
          ),
        )
        .toList(growable: false);

    await Future.delayed(const Duration(milliseconds: 100));
    sharedToken.cancel('A shared UI scope was disposed');

    var cancelledCount = 0;
    var completedCount = 0;

    for (final request in requests) {
      try {
        await request;
        completedCount += 1;
      } catch (error) {
        if (llm.CancellationHelper.isCancelled(error)) {
          cancelledCount += 1;
        } else {
          rethrow;
        }
      }
    }

    print('Completed requests: $completedCount');
    print('Cancelled requests: $cancelledCount\n');
  } catch (error) {
    print('Shared cancellation demo failed: $error\n');
  }
}

Future<void> demonstratePreCancelledRequest(core.LanguageModel model) async {
  print('4. Pre-cancelled request');

  final cancelToken = llm.TransportCancellation();
  cancelToken.cancel('The request owner was already disposed');

  try {
    await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text(
          'This request should never reach the provider.',
        ),
      ],
      callOptions: core.CallOptions(
        cancellation: cancelToken,
      ),
    );

    print('[warning] request unexpectedly ran despite pre-cancellation\n');
  } catch (error) {
    if (llm.CancellationHelper.isCancelled(error)) {
      print(
        'Pre-cancelled request rejected: '
        '${llm.CancellationHelper.getCancellationReason(error)}\n',
      );
    } else {
      print('Pre-cancelled request demo failed: $error\n');
    }
  }
}

Future<void> demonstrateModelListingBoundary(String apiKey) async {
  print('5. Compatibility boundary: model listing');

  try {
    final modelListing =
        await llm.ai().openai().apiKey(apiKey).buildModelListing();
    final cancelToken = llm.TransportCancellation();
    final future = modelListing.models(cancelToken: cancelToken);

    await Future.delayed(const Duration(milliseconds: 10));
    cancelToken.cancel('Boundary request cancelled by caller');

    final models = await future;
    print(
      '[warning] model listing completed before cancellation '
      '(${models.length} models)\n',
    );
  } catch (error) {
    if (llm.CancellationHelper.isCancelled(error)) {
      print(
        'Boundary cancellation handled by the compatibility layer: '
        '${llm.CancellationHelper.getCancellationReason(error)}',
      );
      print('Model listing still lives on the builder surface.\n');
    } else {
      print('Model listing boundary demo failed: $error\n');
    }
  }
}

bool _isTransportCancelled(core.ModelError error) {
  return error.code == 'transport-cancelled';
}
