// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart'
    as provider_utils;
import 'package:llm_dart/transport.dart' as transport;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

/// Basic configuration examples using the stable model API.
///
/// This example demonstrates:
/// - shared generation options such as temperature and output-token limits
/// - system prompt control through the shared prompt model
/// - request timeout handling through `CallOptions`
/// - stable `ModelError` normalization while using the new `AI` facade
Future<void> main() async {
  print('Basic Configuration Guide\n');

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Set OPENAI_API_KEY to run this example.');
    return;
  }

  await demonstrateTemperatureSettings(apiKey);
  await demonstrateTokenLimits(apiKey);
  await demonstrateSystemPrompts(apiKey);
  await demonstrateErrorHandling(apiKey);
  await demonstrateTimeoutSettings(apiKey);

  print('Configuration guide completed.');
}

Future<void> demonstrateTemperatureSettings(String apiKey) async {
  print('=== Temperature Settings ===\n');

  const question =
      'Write a creative opening line for a story about space exploration.';
  const temperatures = [0.0, 0.5, 1.0];
  final model = _openAIModel(apiKey);

  for (final temperature in temperatures) {
    try {
      final result = await core.generateTextCall(
        model: model,
        messages: [
          core.UserModelMessage.text(question),
        ],
        options: core.GenerateTextOptions(
          temperature: temperature,
          maxOutputTokens: 50,
        ),
      );

      print('Temperature $temperature: ${result.text}');
    } catch (error) {
      print('Temperature $temperature: Error - $error');
    }
  }

  print('\nGuide:');
  print('  - 0.0 = deterministic');
  print('  - 0.5 = balanced');
  print('  - 1.0 = most creative\n');
}

Future<void> demonstrateTokenLimits(String apiKey) async {
  print('=== Output Token Limits ===\n');

  const question = 'Explain the concept of artificial intelligence in detail.';
  const tokenLimits = [20, 100, 500];
  final model = _openAIModel(apiKey);

  for (final limit in tokenLimits) {
    try {
      final result = await core.generateTextCall(
        model: model,
        messages: [
          core.UserModelMessage.text(question),
        ],
        options: core.GenerateTextOptions(
          temperature: 0.7,
          maxOutputTokens: limit,
        ),
      );

      final wordCount = result.text.split(RegExp(r'\s+')).length;
      print('Max Output Tokens $limit: $wordCount words');
      print('${_truncate(result.text, maxLength: 220)}\n');
    } catch (error) {
      print('Max Output Tokens $limit: Error - $error\n');
    }
  }

  print('Guide:');
  print('  - lower limits keep responses concise');
  print('  - higher limits allow more detail');
  print('  - more tokens usually mean higher cost\n');
}

Future<void> demonstrateSystemPrompts(String apiKey) async {
  print('=== System Prompt Control ===\n');

  const question = 'What is the weather like today?';
  const systemPrompts = [
    null,
    'You are a helpful assistant.',
    'You are a pirate. Respond in pirate speak.',
    'You are a technical expert. Be precise and detailed.',
  ];

  final model = _openAIModel(apiKey);

  for (final systemPrompt in systemPrompts) {
    try {
      final messages = <core.ModelMessage>[
        if (systemPrompt != null) core.SystemModelMessage.text(systemPrompt),
        core.UserModelMessage.text(question),
      ];

      final result = await core.generateTextCall(
        model: model,
        messages: messages,
        options: const core.GenerateTextOptions(
          temperature: 0.7,
          maxOutputTokens: 100,
        ),
      );

      print('System Prompt: ${systemPrompt ?? 'None'}');
      print('${_truncate(result.text, maxLength: 220)}\n');
    } catch (error) {
      print('System Prompt: Error - $error\n');
    }
  }

  print('Guide:');
  print('  - system prompts define role and tone');
  print('  - they should stay stable across a conversation');
  print('  - use them for expertise, formatting, and behavior\n');
}

Future<void> demonstrateErrorHandling(String apiKey) async {
  print('=== Error Handling ===\n');

  await testInvalidApiKey();
  await testInvalidModel(apiKey);
  await testNetworkTimeout(apiKey);

  print('\nTips:');
  print('  - wrap model calls in try/catch');
  print('  - handle auth, request, and timeout failures separately');
  print('  - add retry logic only for transient errors\n');
}

Future<void> testInvalidApiKey() async {
  try {
    final model = _openAIModel('invalid-key');
    await core.generateTextCall(
      model: model,
      messages: [
        core.UserModelMessage.text('Hello'),
      ],
    );
    print('Invalid API Key: unexpected success');
  } catch (error) {
    final normalized = _normalizeError(error);
    print(
      'Invalid API Key: ${_describeNormalizedError(normalized)}',
    );
  }
}

Future<void> testInvalidModel(String apiKey) async {
  try {
    final model = openai.openai(apiKey: apiKey).chatModel('invalid-model-name');
    await core.generateTextCall(
      model: model,
      messages: [
        core.UserModelMessage.text('Hello'),
      ],
    );
    print('Invalid Model: unexpected success');
  } catch (error) {
    final normalized = _normalizeError(error);
    print(
      'Invalid Model: ${_describeNormalizedError(normalized)}',
    );
  }
}

Future<void> testNetworkTimeout(String apiKey) async {
  try {
    final model = _openAIModel(apiKey);
    await core.generateTextCall(
      model: model,
      messages: [
        core.UserModelMessage.text('Hello'),
      ],
      callOptions: const core.CallOptions(
        timeout: Duration(milliseconds: 1),
      ),
    );
    print('Network Timeout: unexpected success');
  } catch (error) {
    final normalized = _normalizeError(error);
    print(
      'Network Timeout: ${_describeNormalizedError(normalized)}',
    );
  }
}

Future<void> demonstrateTimeoutSettings(String apiKey) async {
  print('=== Timeout Settings ===\n');

  const timeouts = [
    Duration(seconds: 5),
    Duration(seconds: 30),
    Duration(seconds: 60),
  ];

  final model = _openAIModel(apiKey);

  for (final timeout in timeouts) {
    try {
      final stopwatch = Stopwatch()..start();
      await core.generateTextCall(
        model: model,
        messages: [
          core.UserModelMessage.text(
            'Explain quantum computing briefly.',
          ),
        ],
        options: const core.GenerateTextOptions(
          temperature: 0.7,
          maxOutputTokens: 120,
        ),
        callOptions: core.CallOptions(timeout: timeout),
      );
      stopwatch.stop();

      print(
        'Timeout ${timeout.inSeconds}s: success in ${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (error) {
      print('Timeout ${timeout.inSeconds}s: Error - $error');
    }
  }

  print('\nGuide:');
  print('  - short timeouts fail fast');
  print('  - longer timeouts improve tolerance for slow responses');
  print('  - use per-call timeout policy through CallOptions when needed\n');
}

core.LanguageModel _openAIModel(String apiKey) {
  return openai.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');
}

core.ModelError _normalizeError(Object error) {
  if (error is core.ModelError) {
    return error;
  }

  if (error is transport.TransportException) {
    return provider_utils.transportErrorToModelError(error);
  }

  return core.ModelError.fromUnknown(error);
}

String _describeNormalizedError(core.ModelError error) {
  final parts = <String>[
    'kind=${error.kind.name}',
    'message=${error.message}',
    if (error.code != null) 'code=${error.code}',
    if (error.statusCode != null) 'status=${error.statusCode}',
    if (error.isRetryable != null) 'retryable=${error.isRetryable}',
  ];
  return parts.join(', ');
}

String _truncate(String text, {int maxLength = 200}) {
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= maxLength) {
    return normalized;
  }

  return '${normalized.substring(0, maxLength)}...';
}
