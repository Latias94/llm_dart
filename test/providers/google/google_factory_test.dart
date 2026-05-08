import 'package:llm_dart/core/capability.dart';
import 'package:llm_dart/core/config.dart';
import 'package:llm_dart/providers/factories/base_factory.dart';
import 'package:llm_dart/providers/factories/google_factory.dart';
import 'package:llm_dart/providers/google/google.dart';
import 'package:llm_dart/src/compatibility/compat_providers.dart';
import 'package:test/test.dart';

void main() {
  group('GoogleProviderFactory Tests', () {
    late GoogleProviderFactory factory;

    setUp(() {
      factory = GoogleProviderFactory();
    });

    test('should create providers through the compat bridge shell', () {
      final provider = factory.create(
        LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
          model: 'gemini-2.5-flash',
        ),
      );

      expect(provider, isA<CompatGoogleProvider>());
      expect(provider, isA<GoogleProvider>());
      expect(provider, isA<ChatCapability>());
      expect(provider, isA<ProviderCapabilities>());
    });

    test('should implement factory interfaces and defaults', () {
      expect(factory, isA<BaseProviderFactory<ChatCapability>>());
      expect(factory.providerId, 'google');
      expect(factory.supportedCapabilities, contains(LLMCapability.chat));
      expect(factory.supportedCapabilities, contains(LLMCapability.streaming));
      expect(factory.supportedCapabilities, contains(LLMCapability.vision));

      final defaults = factory.getDefaultConfig();
      expect(defaults.baseUrl,
          'https://generativelanguage.googleapis.com/v1beta/');
      expect(defaults.model, isNotEmpty);
    });
  });
}
