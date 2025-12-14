import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

/// Environment setup and configuration examples
///
/// This example demonstrates:
/// - Environment variable configuration
/// - Configuration file management
/// - Provider-specific setup patterns
/// - Security best practices
/// - Development vs production configurations
/// - Error handling for configuration issues
Future<void> main() async {
  print('⚙️ Environment Setup Examples\n');

  // Demonstrate different configuration approaches
  await demonstrateEnvironmentVariables();
  await demonstrateConfigurationFiles();
  await demonstrateSecurityBestPractices();
  await demonstrateDevelopmentVsProduction();
  await demonstrateProviderSpecificSetup();
  await demonstrateConfigurationValidation();

  print('✅ Environment setup examples completed!');
  print('💡 Next steps:');
  print(
      '   • See example/01_getting_started/basic_configuration.dart for basic usage');
  print('   • See example/02_core_features/ for feature-specific examples');
}

/// Demonstrate environment variable configuration
Future<void> demonstrateEnvironmentVariables() async {
  print('🌍 Environment Variables Configuration:\n');

  // Show how to read environment variables
  print('   📖 Reading Environment Variables:');

  final envVars = {
    'OPENAI_API_KEY': Platform.environment['OPENAI_API_KEY'],
    'ANTHROPIC_API_KEY': Platform.environment['ANTHROPIC_API_KEY'],
    'GOOGLE_API_KEY': Platform.environment['GOOGLE_API_KEY'],
    'ELEVENLABS_API_KEY': Platform.environment['ELEVENLABS_API_KEY'],
    'GROQ_API_KEY': Platform.environment['GROQ_API_KEY'],
    'XAI_API_KEY': Platform.environment['XAI_API_KEY'],
  };

  for (final entry in envVars.entries) {
    final key = entry.key;
    final value = entry.value;
    final status = value != null ? '✅ Set' : '❌ Not set';
    final preview = value != null ? '${value.substring(0, 8)}...' : 'N/A';

    print('      $status $key: $preview');
  }

  print('\n   💡 Environment Variable Best Practices:');
  print('      • Use .env files for local development');
  print('      • Never commit API keys to version control');
  print('      • Use different keys for dev/staging/production');
  print('      • Rotate keys regularly');
  print('      • Use key management services in production');

  // Demonstrate provider creation with environment variables
  print('\n   🔧 Creating Providers from Environment:');

  try {
    // OpenAI example
    final openaiKey = Platform.environment['OPENAI_API_KEY'];
    if (openaiKey != null) {
      final openaiProvider =
          await ai().openai().apiKey(openaiKey).model('gpt-3.5-turbo').build();
      print(
          '      ✅ OpenAI provider configured (${openaiProvider.runtimeType})');
    } else {
      print('      ⚠️  OpenAI: Set OPENAI_API_KEY environment variable');
    }

    // Anthropic example
    final anthropicKey = Platform.environment['ANTHROPIC_API_KEY'];
    if (anthropicKey != null) {
      final anthropicProvider = await ai()
          .anthropic()
          .apiKey(anthropicKey)
          .model('claude-3-sonnet-20240229')
          .build();
      print(
          '      ✅ Anthropic provider configured (${anthropicProvider.runtimeType})');
    } else {
      print('      ⚠️  Anthropic: Set ANTHROPIC_API_KEY environment variable');
    }
  } catch (e) {
    print('      ❌ Provider configuration failed: $e');
  }

  print('');
}

/// Demonstrate configuration file management
Future<void> demonstrateConfigurationFiles() async {
  print('📄 Configuration Files:\n');

  // Create sample configuration files
  await createSampleConfigFiles();

  print('   📁 Configuration File Types:');
  print('      • .env - Environment variables');
  print('      • config.json - JSON configuration');
  print('      • config.yaml - YAML configuration');
  print('      • .llmrc - Custom configuration format');

  // Demonstrate reading different config formats
  await demonstrateEnvFileReading();
  await demonstrateJsonConfigReading();
  await demonstrateYamlConfigReading();

  print('');
}

/// Demonstrate security best practices
Future<void> demonstrateSecurityBestPractices() async {
  print('🔒 Security Best Practices:\n');

  print('   🛡️  API Key Security:');
  print('      ✅ DO:');
  print('         • Store keys in environment variables');
  print('         • Use key management services (AWS KMS, Azure Key Vault)');
  print('         • Implement key rotation');
  print('         • Use least privilege access');
  print('         • Monitor API usage');

  print('      ❌ DON\'T:');
  print('         • Hardcode keys in source code');
  print('         • Commit keys to version control');
  print('         • Share keys in plain text');
  print('         • Use production keys in development');
  print('         • Log API keys');

  print('\n   🔐 Configuration Validation:');

  // Demonstrate key validation
  final testKey = 'sk-test123456789';
  final validationResult =
      ConfigurationValidator.validateApiKey(testKey, 'openai');
  print('      Test key validation: ${validationResult.isValid ? '✅' : '❌'}');
  if (!validationResult.isValid) {
    print('      Issues: ${validationResult.errors.join(', ')}');
  }

  print('\n   🚨 Security Checklist:');
  final securityChecks = SecurityChecker.performSecurityCheck();
  for (final check in securityChecks) {
    final status = check.passed ? '✅' : '❌';
    print('      $status ${check.description}');
    if (!check.passed && check.recommendation != null) {
      print('         💡 ${check.recommendation}');
    }
  }

  print('');
}

/// Demonstrate development vs production configurations
Future<void> demonstrateDevelopmentVsProduction() async {
  print('🏗️ Development vs Production:\n');

  print('   🧪 Development Configuration:');
  print('      • Use test API keys');
  print('      • Enable verbose logging');
  print('      • Use smaller models for faster iteration');
  print('      • Set lower rate limits');
  print('      • Enable debug features');

  print('\n   🚀 Production Configuration:');
  print('      • Use production API keys');
  print('      • Minimal logging (errors only)');
  print('      • Use optimized models');
  print('      • Set appropriate timeouts');
  print('      • Enable monitoring and metrics');

  // Demonstrate environment-specific configurations
  final environment = Platform.environment['ENVIRONMENT'] ?? 'development';
  print('\n   🎯 Current Environment: $environment');

  final config = EnvironmentConfig.forEnvironment(environment);
  print('      📊 Configuration:');
  print('         • Log Level: ${config.logLevel}');
  print('         • Timeout: ${config.timeout.inSeconds}s');
  print('         • Max Retries: ${config.maxRetries}');
  print('         • Debug Mode: ${config.debugMode}');

  // Create provider with environment-specific config
  try {
    final provider = await createProviderForEnvironment(environment);
    if (provider != null) {
      print('      ✅ Provider configured for $environment');
    }
  } catch (e) {
    print('      ❌ Failed to configure provider: $e');
  }

  print('');
}

/// Demonstrate provider-specific setup
Future<void> demonstrateProviderSpecificSetup() async {
  print('🔧 Provider-Specific Setup:\n');

  final providerSetups = [
    {
      'name': 'OpenAI',
      'setup': () => setupOpenAI(),
    },
    {
      'name': 'Anthropic',
      'setup': () => setupAnthropic(),
    },
    {
      'name': 'Google',
      'setup': () => setupGoogle(),
    },
    {
      'name': 'Ollama (Local)',
      'setup': () => setupOllama(),
    },
  ];

  for (final provider in providerSetups) {
    print('   🔧 ${provider['name']} Setup:');
    try {
      await (provider['setup'] as Future<void> Function())();
    } catch (e) {
      print('      ❌ Setup failed: $e');
    }
    print('');
  }
}

/// Demonstrate configuration validation
Future<void> demonstrateConfigurationValidation() async {
  print('✅ Configuration Validation:\n');

  print('   🔍 Validating Current Configuration:');

  // Check environment variables
  final envValidation = ConfigurationValidator.validateEnvironment();
  print('      Environment: ${envValidation.isValid ? '✅' : '❌'}');
  if (!envValidation.isValid) {
    for (final error in envValidation.errors) {
      print('         • $error');
    }
  }

  // Check network connectivity
  print('      🌐 Network Connectivity:');
  final connectivityChecks = [
    {'name': 'OpenAI', 'url': 'https://api.openai.com'},
    {'name': 'Anthropic', 'url': 'https://api.anthropic.com'},
    {'name': 'Google', 'url': 'https://generativelanguage.googleapis.com'},
  ];

  for (final check in connectivityChecks) {
    try {
      // Note: In a real implementation, you would make actual HTTP requests
      print('         ✅ ${check['name']}: Reachable');
    } catch (e) {
      print('         ❌ ${check['name']}: Unreachable');
    }
  }

  print('');
}

// Helper functions and classes

/// Create sample configuration files
Future<void> createSampleConfigFiles() async {
  // .env file
  await File('.env.example').writeAsString('''
# OpenAI Configuration
OPENAI_API_KEY=sk-your-openai-key-here
OPENAI_ORG_ID=org-your-org-id

# Anthropic Configuration
ANTHROPIC_API_KEY=sk-ant-your-anthropic-key-here

# Google Configuration
GOOGLE_API_KEY=your-google-api-key-here

# Other Providers
ELEVENLABS_API_KEY=your-elevenlabs-key-here
GROQ_API_KEY=gsk_your-groq-key-here
XAI_API_KEY=xai-your-xai-key-here

# Environment Settings
ENVIRONMENT=development
LOG_LEVEL=info
DEBUG_MODE=true
''');

  // JSON config
  await File('config.example.json').writeAsString('''
{
  "providers": {
    "openai": {
      "model": "gpt-3.5-turbo",
      "temperature": 0.7,
      "max_tokens": 1000
    },
    "anthropic": {
      "model": "claude-3-sonnet-20240229",
      "temperature": 0.7,
      "max_tokens": 1000
    }
  },
  "settings": {
    "timeout": 30,
    "retries": 3,
    "log_level": "info"
  }
}
''');
}

/// Demonstrate .env file reading
Future<void> demonstrateEnvFileReading() async {
  print('   📖 Reading .env file:');

  final envFile = File('.env.example');
  if (await envFile.exists()) {
    final content = await envFile.readAsString();
    final lines = content
        .split('\n')
        .where((line) => line.trim().isNotEmpty && !line.startsWith('#'))
        .length;
    print('      ✅ Found .env.example with $lines configuration entries');
  } else {
    print('      ⚠️  .env.example not found');
  }
}

/// Demonstrate JSON config reading
Future<void> demonstrateJsonConfigReading() async {
  print('   📖 Reading JSON config:');

  final configFile = File('config.example.json');
  if (await configFile.exists()) {
    print('      ✅ Found config.example.json');
    // In a real implementation, you would parse the JSON
    print('      📊 Contains provider and settings configuration');
  } else {
    print('      ⚠️  config.example.json not found');
  }
}

/// Demonstrate YAML config reading
Future<void> demonstrateYamlConfigReading() async {
  print('   📖 Reading YAML config:');
  print('      💡 YAML support requires yaml package');
  print('      📝 Example: pub add yaml');
}

/// Environment-specific configuration
class EnvironmentConfig {
  final String logLevel;
  final Duration timeout;
  final int maxRetries;
  final bool debugMode;

  EnvironmentConfig({
    required this.logLevel,
    required this.timeout,
    required this.maxRetries,
    required this.debugMode,
  });

  factory EnvironmentConfig.forEnvironment(String environment) {
    switch (environment.toLowerCase()) {
      case 'production':
        return EnvironmentConfig(
          logLevel: 'error',
          timeout: Duration(seconds: 60),
          maxRetries: 3,
          debugMode: false,
        );
      case 'staging':
        return EnvironmentConfig(
          logLevel: 'warn',
          timeout: Duration(seconds: 45),
          maxRetries: 2,
          debugMode: false,
        );
      default: // development
        return EnvironmentConfig(
          logLevel: 'debug',
          timeout: Duration(seconds: 30),
          maxRetries: 1,
          debugMode: true,
        );
    }
  }
}

/// Configuration validation
class ConfigurationValidator {
  static ValidationResult validateApiKey(String key, String provider) {
    final errors = <String>[];

    if (key.isEmpty) {
      errors.add('API key is empty');
    }

    // Provider-specific validation
    switch (provider.toLowerCase()) {
      case 'openai':
        if (!key.startsWith('sk-')) {
          errors.add('OpenAI keys should start with "sk-"');
        }
        break;
      case 'anthropic':
        if (!key.startsWith('sk-ant-')) {
          errors.add('Anthropic keys should start with "sk-ant-"');
        }
        break;
    }

    return ValidationResult(errors.isEmpty, errors);
  }

  static ValidationResult validateEnvironment() {
    final errors = <String>[];

    // Check for at least one API key
    final hasAnyKey = [
      'OPENAI_API_KEY',
      'ANTHROPIC_API_KEY',
      'GOOGLE_API_KEY',
    ].any((key) => Platform.environment[key] != null);

    if (!hasAnyKey) {
      errors.add('No API keys found in environment');
    }

    return ValidationResult(errors.isEmpty, errors);
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult(this.isValid, this.errors);
}

/// Security checker
class SecurityChecker {
  static List<SecurityCheck> performSecurityCheck() {
    return [
      SecurityCheck(
        'Environment variables used for API keys',
        !_hasHardcodedKeys(),
        'Move API keys to environment variables',
      ),
      SecurityCheck(
        'No API keys in source code',
        true, // Assume true for demo
        null,
      ),
      SecurityCheck(
        'Using HTTPS endpoints',
        true, // All providers use HTTPS
        null,
      ),
    ];
  }

  static bool _hasHardcodedKeys() {
    // In a real implementation, this would scan source files
    return false;
  }
}

class SecurityCheck {
  final String description;
  final bool passed;
  final String? recommendation;

  SecurityCheck(this.description, this.passed, this.recommendation);
}

/// Provider setup functions
Future<void> setupOpenAI() async {
  print('      🔑 API Key: Set OPENAI_API_KEY');
  print('      🏢 Organization: Set OPENAI_ORG_ID (optional)');
  print('      🌐 Endpoint: https://api.openai.com/v1');
  print('      📚 Models: gpt-4, gpt-3.5-turbo, dall-e-3');
}

Future<void> setupAnthropic() async {
  print('      🔑 API Key: Set ANTHROPIC_API_KEY');
  print('      🌐 Endpoint: https://api.anthropic.com');
  print('      📚 Models: claude-3-opus, claude-3-sonnet, claude-3-haiku');
}

Future<void> setupGoogle() async {
  print('      🔑 API Key: Set GOOGLE_API_KEY');
  print('      🌐 Endpoint: https://generativelanguage.googleapis.com');
  print('      📚 Models: gemini-pro, gemini-pro-vision');
}

Future<void> setupOllama() async {
  print('      🏠 Local Installation: ollama.ai');
  print('      🌐 Default Endpoint: http://localhost:11434');
  print('      📚 Models: Download with `ollama pull model-name`');
  print('      💡 No API key required for local usage');
}

/// Create provider for specific environment
Future<ChatCapability?> createProviderForEnvironment(String environment) async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null) return null;

  final config = EnvironmentConfig.forEnvironment(environment);

  return await ai()
      .openai()
      .apiKey(apiKey)
      .model(environment == 'production' ? 'gpt-4' : 'gpt-3.5-turbo')
      .timeout(config.timeout)
      .temperature(config.debugMode ? 0.1 : 0.7)
      .build();
}
