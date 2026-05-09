// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/transport.dart' as transport;

const _openAIBaseUrl = 'https://api.openai.com/v1';
const _modelId = 'gpt-4.1-mini';

/// Stable timeout layering examples.
///
/// The modern timeout story is split across two layers:
///
/// - transport defaults and connection/receive/send shaping on
///   `DioHttpClientConfig`
/// - per-request timeout overrides on `CallOptions`
///
/// This is cleaner than pushing all timeout policy through a provider builder.
Future<void> main() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Set OPENAI_API_KEY to run this example.');
    return;
  }

  print('Timeout Configuration Examples\n');

  await example1TransportTimeoutOnly(apiKey);
  await example2TransportSpecificTimeoutsOnly(apiKey);
  await example3TransportPlusPerCallOverride(apiKey);
  await example4EnterpriseScenario(apiKey);
  await example5DevelopmentScenario(apiKey);

  explainTimeoutPriority();
}

Future<void> example1TransportTimeoutOnly(String apiKey) async {
  print('=== Example 1: Transport Timeout Only ===');
  print('Setting: DioHttpClientConfig(timeout: 2 minutes)');
  print('Result: connection=2m, receive=2m, send=2m\n');

  final config = const transport.DioHttpClientConfig(
    baseUrl: _openAIBaseUrl,
    defaultHeaders: <String, String>{},
    timeout: Duration(minutes: 2),
  );

  try {
    final result = await _runPrompt(
      model: _openAIModel(apiKey, config),
      prompt: 'Respond briefly so the timeout baseline is exercised.',
    );
    print('Success: ${result.text}\n');
  } catch (error) {
    print('Error: $error\n');
  }
}

Future<void> example2TransportSpecificTimeoutsOnly(String apiKey) async {
  print('=== Example 2: Transport-Specific Timeouts ===');
  print('Setting: connection=30s, receive=5m, send=1m');
  print('Result: fine-grained timeout control at the transport layer\n');

  final config = const transport.DioHttpClientConfig(
    baseUrl: _openAIBaseUrl,
    defaultHeaders: <String, String>{},
    connectionTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(minutes: 5),
    sendTimeout: Duration(minutes: 1),
  );

  try {
    final result = await _runPrompt(
      model: _openAIModel(apiKey, config),
      prompt: 'Explain fine-grained timeout tuning in one sentence.',
    );
    print('Success: ${result.text}\n');
  } catch (error) {
    print('Error: $error\n');
  }
}

Future<void> example3TransportPlusPerCallOverride(String apiKey) async {
  print('=== Example 3: Transport Baseline + Per-Call Override ===');
  print('Setting: transport timeout=2m, connection=20s, receive=10m');
  print('Call override: CallOptions(timeout: 45s)');
  print('Result: connection=20s, receive=45s, send=45s\n');

  final config = const transport.DioHttpClientConfig(
    baseUrl: _openAIBaseUrl,
    defaultHeaders: <String, String>{},
    timeout: Duration(minutes: 2),
    connectionTimeout: Duration(seconds: 20),
    receiveTimeout: Duration(minutes: 10),
  );

  try {
    final result = await _runPrompt(
      model: _openAIModel(apiKey, config),
      prompt: 'Explain request-scoped timeout override behavior.',
      callOptions: const core.CallOptions(
        timeout: Duration(seconds: 45),
      ),
    );
    print('Success: ${result.text}\n');
  } catch (error) {
    print('Error: $error\n');
  }
}

Future<void> example4EnterpriseScenario(String apiKey) async {
  print('=== Example 4: Enterprise Scenario ===');
  print('Setting: conservative timeouts for slower networks');

  final proxyUrl = Platform.environment['HTTP_PROXY_URL'];
  if (proxyUrl case final value?) {
    print('Proxy configured through HTTP_PROXY_URL=$value');
  } else {
    print('No proxy configured; enterprise example still uses conservative timeouts');
  }
  print('');

  final config = transport.DioHttpClientConfig(
    baseUrl: _openAIBaseUrl,
    defaultHeaders: const <String, String>{},
    customHeaders: const <String, String>{
      'X-Corporate-ID': 'dept-ai-research',
      'X-Environment': 'production',
    },
    timeout: const Duration(minutes: 5),
    connectionTimeout: const Duration(minutes: 1),
    receiveTimeout: const Duration(minutes: 8),
    proxyUrl: proxyUrl,
  );

  try {
    final result = await _runPrompt(
      model: _openAIModel(apiKey, config),
      prompt: 'Summarize the latest AI trends for a quarterly report.',
    );
    print('Success: ${result.text}\n');
  } catch (error) {
    print('Error: $error\n');
  }
}

Future<void> example5DevelopmentScenario(String apiKey) async {
  print('=== Example 5: Development Scenario ===');
  print('Setting: fast failures plus transport logging');
  print('Result: quick feedback during local iteration\n');

  final config = const transport.DioHttpClientConfig(
    baseUrl: _openAIBaseUrl,
    defaultHeaders: <String, String>{},
    customHeaders: <String, String>{
      'X-Environment': 'development',
      'X-Debug-Mode': 'true',
    },
    timeout: Duration(seconds: 30),
    connectionTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 45),
    enableLogging: true,
  );

  try {
    final result = await _runPrompt(
      model: _openAIModel(apiKey, config),
      prompt: 'Return a short development test response.',
    );
    print('Success: ${result.text}\n');
  } catch (error) {
    print('Error: $error\n');
  }
}

void explainTimeoutPriority() {
  print('=== Timeout Priority Hierarchy ===');
  print('1. CallOptions.timeout');
  print('   Per-request send/receive override on the shared model call.');
  print('2. DioHttpClientConfig.connectionTimeout / receiveTimeout / sendTimeout');
  print('   Transport-level fine-grained defaults.');
  print('3. DioHttpClientConfig.timeout');
  print('   Transport-level fallback baseline for unspecified channels.');
  print('4. Transport defaults');
  print('   Package default when no timeout policy is supplied.\n');

  print('Best Practices:');
  print('  - keep connection timeout short for faster failure detection');
  print('  - allow longer receive timeouts for complex reasoning tasks');
  print('  - use CallOptions.timeout when a single request needs a different SLA');
  print('  - keep provider selection and timeout policy on separate layers');
}

core.LanguageModel _openAIModel(
  String apiKey,
  transport.DioHttpClientConfig config,
) {
  final dioClient = transport.DioHttpClientFactory.createConfiguredDio(
    config: config,
    logger: transport.Logger('timeout_configuration'),
  );

  return llm.openai(
    apiKey: apiKey,
    transport: transport.DioTransportClient(dio: dioClient),
  ).chatModel(_modelId);
}

Future<core.GenerateTextCallResult<void>> _runPrompt({
  required core.LanguageModel model,
  required String prompt,
  core.CallOptions callOptions = const core.CallOptions(),
}) {
  return core.generateTextCall<void>(
    model: model,
    prompt: [
      core.UserPromptMessage.text(prompt),
    ],
    callOptions: callOptions,
  );
}
