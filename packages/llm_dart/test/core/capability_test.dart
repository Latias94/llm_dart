import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('Capability System Tests', () {
    group('LLMCapability Enum', () {
      test('should have all expected capabilities', () {
        final capabilities = LLMCapability.values;

        expect(capabilities, contains(LLMCapability.chat));
        expect(capabilities, contains(LLMCapability.streaming));
        expect(capabilities, contains(LLMCapability.embedding));
        expect(capabilities, contains(LLMCapability.modelListing));
        expect(capabilities, contains(LLMCapability.toolCalling));
        expect(capabilities, contains(LLMCapability.reasoning));
        expect(capabilities, contains(LLMCapability.vision));
        expect(capabilities, contains(LLMCapability.textToSpeech));
        expect(capabilities, contains(LLMCapability.speechToText));
        expect(capabilities, contains(LLMCapability.imageGeneration));
        expect(capabilities, contains(LLMCapability.fileManagement));
        expect(capabilities, contains(LLMCapability.moderation));
        expect(capabilities, contains(LLMCapability.assistants));
      });

      test('should convert to string correctly', () {
        expect(LLMCapability.chat.toString(), equals('LLMCapability.chat'));
        expect(LLMCapability.streaming.toString(),
            equals('LLMCapability.streaming'));
        expect(LLMCapability.toolCalling.toString(),
            equals('LLMCapability.toolCalling'));
      });
    });

    group('AudioFeature Enum', () {
      test('should have all expected audio features', () {
        final features = AudioFeature.values;

        expect(features, contains(AudioFeature.textToSpeech));
        expect(features, contains(AudioFeature.speechToText));
        expect(features, contains(AudioFeature.audioTranslation));
        expect(features, contains(AudioFeature.realtimeProcessing));
        expect(features, contains(AudioFeature.voiceCloning));
        expect(features, contains(AudioFeature.audioEnhancement));
        expect(features, contains(AudioFeature.streamingTTS));
        expect(features, contains(AudioFeature.speakerDiarization));
        expect(features, contains(AudioFeature.characterTiming));
        expect(features, contains(AudioFeature.audioEventDetection));
        expect(features, contains(AudioFeature.multimodalAudio));
      });
    });

    group('ServiceTier Enum', () {
      test('should have correct values', () {
        expect(ServiceTier.auto.value, equals('auto'));
        expect(ServiceTier.standard.value, equals('standard_only'));
        expect(ServiceTier.priority.value, equals('priority'));
      });

      test('should convert from string correctly', () {
        expect(ServiceTier.fromString('auto'), equals(ServiceTier.auto));
        expect(
            ServiceTier.fromString('standard'), equals(ServiceTier.standard));
        expect(ServiceTier.fromString('standard_only'),
            equals(ServiceTier.standard));
        expect(
            ServiceTier.fromString('priority'), equals(ServiceTier.priority));
      });

      test('should return null for invalid string', () {
        expect(ServiceTier.fromString('invalid'), isNull);
        expect(ServiceTier.fromString(null), isNull);
      });
    });

    group('ReasoningEffort Enum', () {
      test('should have correct values', () {
        expect(ReasoningEffort.low.value, equals('low'));
        expect(ReasoningEffort.medium.value, equals('medium'));
        expect(ReasoningEffort.high.value, equals('high'));
      });

      test('should convert from string correctly', () {
        expect(ReasoningEffort.fromString('low'), equals(ReasoningEffort.low));
        expect(ReasoningEffort.fromString('medium'),
            equals(ReasoningEffort.medium));
        expect(
            ReasoningEffort.fromString('high'), equals(ReasoningEffort.high));
      });

      test('should return null for invalid string', () {
        expect(ReasoningEffort.fromString('invalid'), isNull);
        expect(ReasoningEffort.fromString(null), isNull);
      });
    });

    group('UsageInfo', () {
      test('should create with all parameters', () {
        final usage = UsageInfo(
          promptTokens: 100,
          completionTokens: 50,
          totalTokens: 150,
          reasoningTokens: 25,
        );

        expect(usage.promptTokens, equals(100));
        expect(usage.completionTokens, equals(50));
        expect(usage.totalTokens, equals(150));
        expect(usage.reasoningTokens, equals(25));
      });

      test('should create with minimal parameters', () {
        final usage = UsageInfo(
          promptTokens: 100,
          completionTokens: 50,
          totalTokens: 150,
        );

        expect(usage.promptTokens, equals(100));
        expect(usage.completionTokens, equals(50));
        expect(usage.totalTokens, equals(150));
        expect(usage.reasoningTokens, isNull);
      });

      test('should serialize to JSON correctly', () {
        final usage = UsageInfo(
          promptTokens: 100,
          completionTokens: 50,
          totalTokens: 150,
          reasoningTokens: 25,
        );

        final json = usage.toJson();
        expect(json['prompt_tokens'], equals(100));
        expect(json['completion_tokens'], equals(50));
        expect(json['total_tokens'], equals(150));
        expect(json['reasoning_tokens'], equals(25));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'prompt_tokens': 100,
          'completion_tokens': 50,
          'total_tokens': 150,
          'reasoning_tokens': 25,
        };

        final usage = UsageInfo.fromJson(json);
        expect(usage.promptTokens, equals(100));
        expect(usage.completionTokens, equals(50));
        expect(usage.totalTokens, equals(150));
        expect(usage.reasoningTokens, equals(25));
      });
    });
  });
}
