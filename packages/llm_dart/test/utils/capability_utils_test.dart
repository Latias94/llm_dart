import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('CapabilityUtils', () {
    group('Provider Validation', () {
      test('should validate provider with all required capabilities', () {
        final provider = _MockProvider([
          LLMCapability.chat,
          LLMCapability.streaming,
          LLMCapability.toolCalling,
        ]);

        final required = {
          LLMCapability.chat,
          LLMCapability.streaming,
        };

        final report = CapabilityUtils.validateProvider(provider, required);

        expect(report.isValid, isTrue);
        expect(report.missing, isEmpty);
        expect(report.supported, equals(provider.supportedCapabilities));
        expect(report.required, equals(required));
      });

      test('should detect missing capabilities', () {
        final provider = _MockProvider([
          LLMCapability.chat,
        ]);

        final required = {
          LLMCapability.chat,
          LLMCapability.streaming,
          LLMCapability.toolCalling,
        };

        final report = CapabilityUtils.validateProvider(provider, required);

        expect(report.isValid, isFalse);
        expect(
            report.missing,
            equals({
              LLMCapability.streaming,
              LLMCapability.toolCalling,
            }));
        expect(report.supported, equals(provider.supportedCapabilities));
        expect(report.required, equals(required));
      });

      test('should handle empty required capabilities', () {
        final provider = _MockProvider([LLMCapability.chat]);
        final required = <LLMCapability>{};

        final report = CapabilityUtils.validateProvider(provider, required);

        expect(report.isValid, isTrue);
        expect(report.missing, isEmpty);
        expect(report.required, isEmpty);
      });

      test('should handle provider with no capabilities', () {
        final provider = _MockProvider([]);
        final required = {LLMCapability.chat};

        final report = CapabilityUtils.validateProvider(provider, required);

        expect(report.isValid, isFalse);
        expect(report.missing, equals({LLMCapability.chat}));
        expect(report.supported, isEmpty);
      });
    });

    group('Basic Capability Checking', () {
      test('should check capability using interface type', () {
        final provider = _MockProvider([LLMCapability.chat]);

        expect(CapabilityUtils.hasCapability<ProviderCapabilities>(provider),
            isTrue);
        expect(CapabilityUtils.hasCapability<ChatCapability>(provider),
            isFalse); // Mock doesn't implement ChatCapability
      });

      test('should check capability using enum', () {
        final provider =
            _MockProvider([LLMCapability.chat, LLMCapability.streaming]);

        expect(CapabilityUtils.supportsCapability(provider, LLMCapability.chat),
            isTrue);
        expect(
            CapabilityUtils.supportsCapability(
                provider, LLMCapability.streaming),
            isTrue);
        expect(
            CapabilityUtils.supportsCapability(
                provider, LLMCapability.embedding),
            isFalse);
      });

      test('should check multiple capabilities at once', () {
        final provider =
            _MockProvider([LLMCapability.chat, LLMCapability.streaming]);

        final required = {LLMCapability.chat, LLMCapability.streaming};
        expect(CapabilityUtils.supportsAllCapabilities(provider, required),
            isTrue);

        final tooMany = {
          LLMCapability.chat,
          LLMCapability.streaming,
          LLMCapability.embedding
        };
        expect(CapabilityUtils.supportsAllCapabilities(provider, tooMany),
            isFalse);
      });

      test('should check if provider supports any capability', () {
        final provider = _MockProvider([LLMCapability.chat]);

        final someSupported = {LLMCapability.chat, LLMCapability.embedding};
        expect(CapabilityUtils.supportsAnyCapability(provider, someSupported),
            isTrue);

        final noneSupported = {
          LLMCapability.embedding,
          LLMCapability.imageGeneration
        };
        expect(CapabilityUtils.supportsAnyCapability(provider, noneSupported),
            isFalse);
      });
    });

    group('Capability Discovery', () {
      test('should get all supported capabilities', () {
        final provider =
            _MockProvider([LLMCapability.chat, LLMCapability.streaming]);

        final capabilities = CapabilityUtils.getCapabilities(provider);

        expect(capabilities, equals(provider.supportedCapabilities));
        expect(capabilities, contains(LLMCapability.chat));
        expect(capabilities, contains(LLMCapability.streaming));
      });

      test('should get capability summary', () {
        final provider =
            _MockProvider([LLMCapability.chat, LLMCapability.streaming]);

        final summary = CapabilityUtils.getCapabilitySummary(provider);

        expect(summary, isA<Map<String, bool>>());
        expect(summary['chat'], isTrue);
        expect(summary['streaming'], isTrue);
        expect(summary['embedding'], isFalse);
      });

      test('should find missing capabilities', () {
        final provider = _MockProvider([LLMCapability.chat]);
        final required = {
          LLMCapability.chat,
          LLMCapability.streaming,
          LLMCapability.embedding
        };

        final missing =
            CapabilityUtils.getMissingCapabilities(provider, required);

        expect(missing,
            equals({LLMCapability.streaming, LLMCapability.embedding}));
      });

      test('should validate requirements', () {
        final provider =
            _MockProvider([LLMCapability.chat, LLMCapability.streaming]);

        final validRequirements = {LLMCapability.chat};
        expect(
            CapabilityUtils.validateRequirements(provider, validRequirements),
            isTrue);

        final invalidRequirements = {
          LLMCapability.chat,
          LLMCapability.embedding
        };
        expect(
            CapabilityUtils.validateRequirements(provider, invalidRequirements),
            isFalse);
      });
    });

    group('Safe Execution', () {
      test('should execute with capability check', () async {
        final provider = _MockProvider([LLMCapability.chat]);

        // This would work if provider implemented the interface
        final result =
            await CapabilityUtils.withCapability<ProviderCapabilities, String>(
          provider,
          (p) async => 'success',
        );

        expect(result, equals('success'));
      });

      test('should return null when capability not supported', () async {
        final provider = _MockProvider([LLMCapability.chat]);

        // This should return null since provider doesn't implement ChatCapability
        final result =
            await CapabilityUtils.withCapability<ChatCapability, String>(
          provider,
          (p) async => 'success',
        );

        expect(result, isNull);
      });

      test('should throw error when capability required but not supported',
          () async {
        final provider = _MockProvider([LLMCapability.chat]);

        expect(
          () => CapabilityUtils.requireCapability<ChatCapability, String>(
            provider,
            (p) async => 'success',
          ),
          throwsA(isA<CapabilityError>()),
        );
      });
    });

    group('Error Handling', () {
      test('should handle null provider gracefully', () {
        // CapabilityUtils.validateProvider handles null by treating it as no capabilities
        final report =
            CapabilityUtils.validateProvider(null, {LLMCapability.chat});
        expect(report.isValid, isFalse);
        expect(report.missing, contains(LLMCapability.chat));
      });

      test('should handle empty capabilities gracefully', () {
        final provider = _MockProvider([LLMCapability.chat]);
        final emptySet = <LLMCapability>{};
        expect(() => CapabilityUtils.validateProvider(provider, emptySet),
            returnsNormally);
      });
    });
  });
}

/// Mock provider for testing
class _MockProvider implements ProviderCapabilities {
  final Set<LLMCapability> _capabilities;

  _MockProvider(List<LLMCapability> capabilities)
      : _capabilities = Set.from(capabilities);

  @override
  Set<LLMCapability> get supportedCapabilities => _capabilities;

  @override
  bool supports(LLMCapability capability) => _capabilities.contains(capability);

  String get providerId => 'mock';
  String get displayName => 'Mock Provider';
  String get description => 'A mock provider for testing';
}
