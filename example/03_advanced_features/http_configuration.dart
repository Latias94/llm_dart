// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/transport.dart' as transport;

const _openAIBaseUrl = 'https://api.openai.com/v1';
const _modelId = 'gpt-4.1-mini';

/// Stable transport configuration examples.
///
/// This example keeps provider selection on the stable `openai(...)`
/// surface and moves HTTP concerns into the transport layer:
///
/// - `DioHttpClientConfig` for typed transport settings
/// - `DioHttpClientFactory` for reusable configured Dio instances
/// - `DioTransportClient` for injection into provider facades
///
/// IO-only features such as proxy and custom certificate handling remain
/// transport-owned and platform-dependent.
Future<void> main() async {
  _configureLogging();

  print('HTTP Configuration Demo\n');

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Set OPENAI_API_KEY to run this example.');
    print('Optional transport env vars:');
    print('  HTTP_PROXY_URL=http://proxy.company.com:8080');
    print('  ALLOW_INSECURE_SSL=true');
    print('  CUSTOM_CA_CERT_PATH=/path/to/certificate.pem');
    return;
  }

  await demonstrateBasicTransportConfig(apiKey);
  await demonstrateProxyConfiguration(apiKey);
  await demonstrateSslConfiguration(apiKey);
  await demonstrateCustomHeaders(apiKey);
  await demonstrateTimeoutBaseline(apiKey);
  await demonstrateLoggingConfiguration(apiKey);
  await demonstrateComprehensiveConfiguration(apiKey);
  await demonstrateRequestHooksAndDiagnostics(apiKey);

  print('HTTP configuration demo completed.');
}

Future<void> demonstrateBasicTransportConfig(String apiKey) async {
  print('=== Basic Transport Configuration ===\n');

  final config = const transport.DioHttpClientConfig(
    baseUrl: _openAIBaseUrl,
    defaultHeaders: <String, String>{},
    timeout: Duration(seconds: 30),
  );

  try {
    final result = await _runPrompt(
      model: _openAIModel(
        apiKey,
        transportClient: _transportFromConfig(
          config,
          loggerName: 'http_configuration.basic',
        ),
      ),
      prompt: 'Hello from a transport-configured OpenAI model.',
    );

    print('Configured a 30s transport baseline timeout.');
    print('Response: ${result.text}\n');
  } catch (error) {
    print('Basic transport configuration failed: $error\n');
  }
}

Future<void> demonstrateProxyConfiguration(String apiKey) async {
  print('=== Proxy Configuration ===\n');
  print(
    'Proxy support is transport-owned and only meaningful on IO platforms.',
  );

  final proxyUrl = Platform.environment['HTTP_PROXY_URL'];
  if (proxyUrl == null || proxyUrl.isEmpty) {
    print('Set HTTP_PROXY_URL to execute a live proxy request.');
    print('The example still shows the typed transport recipe.\n');
    return;
  }

  final config = transport.DioHttpClientConfig(
    baseUrl: _openAIBaseUrl,
    defaultHeaders: const <String, String>{},
    timeout: const Duration(seconds: 45),
    proxyUrl: proxyUrl,
  );

  transport.DioHttpClientFactory.validateHttpConfig(
    config,
    logger: transport.Logger('http_configuration.proxy.validation'),
  );

  try {
    final result = await _runPrompt(
      model: _openAIModel(
        apiKey,
        transportClient: _transportFromConfig(
          config,
          loggerName: 'http_configuration.proxy',
        ),
      ),
      prompt: 'Respond with one short sentence through the configured proxy.',
    );

    print('Proxy request succeeded with HTTP_PROXY_URL=$proxyUrl');
    print('Response: ${result.text}\n');
  } catch (error) {
    print('Proxy request failed: $error\n');
  }
}

Future<void> demonstrateSslConfiguration(String apiKey) async {
  print('=== SSL Configuration ===\n');
  print(
    'SSL bypass and custom certificates are transport-owned IO details.',
  );

  final allowInsecureSsl =
      Platform.environment['ALLOW_INSECURE_SSL']?.toLowerCase() == 'true';
  final certificatePath = Platform.environment['CUSTOM_CA_CERT_PATH'];

  if (!allowInsecureSsl &&
      (certificatePath == null || certificatePath.isEmpty)) {
    print(
        'Set ALLOW_INSECURE_SSL=true or CUSTOM_CA_CERT_PATH to run this demo.');
    print('No live SSL override was requested.\n');
    return;
  }

  final config = transport.DioHttpClientConfig(
    baseUrl: _openAIBaseUrl,
    defaultHeaders: const <String, String>{},
    timeout: const Duration(seconds: 45),
    bypassSslVerification: allowInsecureSsl,
    certificatePath: certificatePath,
  );

  transport.DioHttpClientFactory.validateHttpConfig(
    config,
    logger: transport.Logger('http_configuration.ssl.validation'),
  );

  try {
    final result = await _runPrompt(
      model: _openAIModel(
        apiKey,
        transportClient: _transportFromConfig(
          config,
          loggerName: 'http_configuration.ssl',
        ),
      ),
      prompt: 'Confirm that the SSL transport override path is active.',
    );

    print(
      'SSL override request succeeded '
      '(bypass=$allowInsecureSsl, certificatePath=${certificatePath ?? 'none'}).',
    );
    print('Response: ${result.text}\n');
  } catch (error) {
    print('SSL override request failed: $error\n');
  }
}

Future<void> demonstrateCustomHeaders(String apiKey) async {
  print('=== Custom Headers ===\n');

  final config = const transport.DioHttpClientConfig(
    baseUrl: _openAIBaseUrl,
    defaultHeaders: <String, String>{},
    customHeaders: <String, String>{
      'X-Request-ID': 'advanced-http-demo-123',
      'X-Client-Version': '1.0.0',
      'User-Agent': 'llm_dart-http-demo/1.0',
    },
    timeout: Duration(seconds: 30),
  );

  try {
    final result = await _runPrompt(
      model: _openAIModel(
        apiKey,
        transportClient: _transportFromConfig(
          config,
          loggerName: 'http_configuration.headers',
        ),
      ),
      prompt: 'A request with custom transport headers is reaching the model.',
    );

    print('Custom transport headers applied successfully.');
    print('Response: ${result.text}\n');
  } catch (error) {
    print('Custom headers configuration failed: $error\n');
  }
}

Future<void> demonstrateTimeoutBaseline(String apiKey) async {
  print('=== Transport Timeout Baseline ===\n');

  final config = const transport.DioHttpClientConfig(
    baseUrl: _openAIBaseUrl,
    defaultHeaders: <String, String>{},
    timeout: Duration(minutes: 2),
    connectionTimeout: Duration(seconds: 15),
    receiveTimeout: Duration(minutes: 3),
  );

  try {
    final result = await _runPrompt(
      model: _openAIModel(
        apiKey,
        transportClient: _transportFromConfig(
          config,
          loggerName: 'http_configuration.timeout',
        ),
      ),
      prompt: 'Describe transport timeout layering in one sentence.',
    );

    print('Configured connection=15s, receive=3m, send=2m.');
    print(
        'Priority: specific transport timeout > transport timeout > defaults.');
    print('Response: ${result.text}\n');
  } catch (error) {
    print('Transport timeout baseline failed: $error\n');
  }
}

Future<void> demonstrateLoggingConfiguration(String apiKey) async {
  print('=== Transport Logging ===\n');

  final config = const transport.DioHttpClientConfig(
    baseUrl: _openAIBaseUrl,
    defaultHeaders: <String, String>{},
    timeout: Duration(seconds: 30),
    enableLogging: true,
  );

  try {
    final result = await _runPrompt(
      model: _openAIModel(
        apiKey,
        transportClient: _transportFromConfig(
          config,
          loggerName: 'http_configuration.logging',
        ),
      ),
      prompt:
          'Generate a short line so transport logging has activity to show.',
    );

    print('Transport logging was enabled for this request.');
    print('Response: ${result.text}\n');
  } catch (error) {
    print('Transport logging failed: $error\n');
  }
}

Future<void> demonstrateComprehensiveConfiguration(String apiKey) async {
  print('=== Comprehensive Transport Configuration ===\n');

  final config = const transport.DioHttpClientConfig(
    baseUrl: _openAIBaseUrl,
    defaultHeaders: <String, String>{},
    customHeaders: <String, String>{
      'X-Request-ID': 'comprehensive-http-demo-456',
      'X-Environment': 'development',
    },
    timeout: Duration(minutes: 1),
    connectionTimeout: Duration(seconds: 20),
    receiveTimeout: Duration(minutes: 2),
    enableLogging: true,
  );

  try {
    final result = await _runPrompt(
      model: _openAIModel(
        apiKey,
        transportClient: _transportFromConfig(
          config,
          loggerName: 'http_configuration.comprehensive',
        ),
      ),
      prompt:
          'Summarize why transport configuration belongs below provider selection.',
      callOptions: const core.CallOptions(
        headers: <String, String>{
          'X-Per-Call-Header': 'call-scope',
        },
      ),
    );

    print('Combined transport defaults with a per-call header override.');
    print('Response: ${result.text}\n');
  } catch (error) {
    print('Comprehensive transport configuration failed: $error\n');
  }
}

Future<void> demonstrateRequestHooksAndDiagnostics(String apiKey) async {
  print('=== Request Hooks And Diagnostics ===\n');

  final events = <transport.TransportDiagnosticsEvent>[];
  final baseTransport = _transportFromConfig(
    const transport.DioHttpClientConfig(
      baseUrl: _openAIBaseUrl,
      defaultHeaders: <String, String>{},
      timeout: Duration(seconds: 30),
      enableLogging: true,
    ),
    loggerName: 'http_configuration.request_hooks',
    diagnostics: transport.CallbackTransportDiagnostics(events.add),
    diagnosticsOptions: transport.TransportDiagnosticsOptions(
      includeHeaders: true,
      includeRequestBody: true,
      includeResponseBody: true,
      bodySanitizer: (body) {
        if (body is Map) {
          return {
            'keys': body.keys.map((key) => key.toString()).toList(),
          };
        }
        return body?.runtimeType.toString();
      },
    ),
  );

  final hookedTransport = transport.MiddlewareTransportClient(
    inner: baseTransport,
    middlewares: [
      transport.TransportMiddleware(
        onRequest: (request) => request.copyWith(
          headers: {
            ...request.headers,
            'x-demo-hook': 'enabled',
          },
        ),
      ),
    ],
  );

  try {
    final result = await _runPrompt(
      model: _openAIModel(
        apiKey,
        transportClient: hookedTransport,
      ),
      prompt: 'Reply with one short sentence.',
      callOptions: const core.CallOptions(
        timeout: Duration(seconds: 20),
        maxRetries: 1,
        headers: <String, String>{
          'X-Per-Call-Header': 'hook-demo',
        },
      ),
    );

    final startEvent = events.firstWhere(
      (event) =>
          event.kind == transport.TransportDiagnosticsEventKind.requestStart,
    );

    print('Hooked request maxRetries: ${startEvent.request.maxRetries}');
    print(
        'Hooked request headers: ${startEvent.request.headerNames.join(', ')}');
    print('Hooked request body snapshot: ${startEvent.request.body}');
    print('Response: ${result.text}\n');
  } catch (error) {
    print('Request hook demo failed: $error\n');
  }
}

void _configureLogging() {
  transport.Logger.root.level = transport.Level.ALL;
  transport.Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.loggerName}: '
        '${record.message}');
  });
}

core.LanguageModel _openAIModel(
  String apiKey, {
  required transport.TransportClient transportClient,
}) {
  return llm
      .openai(
        apiKey: apiKey,
        transport: transportClient,
      )
      .chatModel(_modelId);
}

transport.TransportClient _transportFromConfig(
  transport.DioHttpClientConfig config, {
  required String loggerName,
  transport.TransportDiagnostics? diagnostics,
  transport.TransportDiagnosticsOptions diagnosticsOptions =
      const transport.TransportDiagnosticsOptions(),
}) {
  final dio = transport.DioHttpClientFactory.createConfiguredDio(
    config: config,
    logger: transport.Logger(loggerName),
  );
  return transport.DioTransportClient(
    dio: dio,
    diagnostics: diagnostics,
    diagnosticsOptions: diagnosticsOptions,
  );
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
