// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

/// Custom language-model examples built on the stable `LanguageModel` contract.
///
/// This example demonstrates:
/// - implementing `LanguageModel` directly instead of the old `ChatCapability`
/// - composing wrappers for logging and caching
/// - simulating proprietary backends behind the shared text-call contract
/// - keeping app/runtime code on `generateTextCall(...)` and `streamTextCall(...)`
Future<void> main() async {
  print('Stable custom language-model examples\n');

  await _demonstrateMockModel();
  await _demonstrateLoggingWrapper();
  await _demonstrateCachingWrapper();
  await _demonstrateCustomApiModel();
  await _demonstrateModelChaining();

  print('Completed stable custom model examples.');
  print('Implement shared model contracts for app/runtime integration.');
  print('Keep provider-owned transport details behind the model boundary.');
}

Future<void> _demonstrateMockModel() async {
  print('Mock model for testing:');

  final model = MockLanguageModel();

  try {
    final result = await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text('Hello, how are you?'),
      ],
    );

    print('  User: Hello, how are you?');
    print('  Mock model: ${result.text}');

    print('  Streaming test:');
    final stream = core.streamTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text('Count to five'),
      ],
    );

    stdout.write('  Stream: ');
    await for (final event in stream) {
      switch (event) {
        case core.TextDeltaEvent(:final delta):
          stdout.write(delta);
        case core.FinishEvent():
          stdout.writeln();
        default:
          break;
      }
    }
  } catch (error) {
    print('  Failed: $error');
  }

  print('');
}

Future<void> _demonstrateLoggingWrapper() async {
  print('Logging wrapper:');

  final model = LoggingLanguageModel(
    MockLanguageModel(),
    logSink: stdout.writeln,
  );

  try {
    final result = await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text('What is artificial intelligence?'),
      ],
      options: const core.GenerateTextOptions(
        maxOutputTokens: 120,
      ),
    );

    print('  Final answer: ${result.text}');
  } catch (error) {
    print('  Failed: $error');
  }

  print('');
}

Future<void> _demonstrateCachingWrapper() async {
  print('Caching wrapper:');

  final model = CachingLanguageModel(
    MockLanguageModel(),
    logSink: stdout.writeln,
  );
  const prompt = 'What is the capital of France?';

  try {
    final first = await _runTextCall(
      model: model,
      prompt: prompt,
    );
    print('  First call: ${first.text} (${first.duration.inMilliseconds}ms)');

    final second = await _runTextCall(
      model: model,
      prompt: prompt,
    );
    print(
        '  Second call: ${second.text} (${second.duration.inMilliseconds}ms)');

    final stream = core.streamTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text(prompt),
      ],
    );

    stdout.write('  Cached stream: ');
    await for (final event in stream) {
      switch (event) {
        case core.TextDeltaEvent(:final delta):
          stdout.write(delta);
        case core.FinishEvent():
          stdout.writeln();
        default:
          break;
      }
    }
  } catch (error) {
    print('  Failed: $error');
  }

  print('');
}

Future<void> _demonstrateCustomApiModel() async {
  print('Custom API model:');

  final model = CustomApiLanguageModel(
    baseUrl: 'https://api.example.com',
    apiKey: 'custom-api-key',
    modelId: 'custom-model-v1',
  );

  try {
    final result = await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text('Hello from a proprietary backend!'),
      ],
      options: const core.GenerateTextOptions(
        temperature: 0.2,
        maxOutputTokens: 100,
      ),
    );

    print('  Response: ${result.text}');
    print('  Reported model id: ${result.responseModelId ?? model.modelId}');
  } catch (error) {
    print('  Failed: $error');
  }

  print('');
}

Future<void> _demonstrateModelChaining() async {
  print('Model chaining:');

  final chainedModel = LoggingLanguageModel(
    CachingLanguageModel(
      CustomApiLanguageModel(
        baseUrl: 'https://api.example.com',
        apiKey: 'custom-api-key',
        modelId: 'custom-model-v2',
      ),
      logSink: stdout.writeln,
    ),
    logSink: stdout.writeln,
  );

  try {
    final first = await _runTextCall(
      model: chainedModel,
      prompt: 'Summarize why composable wrappers matter.',
    );
    print('  First chained response: ${first.text}');

    final second = await _runTextCall(
      model: chainedModel,
      prompt: 'Summarize why composable wrappers matter.',
    );
    print('  Second chained response: ${second.text}');
  } catch (error) {
    print('  Failed: $error');
  }

  print('');
}

Future<_RunResult> _runTextCall({
  required core.LanguageModel model,
  required String prompt,
  core.GenerateTextOptions options = const core.GenerateTextOptions(),
}) async {
  final stopwatch = Stopwatch()..start();
  final result = await core.generateTextCall(
    model: model,
    prompt: [
      core.UserPromptMessage.text(prompt),
    ],
    options: options,
  );
  stopwatch.stop();

  return _RunResult(
    text: result.text,
    duration: stopwatch.elapsed,
  );
}

final class MockLanguageModel implements core.LanguageModel {
  @override
  String get providerId => 'mock';

  @override
  String get modelId => 'mock-chat-model';

  @override
  Future<core.GenerateTextResult> doGenerate(
    core.GenerateTextRequest request,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final text = _responseForPrompt(_promptText(request.prompt));

    return core.GenerateTextResult(
      content: [
        core.TextContentPart(text),
      ],
      finishReason: core.FinishReason.stop,
      responseModelId: modelId,
      usage: core.UsageStats(
        inputTokens: 24,
        outputTokens: text.length ~/ 4,
        totalTokens: 24 + text.length ~/ 4,
      ),
    );
  }

  @override
  Stream<provider.LanguageModelStreamEvent> doStream(
    core.GenerateTextRequest request,
  ) async* {
    final text = _responseForPrompt(_promptText(request.prompt));
    yield provider.StartEvent();
    yield const provider.TextStartEvent(id: 'text-1');

    for (final token in text.split(' ')) {
      await Future<void>.delayed(const Duration(milliseconds: 35));
      yield provider.TextDeltaEvent(
        id: 'text-1',
        delta: '$token ',
      );
    }

    yield const provider.TextEndEvent(id: 'text-1');
    yield provider.FinishEvent(
      finishReason: core.FinishReason.stop,
      usage: core.UsageStats(
        inputTokens: 24,
        outputTokens: text.length ~/ 4,
        totalTokens: 24 + text.length ~/ 4,
      ),
    );
  }
}

final class LoggingLanguageModel implements core.LanguageModel {
  final core.LanguageModel _baseModel;
  final void Function(String message) _logSink;

  LoggingLanguageModel(
    this._baseModel, {
    required void Function(String message) logSink,
  }) : _logSink = logSink;

  @override
  String get providerId => _baseModel.providerId;

  @override
  String get modelId => _baseModel.modelId;

  @override
  Future<core.GenerateTextResult> doGenerate(
    core.GenerateTextRequest request,
  ) async {
    final stopwatch = Stopwatch()..start();
    _logSink(
      '  [log] generate start '
      'provider=$providerId model=$modelId prompt="${_promptText(request.prompt)}"',
    );

    try {
      final result = await _baseModel.doGenerate(request);
      stopwatch.stop();
      _logSink(
        '  [log] generate done ${stopwatch.elapsedMilliseconds}ms '
        'tokens=${result.usage?.totalTokens ?? 'unknown'}',
      );
      return result;
    } catch (error) {
      stopwatch.stop();
      _logSink(
        '  [log] generate failed ${stopwatch.elapsedMilliseconds}ms error=$error',
      );
      rethrow;
    }
  }

  @override
  Stream<provider.LanguageModelStreamEvent> doStream(
    core.GenerateTextRequest request,
  ) async* {
    _logSink('  [log] stream start provider=$providerId model=$modelId');

    await for (final event in _baseModel.doStream(request)) {
      switch (event) {
        case provider.TextDeltaEvent():
          _logSink('  [log] stream text delta');
        case provider.FinishEvent(:final usage):
          _logSink(
            '  [log] stream finish tokens=${usage?.totalTokens ?? 'unknown'}',
          );
        default:
          break;
      }
      yield event;
    }
  }
}

final class CachingLanguageModel implements core.LanguageModel {
  final core.LanguageModel _baseModel;
  final void Function(String message)? _logSink;
  final Map<String, core.GenerateTextResult> _cache =
      <String, core.GenerateTextResult>{};

  CachingLanguageModel(
    this._baseModel, {
    void Function(String message)? logSink,
  }) : _logSink = logSink;

  @override
  String get providerId => _baseModel.providerId;

  @override
  String get modelId => _baseModel.modelId;

  @override
  Future<core.GenerateTextResult> doGenerate(
    core.GenerateTextRequest request,
  ) async {
    final cacheKey = _cacheKey(request);
    final cached = _cache[cacheKey];
    if (cached != null) {
      _logSink?.call('  [cache] hit for "$cacheKey"');
      return cached;
    }

    _logSink?.call('  [cache] miss for "$cacheKey"');
    final result = await _baseModel.doGenerate(request);
    _cache[cacheKey] = result;
    return result;
  }

  @override
  Stream<provider.LanguageModelStreamEvent> doStream(
    core.GenerateTextRequest request,
  ) async* {
    final cacheKey = _cacheKey(request);
    final cached = _cache[cacheKey];
    if (cached != null) {
      _logSink?.call('  [cache] stream replay for "$cacheKey"');
      yield provider.StartEvent();
      yield const provider.TextStartEvent(id: 'cached-text');
      yield provider.TextDeltaEvent(
        id: 'cached-text',
        delta: cached.text,
      );
      yield const provider.TextEndEvent(id: 'cached-text');
      yield provider.FinishEvent(
        finishReason: cached.finishReason,
        rawFinishReason: cached.rawFinishReason,
        usage: cached.usage,
        providerMetadata: cached.providerMetadata,
      );
      return;
    }

    yield* _baseModel.doStream(request);
  }

  String _cacheKey(core.GenerateTextRequest request) {
    return [
      for (final message in request.prompt)
        '${message.role.name}:${_messageText(message)}',
      'max=${request.options.maxOutputTokens}',
      'temp=${request.options.temperature}',
    ].join('|');
  }
}

final class CustomApiLanguageModel implements core.LanguageModel {
  final String baseUrl;
  final String apiKey;
  @override
  final String modelId;

  CustomApiLanguageModel({
    required this.baseUrl,
    required this.apiKey,
    required this.modelId,
  });

  @override
  String get providerId => 'custom-api';

  @override
  Future<core.GenerateTextResult> doGenerate(
    core.GenerateTextRequest request,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final prompt = _promptText(request.prompt);
    final text =
        'Custom backend at $baseUrl handled "$prompt" with model $modelId.';

    return core.GenerateTextResult(
      content: [
        core.TextContentPart(text),
      ],
      finishReason: core.FinishReason.stop,
      responseModelId: modelId,
      usage: core.UsageStats(
        inputTokens: 36,
        outputTokens: text.length ~/ 4,
        totalTokens: 36 + text.length ~/ 4,
      ),
    );
  }

  @override
  Stream<provider.LanguageModelStreamEvent> doStream(
    core.GenerateTextRequest request,
  ) async* {
    final result = await doGenerate(request);
    yield provider.StartEvent();
    yield const provider.TextStartEvent(id: 'custom-text');
    yield provider.TextDeltaEvent(
      id: 'custom-text',
      delta: result.text,
    );
    yield const provider.TextEndEvent(id: 'custom-text');
    yield provider.FinishEvent(
      finishReason: result.finishReason,
      usage: result.usage,
    );
  }
}

String _promptText(List<core.PromptMessage> prompt) {
  return prompt.map(_messageText).join('\n');
}

String _messageText(core.PromptMessage message) {
  return message.parts.map((part) {
    return switch (part) {
      core.TextPromptPart(:final text) => text,
      core.ImagePromptPart(:final uri, :final mediaType) =>
        '[image ${uri ?? mediaType}]',
      core.FilePromptPart(:final filename, :final mediaType) =>
        '[file ${filename ?? mediaType}]',
      core.ReasoningPromptPart(:final text) => '[reasoning $text]',
      core.ReasoningFilePromptPart(:final filename, :final mediaType) =>
        '[reasoning-file ${filename ?? mediaType}]',
      core.ToolCallPromptPart(:final toolName) => '[tool-call $toolName]',
      core.ToolResultPromptPart(:final toolName) => '[tool-result $toolName]',
      core.ToolApprovalRequestPromptPart(:final toolCallId) =>
        '[approval-request $toolCallId]',
      core.ToolApprovalResponsePromptPart(:final toolCallId, :final approved) =>
        '[approval-response $toolCallId:$approved]',
      core.CustomPromptPart(:final kind) => '[custom $kind]',
    };
  }).join(' ');
}

String _responseForPrompt(String prompt) {
  final normalized = prompt.toLowerCase();
  if (normalized.contains('count to five')) {
    return 'One two three four five.';
  }
  if (normalized.contains('artificial intelligence')) {
    return 'Artificial intelligence is software that performs tasks normally associated with human reasoning and pattern recognition.';
  }
  if (normalized.contains('capital of france')) {
    return 'Paris is the capital of France.';
  }

  return 'Mock model response for: $prompt';
}

final class _RunResult {
  final String text;
  final Duration duration;

  const _RunResult({
    required this.text,
    required this.duration,
  });
}
