import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:logging/logging.dart';

/// HTTP Configuration Example
///
/// This example demonstrates how to configure HTTP settings for LLM providers,
/// including proxy configuration, custom headers, SSL settings, and logging.
///
/// Note: Advanced HTTP features (proxy, SSL bypass, custom certificates) are only
/// available on IO platforms (Desktop/Mobile/Server). On Web platforms, these
/// features are managed by the browser.
///
/// Before running, set your OpenAI API key:
/// export OPENAI_API_KEY="your-openai-key"
Future<void> main() async {
  // Configure logging to see HTTP request/response logs
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  print('🌐 HTTP Configuration Demo\n');

  registerOpenAI();

  // Get OpenAI API key from environment
  final openaiApiKey = Platform.environment['OPENAI_API_KEY'];

  if (openaiApiKey == null) {
    print('❌ Please set your OpenAI API key:');
    print('   export OPENAI_API_KEY="your-openai-key"');
    return;
  }

  print('📋 Using OpenAI provider for all demonstrations\n');

  // Run all demonstrations with OpenAI
  await demonstrateBasicHttpConfig(openaiApiKey);
  await demonstrateProxyConfiguration(openaiApiKey);
  await demonstrateSSLConfiguration(openaiApiKey);
  await demonstrateCustomHeaders(openaiApiKey);
  await demonstrateTimeoutConfiguration(openaiApiKey);
  await demonstrateLoggingConfiguration(openaiApiKey);
  await demonstrateComprehensiveConfig(openaiApiKey);

  // await demonstrateConfigValidation();

  print('✅ HTTP configuration demonstration completed!');
}

/// Demonstrate basic HTTP configuration
Future<void> demonstrateBasicHttpConfig(String apiKey) async {
  print('🔧 Basic HTTP Configuration:\n');

  try {
    // Create provider with basic HTTP settings
    final provider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .timeout(Duration(seconds: 30))
        .build();

    final result = await generateText(
      model: provider,
      messages: [
        ChatMessage.user(
            'Hello! This is a test with basic HTTP configuration.'),
      ],
    );

    print('   ✅ Basic HTTP configuration successful');
    print('   📝 Response: ${result.text}\n');
  } catch (e) {
    print('   ❌ Basic HTTP configuration failed: $e\n');
  }
}

/// Demonstrate proxy configuration
Future<void> demonstrateProxyConfiguration(String apiKey) async {
  print('🔄 Proxy Configuration:\n');
  print('   ℹ️  Note: Proxy configuration is only supported on IO platforms');
  print('   📝 On Web platforms, proxy settings are managed by the browser\n');

  try {
    // Note: This example shows the API usage. In practice, you would
    // need a real proxy server for this to work.
    await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .http((http) => http.proxy('http://proxy.company.com:8080'))
        .build();

    print('   ✅ Proxy configuration set successfully');
    print('   📝 Note: Proxy will be used for all HTTP requests\n');
  } catch (e) {
    print(
        '   ⚠️  Proxy configuration example (may fail without real proxy): $e\n');
  }
}

/// Demonstrate custom headers configuration
Future<void> demonstrateCustomHeaders(String openaiApiKey) async {
  print('📋 Custom Headers Configuration (OpenAI):\n');

  try {
    final provider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(openaiApiKey)
        .model('gpt-4o-mini')
        .http((http) => http.headers({
              'X-Request-ID': 'demo-request-123',
              'X-Client-Version': '1.0.0',
              'User-Agent': 'LLMDart-Demo/1.0',
            }).header('X-Additional-Header', 'additional-value'))
        .build();

    final result = await generateText(
      model: provider,
      messages: [
        ChatMessage.user('Hello! This request includes custom headers.')
      ],
    );

    print('   ✅ Custom headers configuration successful');
    print('   📝 Response: ${result.text}\n');
  } catch (e) {
    print('   ❌ Custom headers configuration failed: $e\n');
  }
}

/// Demonstrate SSL configuration
Future<void> demonstrateSSLConfiguration(String openaiApiKey) async {
  print('🔒 SSL Configuration:\n');
  print('   ℹ️  Note: SSL configuration is only supported on IO platforms');
  print('   📝 On Web platforms, SSL/TLS is managed by the browser\n');

  try {
    // Example with SSL verification bypass (for development only)
    await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(openaiApiKey)
        .model('gpt-4o-mini')
        .http((http) =>
            http.bypassSSLVerification(true)) // ⚠️ Only for development!
        .build();

    print('   ⚠️  SSL verification bypass enabled (development only)');
    print('   📝 Note: This should only be used for local development\n');
  } catch (e) {
    print('   ⚠️  SSL verification bypass example: $e\n');
  }

  try {
    // Example with custom SSL certificate
    await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(openaiApiKey)
        .model('gpt-4o-mini')
        .http((http) => http.sslCertificate('/path/to/custom/certificate.pem'))
        .build();

    print('   ✅ Custom SSL certificate configuration set');
    print('   📝 Note: Certificate path configured for secure connections\n');
  } catch (e) {
    print('   ⚠️  Custom SSL certificate example: $e\n');
  }
}

/// Demonstrate timeout configuration with priority hierarchy
Future<void> demonstrateTimeoutConfiguration(String openaiApiKey) async {
  print('⏱️  Timeout Configuration (OpenAI - Priority Hierarchy):\n');

  try {
    // Example 1: Global timeout only
    print('   📝 Example 1: Global timeout only');
    final provider1 = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(openaiApiKey)
        .model('gpt-4o-mini')
        .timeout(Duration(minutes: 1)) // Global timeout for all operations
        .build();

    final result1 = await generateText(
      model: provider1,
      messages: [ChatMessage.user('Hello! This uses global timeout.')],
    );
    print('   ✅ Global timeout: connection=1m, receive=1m, send=1m');
    print('   📝 Response: ${result1.text}\n');

    // Example 2: Mixed configuration (global + HTTP overrides)
    print('   📝 Example 2: Mixed configuration (global + HTTP overrides)');
    final provider2 = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(openaiApiKey)
        .model('gpt-4o-mini')
        .timeout(Duration(minutes: 2)) // Global default: 2 minutes
        .http((http) => http
            .connectionTimeout(
                Duration(seconds: 15)) // Override connection: 15s
            .receiveTimeout(Duration(minutes: 3))) // Override receive: 3m
        // sendTimeout will use global timeout (2 minutes)
        .build();

    final result2 = await generateText(
      model: provider2,
      messages: [
        ChatMessage.user('Hello! This uses mixed timeout configuration.'),
      ],
    );
    print('   ✅ Mixed timeouts: connection=15s, receive=3m, send=2m');
    print('   📝 Priority: HTTP-specific > Global > Provider defaults');
    print('   📝 Response: ${result2.text}\n');
  } catch (e) {
    print('   ❌ Timeout configuration failed: $e\n');
  }
}

/// Demonstrate logging configuration
Future<void> demonstrateLoggingConfiguration(String openaiApiKey) async {
  print('📊 HTTP Logging Configuration (OpenAI):\n');

  try {
    final provider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(openaiApiKey)
        .model('gpt-4o-mini')
        .http((http) => http.enableLogging(true))
        .build();

    print('   ✅ HTTP logging enabled');
    print('   📝 All HTTP requests and responses will be logged');
    print('   📝 Making a test request...\n');

    final result = await generateText(
      model: provider,
      messages: [ChatMessage.user('Hello! This request will be logged.')],
    );

    print('   ✅ Request completed with logging');
    print('   📝 Response: ${result.text}\n');
  } catch (e) {
    print('   ❌ Logging configuration failed: $e\n');
  }
}

/// Demonstrate comprehensive HTTP configuration
Future<void> demonstrateComprehensiveConfig(String openaiApiKey) async {
  print('🎯 Comprehensive HTTP Configuration (OpenAI):\n');

  try {
    final provider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(openaiApiKey)
        .model('gpt-4o-mini')
        // HTTP configuration using the new layered approach
        .http((http) => http
            .headers({
              'X-Request-ID': 'comprehensive-demo-456',
              'X-Client-Name': 'LLMDart-Comprehensive-Demo',
            })
            .connectionTimeout(Duration(seconds: 20))
            .receiveTimeout(Duration(minutes: 3))
            .enableLogging(true))
        // Provider-specific configuration
        .temperature(0.7)
        .maxTokens(1000)
        .build();

    final result = await generateText(
      model: provider,
      messages: [
        ChatMessage.user(
          'Hello! This request uses comprehensive HTTP configuration.',
        ),
      ],
    );

    print('   ✅ Comprehensive configuration successful');
    print('   📝 All HTTP settings applied successfully');
    print('   📝 Response: ${result.text}\n');
  } catch (e) {
    print('   ❌ Comprehensive configuration failed: $e\n');
  }
}

/// Demonstrate configuration validation
Future<void> demonstrateConfigValidation() async {
  print('✅ Configuration Validation:\n');

  try {
    // This would typically be called internally, but shown here for demonstration
    final config = LLMConfig(
      baseUrl: 'https://api.openai.com/v1/',
      model: 'gpt-4o-mini',
      apiKey: 'test-key',
      timeout: Duration(seconds: 60),
    ).withTransportOptions({
      'httpProxy': 'invalid-proxy-url', // This will trigger a warning
      'bypassSSLVerification': true, // This will trigger a security warning
      'connectionTimeout':
          Duration(seconds: 30), // Different from global timeout
    });

    HttpConfigUtils.validateHttpConfig(config);
    print('   ✅ Configuration validation completed');
    print('   📝 Check logs for any warnings about configuration issues\n');
  } catch (e) {
    print('   ❌ Configuration validation failed: $e\n');
  }
}
