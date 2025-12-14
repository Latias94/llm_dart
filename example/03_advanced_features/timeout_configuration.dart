import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

/// Example demonstrating the timeout configuration hierarchy
///
/// This example shows how different timeout settings interact and override each other.
void main() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null) {
    print('Please set OPENAI_API_KEY environment variable');
    return;
  }

  print('🕐 Timeout Configuration Examples\n');

  // Example 1: Global timeout only
  await example1GlobalTimeoutOnly(apiKey);

  // Example 2: HTTP-specific timeouts only
  await example2HttpTimeoutsOnly(apiKey);

  // Example 3: Mixed configuration (global + HTTP overrides)
  await example3MixedConfiguration(apiKey);

  // Example 4: Enterprise scenario
  await example4EnterpriseScenario(apiKey);

  // Example 5: Development scenario
  await example5DevelopmentScenario(apiKey);

  // Show priority explanation
  demonstrateTimeoutPriority();
}

/// Example 1: Using only global timeout
/// All HTTP operations will use the same timeout value
Future<void> example1GlobalTimeoutOnly(String apiKey) async {
  print('📝 Example 1: Global Timeout Only');
  print('   Setting: timeout(Duration(minutes: 2))');
  print('   Result: connection=2min, receive=2min, send=2min\n');

  try {
    final model = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .timeout(Duration(minutes: 2)) // Global timeout for all operations
        .buildLanguageModel();

    final result = await generateTextPromptWithModel(
      model,
      messages: [
        ModelMessage.userText('Hello! Please respond briefly.'),
      ],
    );

    print('   ✅ Success: ${result.text}\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }
}

/// Example 2: Using only HTTP-specific timeouts
/// Each HTTP operation type has its own timeout
Future<void> example2HttpTimeoutsOnly(String apiKey) async {
  print('📝 Example 2: HTTP-Specific Timeouts Only');
  print('   Setting: http config with specific timeouts');
  print('   Result: connection=30s, receive=5min, send=1min\n');

  try {
    final model = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .http((http) => http
            .connectionTimeout(Duration(seconds: 30)) // Quick connection
            .receiveTimeout(Duration(minutes: 5)) // Long response wait
            .sendTimeout(Duration(minutes: 1))) // Medium send time
        .buildLanguageModel();

    final result = await generateTextPromptWithModel(
      model,
      messages: [
        ModelMessage.userText(
          'Explain quantum computing in one sentence.',
        ),
      ],
    );

    print('   ✅ Success: ${result.text}\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }
}

/// Example 3: Mixed configuration (global + HTTP overrides)
/// Global timeout provides defaults, HTTP config overrides specific types
Future<void> example3MixedConfiguration(String apiKey) async {
  print('📝 Example 3: Mixed Configuration');
  print('   Setting: timeout(2min) + http.receiveTimeout(10min)');
  print('   Result: connection=2min, receive=10min, send=2min\n');

  try {
    final model = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .timeout(Duration(minutes: 2)) // Global default: 2 minutes
        .http((http) => http.receiveTimeout(
            Duration(minutes: 10))) // Override only receive timeout
        .buildLanguageModel();

    final result = await generateTextPromptWithModel(
      model,
      messages: [
        ModelMessage.userText(
          'What are the benefits of renewable energy?',
        ),
      ],
    );

    print('   ✅ Success: ${result.text}\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }
}

/// Example 4: Enterprise scenario with proxy and custom timeouts
/// Demonstrates real-world enterprise configuration
Future<void> example4EnterpriseScenario(String apiKey) async {
  print('📝 Example 4: Enterprise Scenario');
  print('   Setting: Corporate proxy + conservative timeouts');
  print('   Result: All timeouts extended for corporate network\n');

  try {
    final model = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .timeout(Duration(minutes: 5)) // Conservative global timeout
        .http((http) => http
                // .proxy('http://corporate-proxy:8080')  // Uncomment if you have a proxy
                .connectionTimeout(
                    Duration(minutes: 1)) // Slow corporate network
                .receiveTimeout(
                    Duration(minutes: 8)) // Allow for slow responses
                .headers({
              'X-Corporate-ID': 'dept-ai-research',
              'X-Environment': 'production',
            }).enableLogging(false)) // Disabled in production
        .buildLanguageModel();

    final result = await generateTextPromptWithModel(
      model,
      messages: [
        ModelMessage.userText(
          'Summarize the latest AI trends for our quarterly report.',
        ),
      ],
    );

    print('   ✅ Success: ${result.text}\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }
}

/// Example 5: Development scenario with fast timeouts and logging
/// Optimized for quick feedback during development
Future<void> example5DevelopmentScenario(String apiKey) async {
  print('📝 Example 5: Development Scenario');
  print('   Setting: Fast timeouts + logging enabled');
  print('   Result: Quick feedback for development\n');

  try {
    final model = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .timeout(Duration(seconds: 30)) // Fast global timeout
        .http((http) => http
                .connectionTimeout(Duration(seconds: 10)) // Quick connection
                .receiveTimeout(Duration(seconds: 45)) // Fast response
                .headers({
              'X-Environment': 'development',
              'X-Debug-Mode': 'true',
            }).enableLogging(true)) // Enabled for debugging
        .buildLanguageModel();

    final result = await generateTextPromptWithModel(
      model,
      messages: [
        ModelMessage.userText('Test message for development.'),
      ],
    );

    print('   ✅ Success: ${result.text}\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }
}

/// Utility function to demonstrate timeout priority
void demonstrateTimeoutPriority() {
  print('🔄 Timeout Priority Hierarchy:');
  print('   1. HTTP-specific timeouts (highest priority)');
  print('      .http((http) => http.connectionTimeout(Duration(seconds: 30)))');
  print('   2. Global timeout (medium priority)');
  print('      .timeout(Duration(minutes: 2))');
  print('   3. Provider defaults (low priority)');
  print('      Built-in provider-specific defaults');
  print('   4. System defaults (lowest priority)');
  print('      Duration(seconds: 60)\n');

  print('💡 Best Practices:');
  print('   • Use global timeout for simple scenarios');
  print('   • Use HTTP-specific timeouts for fine-grained control');
  print('   • Set longer receive timeouts for complex LLM tasks');
  print('   • Set shorter connection timeouts for quick failure detection');
  print('   • Consider network conditions (enterprise vs. direct connection)');
}
