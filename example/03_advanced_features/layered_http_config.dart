import 'dart:io';
import 'package:dio/dio.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

/// Layered HTTP Configuration Example
///
/// This example demonstrates the new layered approach to HTTP configuration,
/// which provides a cleaner and more organized way to configure HTTP settings.
///
/// Note: Advanced HTTP features (proxy, SSL bypass, custom certificates) are only
/// available on IO platforms (Desktop/Mobile/Server). On Web platforms, these
/// features are managed by the browser.
///
/// Before running, set API keys for the providers you want to test:
/// export OPENAI_API_KEY="your-openai-key"
/// export ANTHROPIC_API_KEY="your-anthropic-key"
/// export DEEPSEEK_API_KEY="your-deepseek-key"
Future<void> main() async {
  print('🏗️  Layered HTTP Configuration Demo\n');

  // Get API keys from environment
  final apiKeys = {
    'openai': Platform.environment['OPENAI_API_KEY'],
    'anthropic': Platform.environment['ANTHROPIC_API_KEY'],
    'deepseek': Platform.environment['DEEPSEEK_API_KEY'],
  };

  // Check if we have at least one API key
  final availableKeys = apiKeys.entries.where((e) => e.value != null).toList();
  if (availableKeys.isEmpty) {
    print('❌ Please set at least one API key:');
    print('   OPENAI_API_KEY, ANTHROPIC_API_KEY, or DEEPSEEK_API_KEY');
    return;
  }

  print('📋 Available providers:');
  for (final entry in availableKeys) {
    print('   ✅ ${entry.key.toUpperCase()}');
  }
  print('');

  // Run demonstrations with available keys
  if (apiKeys['openai'] != null) {
    await demonstrateBasicLayeredConfig(apiKeys['openai']!);
  }

  if (apiKeys['anthropic'] != null) {
    await demonstrateAdvancedLayeredConfig(apiKeys['anthropic']!);
    await demonstrateCustomDioClient(apiKeys['anthropic']!);
  }

  if (apiKeys['deepseek'] != null) {
    await demonstrateTimeoutPriorityInLayeredConfig(apiKeys['deepseek']!);
  }

  await demonstrateConfigReusability();

  print('✅ Layered HTTP configuration demonstration completed!');
}

/// Demonstrate basic layered HTTP configuration
Future<void> demonstrateBasicLayeredConfig(String openaiApiKey) async {
  print('🔧 Basic Layered HTTP Configuration (OpenAI):\n');

  try {
    // Clean, organized HTTP configuration
    final provider = await ai()
        .openai()
        .apiKey(openaiApiKey)
        .model('gpt-4o-mini')
        .http((http) => http
            .headers({'X-Request-ID': 'layered-demo-001'})
            .connectionTimeout(Duration(seconds: 30))
            .enableLogging(true))
        .build();

    final response = await provider.chat([
      ChatMessage.user('Hello! This uses the new layered HTTP configuration.'),
    ]);

    print('   ✅ Layered HTTP configuration successful');
    print('   📝 Response: ${response.text}\n');
  } catch (e) {
    print('   ❌ Layered HTTP configuration failed: $e\n');
  }
}

/// Demonstrate advanced layered HTTP configuration
Future<void> demonstrateAdvancedLayeredConfig(String anthropicApiKey) async {
  print('🚀 Advanced Layered HTTP Configuration (Anthropic):\n');

  try {
    // Complex HTTP configuration with multiple settings
    final provider = await ai()
        .anthropic()
        .apiKey(anthropicApiKey)
        .model('claude-3-5-haiku-20241022')
        .http((http) => http
                // Headers configuration
                .headers({
                  'X-Request-ID': 'advanced-layered-demo-002',
                  'X-Client-Version': '2.0.0',
                  'X-Environment': 'production',
                })
                .header('X-Additional-Header', 'dynamic-value')
                // Timeout configuration
                .connectionTimeout(Duration(seconds: 20))
                .receiveTimeout(Duration(minutes: 5))
                .sendTimeout(Duration(seconds: 45))
                // Debugging
                .enableLogging(true)
            // SSL configuration (example - IO platforms only)
            // .bypassSSLVerification(false)
            // .sslCertificate('/path/to/cert.pem')
            // Proxy configuration (example - IO platforms only)
            // .proxy('http://corporate-proxy:8080')
            )
        .build();

    final response = await provider.chat([
      ChatMessage.user(
          'Hello! This uses advanced layered HTTP configuration with multiple settings.'),
    ]);

    print('   ✅ Advanced layered configuration successful');
    print('   📝 All HTTP settings applied cleanly');
    print('   📝 Response: ${response.text}\n');
  } catch (e) {
    print('   ❌ Advanced layered configuration failed: $e\n');
  }
}

/// Demonstrate a custom transport client backed by Dio
Future<void> demonstrateCustomDioClient(String anthropicApiKey) async {
  print('🔧 Custom Transport Client for Advanced HTTP Control (Anthropic):\n');

  try {
    // Create custom Dio with advanced configuration
    final customDio = Dio();

    // Configure custom timeouts
    customDio.options.connectTimeout = Duration(seconds: 20);
    customDio.options.receiveTimeout = Duration(minutes: 3);
    customDio.options.sendTimeout = Duration(seconds: 30);

    // Add custom headers
    customDio.options.headers.addAll({
      'X-Custom-Client': 'LLMDart-Advanced',
      'X-Client-Version': '2.0.0',
      'X-Request-Source': 'custom-dio-demo',
    });

    // Add monitoring interceptor
    customDio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final requestId = 'req-${DateTime.now().millisecondsSinceEpoch}';
        options.headers['X-Request-ID'] = requestId;
        print('   🚀 Starting request: $requestId to ${options.uri.host}');
        options.extra['start_time'] = DateTime.now();
        handler.next(options);
      },
      onResponse: (response, handler) {
        final startTime =
            response.requestOptions.extra['start_time'] as DateTime?;
        if (startTime != null) {
          final duration = DateTime.now().difference(startTime);
          print('   ✅ Request completed in ${duration.inMilliseconds}ms');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        final startTime = error.requestOptions.extra['start_time'] as DateTime?;
        if (startTime != null) {
          final duration = DateTime.now().difference(startTime);
          print('   ❌ Request failed after ${duration.inMilliseconds}ms');
        }
        handler.next(error);
      },
    ));

    // Add retry interceptor for production resilience
    customDio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode == 429) {
          print('   ⏳ Rate limited, implementing backoff strategy...');
          await Future.delayed(Duration(seconds: 1));
          // In production, you might want to retry the request here
        }
        handler.next(error);
      },
    ));

    // Wrap the custom Dio instance in the stable transport client surface.
    final transportClient = DioTransportClient(dio: customDio);

    // Use the custom transport client with the provider
    final provider = await ai()
        .anthropic()
        .apiKey(anthropicApiKey)
        .model('claude-3-5-haiku-20241022')
        .http((http) => http
            .transportClient(
                transportClient) // 🎯 Custom transport takes highest priority
            .enableLogging(
                true) // This will be ignored since the custom transport is used
            .connectionTimeout(Duration(seconds: 60))) // This will be ignored
        .build();

    print('   📝 Priority: Custom transport > HTTP config > Provider defaults');
    print('   📝 Making request with custom transport client...\n');

    final response = await provider.chat([
      ChatMessage.user(
          'Hello! This request uses a custom Dio client with advanced monitoring and retry logic.'),
    ]);

    print('   ✅ Custom transport client demonstration successful');
    print('   📝 Response: ${response.text}\n');

    // Show the benefits
    print('   🎯 Benefits of a Custom Transport Client:');
    print('   📝 • Complete HTTP control and customization');
    print('   📝 • Advanced monitoring and metrics collection');
    print('   📝 • Custom retry and error handling logic');
    print('   📝 • Integration with existing HTTP infrastructure');
    print('   📝 • Perfect for production environments\n');
  } catch (e) {
    print('   ❌ Custom transport client demonstration failed: $e\n');
  }
}

/// Demonstrate timeout priority in layered configuration
Future<void> demonstrateTimeoutPriorityInLayeredConfig(
    String deepseekApiKey) async {
  print('⏱️  Timeout Priority in Layered Configuration (DeepSeek):\n');

  try {
    // Example: Global timeout with HTTP-specific overrides
    final provider = await ai()
        .deepseek()
        .apiKey(deepseekApiKey)
        .model('deepseek-chat')
        .timeout(Duration(minutes: 2)) // Global timeout: 2 minutes
        .http((http) => http
            .headers({'X-Timeout-Demo': 'priority-example'})
            .connectionTimeout(
                Duration(seconds: 15)) // Override connection: 15s
            .receiveTimeout(Duration(minutes: 5)) // Override receive: 5min
            // sendTimeout will use global timeout (2 minutes)
            .enableLogging(false))
        .build();

    final response = await provider.chat([
      ChatMessage.user('This demonstrates timeout priority in layered config!'),
    ]);

    print('   ✅ Timeout priority demonstration successful');
    print('   📝 Final timeouts: connection=15s, receive=5min, send=2min');
    print('   📝 Priority: HTTP-specific > Global > Provider defaults');
    print('   📝 Response: ${response.text}\n');
  } catch (e) {
    print('   ❌ Timeout priority demonstration failed: $e\n');
  }
}

/// Demonstrate HTTP configuration reusability
Future<void> demonstrateConfigReusability() async {
  print('♻️  HTTP Configuration Reusability:\n');

  // Create reusable HTTP configuration
  HttpConfig createProductionHttpConfig() {
    return HttpConfig()
        .headers({
          'X-Environment': 'production',
          'X-Client-Version': '1.0.0',
          'X-Request-Source': 'mobile-app',
        })
        .connectionTimeout(Duration(seconds: 30))
        .receiveTimeout(Duration(minutes: 3))
        .enableLogging(false); // Disable in production
  }

  HttpConfig createDevelopmentHttpConfig() {
    return HttpConfig()
        .headers({
          'X-Environment': 'development',
          'X-Debug-Mode': 'true',
        })
        .connectionTimeout(Duration(seconds: 10))
        .receiveTimeout(Duration(seconds: 30))
        .enableLogging(true) // Enable in development
        .bypassSSLVerification(true); // For local testing (IO platforms only)
  }

  print('   ✅ HTTP configurations can be created as reusable functions');
  print('   📝 Production config: secure, optimized timeouts, no logging');
  print(
      '   📝 Development config: debug-friendly, logging enabled, relaxed SSL');
  print('   📝 Usage: .http((http) => createProductionHttpConfig())\n');

  // Demonstrate the configurations
  final prodConfig = createProductionHttpConfig();
  final devConfig = createDevelopmentHttpConfig();

  print(
      '   📊 Production config settings: ${prodConfig.build().keys.join(', ')}');
  print(
      '   📊 Development config settings: ${devConfig.build().keys.join(', ')}\n');

  // Demonstrate reusable custom transport factories
  print('   🔧 Reusable Custom Transport Factory:\n');

  // ignore: unused_element
  Dio createProductionDio() {
    final dio = Dio();

    // Production-optimized settings
    dio.options.connectTimeout = Duration(seconds: 30);
    dio.options.receiveTimeout = Duration(minutes: 5);
    dio.options.headers.addAll({
      'User-Agent': 'LLMDart-Production/1.0',
      'X-Environment': 'production',
    });

    // Add production monitoring
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Log for production monitoring
        print(
            '   📊 Production request: ${options.method} ${options.uri.host}');
        handler.next(options);
      },
    ));

    return dio;
  }

  // ignore: unused_element
  Dio createDevelopmentDio() {
    final dio = Dio();

    // Development-friendly settings
    dio.options.connectTimeout = Duration(seconds: 10);
    dio.options.receiveTimeout = Duration(seconds: 30);
    dio.options.headers.addAll({
      'User-Agent': 'LLMDart-Development/1.0',
      'X-Environment': 'development',
      'X-Debug': 'true',
    });

    // Add verbose logging for development
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('   🔍 Dev HTTP: $obj'),
    ));

    return dio;
  }

  print('   ✅ Custom transport factories created for different environments');
  print(
      '   📝 Usage: .http((http) => http.transportClient(DioTransportClient(dio: createProductionDio())))');
  print(
      '   📝 Benefits: Environment-specific optimizations, reusable across projects\n');
}
