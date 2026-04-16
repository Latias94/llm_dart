// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/transport.dart' as transport;

/// Stable-first error handling examples centered on `ModelError`.
///
/// This example demonstrates:
/// - local validation failures before any network call
/// - structured-output decoding failures normalized as validation errors
/// - transport/auth/network/timeout normalization
/// - retry, fallback, and circuit-breaker patterns around shared call closures
Future<void> main() async {
  print('Error Handling\n');

  await demonstrateLocalValidationError();
  await demonstrateStructuredOutputValidationError();
  await demonstrateAuthenticationFailure();
  await demonstrateNetworkFailure();
  await demonstrateTimeoutFailure();
  await demonstrateRetryPattern();
  await demonstrateFallbackPattern();
  await demonstrateCircuitBreakerPattern();

  print('Error handling completed.');
}

Future<void> demonstrateLocalValidationError() async {
  print('=== Local Validation Error ===\n');

  try {
    await core.generateTextCall(
      model: const _StaticTextLanguageModel('unused'),
      prompt: [
        core.UserPromptMessage.text('Hello'),
      ],
      tools: [
        _weatherTool(),
      ],
      toolChoice: const core.SpecificToolChoice('missing_tool'),
    );
    print('Unexpected success.\n');
  } catch (error) {
    _printNormalizedError(
      label: 'Undeclared SpecificToolChoice',
      error: error,
    );
  }
}

Future<void> demonstrateStructuredOutputValidationError() async {
  print('=== Structured Output Validation Error ===\n');

  final model = const _StaticTextLanguageModel(
    '{"summary":42,"actions":["retry from cache"]}',
  );

  try {
    await core.generateTextCall<IncidentPlan>(
      model: model,
      prompt: [
        core.UserPromptMessage.text('Return a remediation plan as JSON.'),
      ],
      outputSpec: core.ObjectOutputSpec<IncidentPlan>(
        schema: core.JsonSchema.object(
          properties: const {
            'summary': {'type': 'string'},
            'actions': {
              'type': 'array',
              'items': {'type': 'string'},
              'minItems': 1,
            },
          },
          required: const ['summary', 'actions'],
          additionalProperties: false,
        ),
        decode: IncidentPlan.fromJson,
      ),
    );
    print('Unexpected success.\n');
  } catch (error) {
    _printNormalizedError(
      label: 'Structured output decode failure',
      error: error,
    );
  }
}

Future<void> demonstrateAuthenticationFailure() async {
  print('=== Authentication Failure ===\n');

  try {
    final model = llm.AI.openai(apiKey: 'invalid-key').chatModel('gpt-4.1-mini');
    await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text('Hello'),
      ],
      callOptions: const core.CallOptions(
        timeout: Duration(seconds: 20),
      ),
    );
    print('Unexpected success.\n');
  } catch (error) {
    _printNormalizedError(
      label: 'Invalid API key request',
      error: error,
    );
  }
}

Future<void> demonstrateNetworkFailure() async {
  print('=== Network Failure ===\n');

  try {
    final model = llm.AI
        .openai(
          apiKey: 'not-used',
          baseUrl: 'https://unreachable-host.invalid/v1',
        )
        .chatModel('gpt-4.1-mini');

    await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text('Hello'),
      ],
      callOptions: const core.CallOptions(
        timeout: Duration(seconds: 3),
      ),
    );
    print('Unexpected success.\n');
  } catch (error) {
    _printNormalizedError(
      label: 'Invalid baseUrl request',
      error: error,
    );
  }
}

Future<void> demonstrateTimeoutFailure() async {
  print('=== Timeout Failure ===\n');

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Skipping timeout example because OPENAI_API_KEY is not set.\n');
    return;
  }

  try {
    final model = llm.AI.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');

    await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text('Say hello in one short sentence.'),
      ],
      callOptions: const core.CallOptions(
        timeout: Duration(milliseconds: 1),
      ),
    );
    print('Unexpected success.\n');
  } catch (error) {
    _printNormalizedError(
      label: 'Short timeout request',
      error: error,
    );
  }
}

Future<void> demonstrateRetryPattern() async {
  print('=== Retry Pattern ===\n');

  final model = _FlakyLanguageModel(
    successText: 'Primary region recovered after retry.',
    failuresBeforeSuccess: 2,
    failureFactory: () => const transport.TransportTimeoutException(
      'Simulated upstream timeout',
    ),
  );

  final retryExecutor = _RetryExecutor<core.GenerateTextCallResult<dynamic>>(
    maxAttempts: 3,
    baseDelay: const Duration(milliseconds: 80),
  );

  final result = await retryExecutor.execute(
    () => core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text('Summarize the current status.'),
      ],
    ),
  );

  print('Final text: ${result.text}\n');
}

Future<void> demonstrateFallbackPattern() async {
  print('=== Fallback Pattern ===\n');

  final primaryModel = _FlakyLanguageModel(
    successText: 'unused',
    failuresBeforeSuccess: 100,
    failureFactory: () => const transport.TransportNetworkException(
      'Primary region is unavailable',
    ),
  );
  final fallbackModel = const _StaticTextLanguageModel(
    'Fallback answer from a cached or secondary path.',
  );

  final fallbackExecutor = _FallbackExecutor<core.GenerateTextCallResult<dynamic>>();

  final outcome = await fallbackExecutor.execute(
    [
      () => core.generateTextCall(
            model: primaryModel,
            prompt: [
              core.UserPromptMessage.text('Generate the release summary.'),
            ],
          ),
      () => core.generateTextCall(
            model: fallbackModel,
            prompt: [
              core.UserPromptMessage.text('Generate the release summary.'),
            ],
          ),
    ],
  );

  print('Resolved by fallback step: ${outcome.stepIndex + 1}');
  print('Final text: ${outcome.value.text}\n');
}

Future<void> demonstrateCircuitBreakerPattern() async {
  print('=== Circuit Breaker Pattern ===\n');

  final model = _FlakyLanguageModel(
    successText: 'Service recovered after the breaker half-open probe.',
    failuresBeforeSuccess: 2,
    failureFactory: () => const transport.TransportTimeoutException(
      'Primary model endpoint timed out',
    ),
  );

  final breaker = _CircuitBreaker(
    failureThreshold: 2,
    resetTimeout: const Duration(milliseconds: 120),
  );

  for (var callIndex = 1; callIndex <= 4; callIndex += 1) {
    if (callIndex == 4) {
      await Future<void>.delayed(const Duration(milliseconds: 160));
    }

    try {
      final result = await breaker.execute(
        () => core.generateTextCall(
          model: model,
          prompt: [
            core.UserPromptMessage.text('Ping the service.'),
          ],
        ),
      );
      print('Call $callIndex: success -> ${result.text}');
    } catch (error) {
      final normalized = _normalizeError(error);
      print(
        'Call $callIndex: ${normalized.code ?? normalized.kind.name} '
        '-> ${normalized.message}',
      );
    }
  }

  print('');
}

core.FunctionToolDefinition _weatherTool() {
  return core.FunctionToolDefinition(
    name: 'weather',
    description: 'Get weather for a city.',
    inputSchema: core.ToolJsonSchema.object(
      properties: const {
        'city': {'type': 'string'},
      },
      required: const ['city'],
      additionalProperties: false,
    ),
  );
}

core.ModelError _normalizeError(Object error) {
  if (error is core.ModelError) {
    return error;
  }

  if (error is transport.TransportException) {
    return transport.transportErrorToModelError(error);
  }

  return core.ModelError.fromUnknown(error);
}

void _printNormalizedError({
  required String label,
  required Object error,
}) {
  final normalized = _normalizeError(error);

  print(label);
  print('  kind: ${normalized.kind.name}');
  print('  message: ${normalized.message}');
  print('  code: ${normalized.code ?? '<none>'}');
  print('  statusCode: ${normalized.statusCode?.toString() ?? '<none>'}');
  print('  retryable: ${normalized.isRetryable?.toString() ?? '<unknown>'}');
  print('  originalType: ${normalized.originalType ?? '<none>'}\n');
}

final class IncidentPlan {
  final String summary;
  final List<String> actions;

  const IncidentPlan({
    required this.summary,
    required this.actions,
  });

  factory IncidentPlan.fromJson(Map<String, Object?> json) {
    final actions = json['actions'] as List;
    return IncidentPlan(
      summary: json['summary']! as String,
      actions: List<String>.unmodifiable(
        actions.map((value) => value as String),
      ),
    );
  }
}

final class _StaticTextLanguageModel implements core.LanguageModel {
  final String text;

  const _StaticTextLanguageModel(this.text);

  @override
  String get providerId => 'example';

  @override
  String get modelId => 'static-text';

  @override
  Future<core.GenerateTextResult> generate(core.GenerateTextRequest request) {
    return Future.value(
      core.GenerateTextResult(
        content: [
          core.TextContentPart(text),
        ],
        finishReason: core.FinishReason.stop,
      ),
    );
  }

  @override
  Stream<core.TextStreamEvent> stream(core.GenerateTextRequest request) {
    return const Stream.empty();
  }
}

final class _FlakyLanguageModel implements core.LanguageModel {
  final String successText;
  final int failuresBeforeSuccess;
  final Object Function() failureFactory;

  int _attempts = 0;

  _FlakyLanguageModel({
    required this.successText,
    required this.failuresBeforeSuccess,
    required this.failureFactory,
  });

  @override
  String get providerId => 'example';

  @override
  String get modelId => 'flaky-model';

  @override
  Future<core.GenerateTextResult> generate(core.GenerateTextRequest request) {
    _attempts += 1;
    if (_attempts <= failuresBeforeSuccess) {
      throw failureFactory();
    }

    return Future.value(
      core.GenerateTextResult(
        content: [
          core.TextContentPart(successText),
        ],
        finishReason: core.FinishReason.stop,
      ),
    );
  }

  @override
  Stream<core.TextStreamEvent> stream(core.GenerateTextRequest request) {
    return const Stream.empty();
  }
}

final class _RetryExecutor<T> {
  final int maxAttempts;
  final Duration baseDelay;

  const _RetryExecutor({
    required this.maxAttempts,
    this.baseDelay = const Duration(milliseconds: 100),
  });

  Future<T> execute(Future<T> Function() operation) async {
    if (maxAttempts < 1) {
      throw ArgumentError.value(
        maxAttempts,
        'maxAttempts',
        'Retry executor requires at least one attempt.',
      );
    }

    for (var attempt = 1; attempt <= maxAttempts; attempt += 1) {
      try {
        return await operation();
      } catch (error) {
        final normalized = _normalizeError(error);
        final shouldRetry =
            attempt < maxAttempts && (normalized.isRetryable ?? false);

        print(
          'Attempt $attempt failed: '
          '${normalized.code ?? normalized.kind.name} -> ${normalized.message}',
        );

        if (!shouldRetry) {
          rethrow;
        }

        final delay =
            Duration(milliseconds: baseDelay.inMilliseconds * attempt);
        print('Retrying in ${delay.inMilliseconds}ms...');
        await Future<void>.delayed(delay);
      }
    }

    throw StateError('Retry executor exited unexpectedly.');
  }
}

final class _FallbackOutcome<T> {
  final int stepIndex;
  final T value;

  const _FallbackOutcome({
    required this.stepIndex,
    required this.value,
  });
}

final class _FallbackExecutor<T> {
  Future<_FallbackOutcome<T>> execute(
    List<Future<T> Function()> operations,
  ) async {
    if (operations.isEmpty) {
      throw ArgumentError.value(
        operations,
        'operations',
        'Fallback executor requires at least one operation.',
      );
    }

    Object? lastError;
    StackTrace? lastStackTrace;

    for (var index = 0; index < operations.length; index += 1) {
      try {
        final value = await operations[index]();
        return _FallbackOutcome(
          stepIndex: index,
          value: value,
        );
      } catch (error, stackTrace) {
        final normalized = _normalizeError(error);
        print(
          'Fallback step ${index + 1} failed: '
          '${normalized.code ?? normalized.kind.name} -> ${normalized.message}',
        );
        lastError = error;
        lastStackTrace = stackTrace;
      }
    }

    Error.throwWithStackTrace(
      lastError ?? StateError('All fallback operations failed.'),
      lastStackTrace ?? StackTrace.current,
    );
  }
}

final class _CircuitBreaker {
  final int failureThreshold;
  final Duration resetTimeout;

  int _failureCount = 0;
  DateTime? _openedAt;

  _CircuitBreaker({
    required this.failureThreshold,
    required this.resetTimeout,
  });

  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_openedAt case final openedAt?) {
      final elapsed = DateTime.now().difference(openedAt);
      if (elapsed < resetTimeout) {
        throw core.ModelError(
          kind: core.ModelErrorKind.transport,
          message: 'Circuit breaker is open. Skip the call and use fallback UI.',
          code: 'circuit-open',
          isRetryable: false,
        );
      }

      _openedAt = null;
      _failureCount = 0;
    }

    try {
      final value = await operation();
      _failureCount = 0;
      return value;
    } catch (error) {
      _failureCount += 1;
      if (_failureCount >= failureThreshold) {
        _openedAt = DateTime.now();
      }
      rethrow;
    }
  }
}
