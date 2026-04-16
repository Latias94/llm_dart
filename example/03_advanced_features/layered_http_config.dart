// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/transport.dart' as transport;
import 'package:llm_dart_transport/dio.dart' as dio;

const _openAIBaseUrl = 'https://api.openai.com/v1';
const _anthropicBaseUrl = 'https://api.anthropic.com/v1';
const _deepSeekBaseUrl = 'https://api.deepseek.com/v1';

/// Layered transport configuration examples on the stable model facade.
///
/// The architecture boundary is:
///
/// - provider choice and model selection on `AI.*(...).chatModel(...)`
/// - HTTP wiring on `TransportClient`
/// - reusable transport presets on `DioHttpClientConfig`
/// - advanced custom transport control through an injected Dio instance
Future<void> main() async {
  print('Layered HTTP Configuration Demo\n');

  final apiKeys = {
    'openai': Platform.environment['OPENAI_API_KEY'],
    'anthropic': Platform.environment['ANTHROPIC_API_KEY'],
    'deepseek': Platform.environment['DEEPSEEK_API_KEY'],
  };

  final availableKeys = apiKeys.entries.where((entry) {
    final value = entry.value;
    return value != null && value.isNotEmpty;
  }).toList();

  if (availableKeys.isEmpty) {
    print('Set at least one API key:');
    print('  OPENAI_API_KEY');
    print('  ANTHROPIC_API_KEY');
    print('  DEEPSEEK_API_KEY');
    return;
  }

  print('Available providers:');
  for (final entry in availableKeys) {
    print('  ${entry.key}');
  }
  print('');

  if (apiKeys['openai'] case final openAIKey?) {
    await demonstrateBasicLayeredConfig(openAIKey);
  }

  if (apiKeys['anthropic'] case final anthropicKey?) {
    await demonstrateAdvancedLayeredConfig(anthropicKey);
    await demonstrateCustomDioClient(anthropicKey);
  }

  if (apiKeys['deepseek'] case final deepSeekKey?) {
    await demonstrateTimeoutPriorityInLayeredConfig(deepSeekKey);
  }

  demonstrateConfigReusability();

  print('Layered HTTP configuration demo completed.');
}

Future<void> demonstrateBasicLayeredConfig(String apiKey) async {
  print('=== Basic Layered Transport Configuration ===\n');

  final config = const transport.DioHttpClientConfig(
    baseUrl: _openAIBaseUrl,
    defaultHeaders: <String, String>{},
    customHeaders: <String, String>{
      'X-Request-ID': 'layered-demo-001',
    },
    connectionTimeout: Duration(seconds: 30),
    enableLogging: true,
  );

  try {
    final result = await _runPrompt(
      model: llm.AI.openai(
        apiKey: apiKey,
        transport: _transportFromConfig(
          config,
          loggerName: 'layered_http.openai',
        ),
      ).chatModel('gpt-4.1-mini'),
      prompt: 'Explain why transport settings belong below provider selection.',
    );

    print('Applied reusable typed transport settings to OpenAI.');
    print('Response: ${result.text}\n');
  } catch (error) {
    print('Basic layered configuration failed: $error\n');
  }
}

Future<void> demonstrateAdvancedLayeredConfig(String apiKey) async {
  print('=== Advanced Layered Transport Configuration ===\n');

  final config = const transport.DioHttpClientConfig(
    baseUrl: _anthropicBaseUrl,
    defaultHeaders: <String, String>{},
    customHeaders: <String, String>{
      'X-Request-ID': 'advanced-layered-demo-002',
      'X-Client-Version': '2.0.0',
      'X-Environment': 'production',
      'X-Additional-Header': 'dynamic-value',
    },
    connectionTimeout: Duration(seconds: 20),
    receiveTimeout: Duration(minutes: 5),
    sendTimeout: Duration(seconds: 45),
    enableLogging: true,
  );

  try {
    final result = await _runPrompt(
      model: llm.AI.anthropic(
        apiKey: apiKey,
        transport: _transportFromConfig(
          config,
          loggerName: 'layered_http.anthropic',
        ),
      ).chatModel('claude-3-5-haiku-20241022'),
      prompt:
          'Describe a production-grade transport profile in one compact paragraph.',
    );

    print('Applied advanced headers and timeout shaping to Anthropic.');
    print('Response: ${result.text}\n');
  } catch (error) {
    print('Advanced layered configuration failed: $error\n');
  }
}

Future<void> demonstrateCustomDioClient(String apiKey) async {
  print('=== Custom Dio Client ===\n');

  try {
    final customDio = dio.Dio();

    customDio.options.connectTimeout = const Duration(seconds: 20);
    customDio.options.receiveTimeout = const Duration(minutes: 3);
    customDio.options.sendTimeout = const Duration(seconds: 30);
    customDio.options.headers.addAll({
      'X-Custom-Client': 'llm_dart-advanced',
      'X-Client-Version': '2.0.0',
      'X-Request-Source': 'custom-dio-demo',
    });

    customDio.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (options, handler) {
          final requestId = 'req-${DateTime.now().millisecondsSinceEpoch}';
          options.headers['X-Request-ID'] = requestId;
          print('Starting request: $requestId to ${options.uri.host}');
          options.extra['startTime'] = DateTime.now();
          handler.next(options);
        },
        onResponse: (response, handler) {
          final startTime = response.requestOptions.extra['startTime']
              as DateTime?;
          if (startTime != null) {
            final duration = DateTime.now().difference(startTime);
            print('Completed in ${duration.inMilliseconds}ms');
          }
          handler.next(response);
        },
        onError: (error, handler) {
          final startTime =
              error.requestOptions.extra['startTime'] as DateTime?;
          if (startTime != null) {
            final duration = DateTime.now().difference(startTime);
            print('Failed after ${duration.inMilliseconds}ms');
          }
          handler.next(error);
        },
      ),
    );

    customDio.interceptors.add(
      dio.InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode == 429) {
            print('Rate limited, applying demo backoff...');
            await Future<void>.delayed(const Duration(seconds: 1));
          }
          handler.next(error);
        },
      ),
    );

    final model = llm.AI.anthropic(
      apiKey: apiKey,
      transport: transport.DioTransportClient(dio: customDio),
    ).chatModel('claude-3-5-haiku-20241022');

    final result = await _runPrompt(
      model: model,
      prompt:
          'Summarize the advantages of injecting a custom transport client.',
    );

    print('Custom Dio injection succeeded on the stable Anthropic facade.');
    print('Response: ${result.text}\n');
  } catch (error) {
    print('Custom Dio client demo failed: $error\n');
  }
}

Future<void> demonstrateTimeoutPriorityInLayeredConfig(String apiKey) async {
  print('=== Timeout Priority In Layered Transport Configuration ===\n');

  final config = const transport.DioHttpClientConfig(
    baseUrl: _deepSeekBaseUrl,
    defaultHeaders: <String, String>{},
    customHeaders: <String, String>{
      'X-Timeout-Demo': 'priority-example',
    },
    timeout: Duration(minutes: 2),
    connectionTimeout: Duration(seconds: 15),
    receiveTimeout: Duration(minutes: 5),
  );

  final model = llm.AI.deepSeek(
    apiKey: apiKey,
    transport: _transportFromConfig(
      config,
      loggerName: 'layered_http.deepseek',
    ),
  ).chatModel('deepseek-chat');

  try {
    final baselineResult = await _runPrompt(
      model: model,
      prompt: 'Describe the baseline transport timeout profile in one line.',
    );

    print('Transport baseline: connection=15s, receive=5m, send=2m.');
    print('Response: ${baselineResult.text}\n');
  } catch (error) {
    print('Transport baseline timeout demo failed: $error\n');
  }

  try {
    final perCallResult = await _runPrompt(
      model: model,
      prompt:
          'Describe how a single request can override send and receive timeout.',
      callOptions: const core.CallOptions(
        timeout: Duration(seconds: 45),
      ),
    );

    print('Per-call override: send=45s, receive=45s, connection stays 15s.');
    print('Priority: CallOptions.timeout > transport receive/send > defaults.');
    print('Response: ${perCallResult.text}\n');
  } catch (error) {
    print('Per-call timeout override demo failed: $error\n');
  }
}

void demonstrateConfigReusability() {
  print('=== Transport Configuration Reusability ===\n');

  transport.DioHttpClientConfig createProductionConfig(String baseUrl) {
    return transport.DioHttpClientConfig(
      baseUrl: baseUrl,
      defaultHeaders: const <String, String>{},
      customHeaders: const <String, String>{
        'X-Environment': 'production',
        'X-Client-Version': '1.0.0',
        'X-Request-Source': 'mobile-app',
      },
      connectionTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 3),
    );
  }

  transport.DioHttpClientConfig createDevelopmentConfig(String baseUrl) {
    return transport.DioHttpClientConfig(
      baseUrl: baseUrl,
      defaultHeaders: const <String, String>{},
      customHeaders: const <String, String>{
        'X-Environment': 'development',
        'X-Debug-Mode': 'true',
      },
      connectionTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      enableLogging: true,
      bypassSslVerification: true,
    );
  }

  dio.Dio createProductionDio() {
    final client = dio.Dio();
    client.options.connectTimeout = const Duration(seconds: 30);
    client.options.receiveTimeout = const Duration(minutes: 5);
    client.options.headers.addAll({
      'User-Agent': 'LLMDart-Production/1.0',
      'X-Environment': 'production',
    });
    return client;
  }

  dio.Dio createDevelopmentDio() {
    final client = dio.Dio();
    client.options.connectTimeout = const Duration(seconds: 10);
    client.options.receiveTimeout = const Duration(seconds: 30);
    client.options.headers.addAll({
      'User-Agent': 'LLMDart-Development/1.0',
      'X-Environment': 'development',
      'X-Debug': 'true',
    });
    client.interceptors.add(
      dio.LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (message) => print('DEV HTTP: $message'),
      ),
    );
    return client;
  }

  final productionConfig = createProductionConfig(_openAIBaseUrl);
  final developmentConfig = createDevelopmentConfig(_openAIBaseUrl);

  print('Reusable DioHttpClientConfig factories:');
  print(
    '  production -> connect=${productionConfig.connectionTimeout}, '
    'receive=${productionConfig.receiveTimeout}, '
    'logging=${productionConfig.enableLogging}',
  );
  print(
    '  development -> connect=${developmentConfig.connectionTimeout}, '
    'receive=${developmentConfig.receiveTimeout}, '
    'logging=${developmentConfig.enableLogging}, '
    'bypassSsl=${developmentConfig.bypassSslVerification}',
  );
  print('');

  final productionDio = createProductionDio();
  final developmentDio = createDevelopmentDio();

  print('Reusable custom Dio factories:');
  print(
    '  production headers -> ${productionDio.options.headers.keys.join(', ')}',
  );
  print(
    '  development headers -> ${developmentDio.options.headers.keys.join(', ')}',
  );
  print(
    'Inject with AI.*(..., transport: DioTransportClient(dio: createProductionDio())).\n',
  );
}

transport.TransportClient _transportFromConfig(
  transport.DioHttpClientConfig config, {
  required String loggerName,
}) {
  final dioClient = transport.DioHttpClientFactory.createConfiguredDio(
    config: config,
    logger: transport.Logger(loggerName),
  );
  return transport.DioTransportClient(dio: dioClient);
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
