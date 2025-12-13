import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LLMBuilder audio extensions', () {
    test('audioFormat() sets LLMConfigKeys.audioFormat', () {
      final builder = LLMBuilder().audioFormat('mp3');
      expect(
        builder.currentConfig.getExtension<String>(LLMConfigKeys.audioFormat),
        equals('mp3'),
      );
    });

    test('audioQuality() sets LLMConfigKeys.audioQuality', () {
      final builder = LLMBuilder().audioQuality('high');
      expect(
        builder.currentConfig.getExtension<String>(LLMConfigKeys.audioQuality),
        equals('high'),
      );
    });

    test('sampleRate() sets LLMConfigKeys.sampleRate', () {
      final builder = LLMBuilder().sampleRate(44100);
      expect(
        builder.currentConfig.getExtension<int>(LLMConfigKeys.sampleRate),
        equals(44100),
      );
    });

    test('languageCode() sets LLMConfigKeys.languageCode', () {
      final builder = LLMBuilder().languageCode('en-US');
      expect(
        builder.currentConfig.getExtension<String>(LLMConfigKeys.languageCode),
        equals('en-US'),
      );
    });

    test('includeTimestamps() sets LLMConfigKeys.includeTimestamps', () {
      final builder = LLMBuilder().includeTimestamps(true);
      expect(
        builder.currentConfig
            .getExtension<bool>(LLMConfigKeys.includeTimestamps),
        isTrue,
      );
    });

    test('timestampGranularity() sets LLMConfigKeys.timestampGranularity', () {
      final builder = LLMBuilder().timestampGranularity('word');
      expect(
        builder.currentConfig
            .getExtension<String>(LLMConfigKeys.timestampGranularity),
        equals('word'),
      );
    });

    test('diarize() and numSpeakers() set STT-related keys', () {
      final builder = LLMBuilder().diarize(true).numSpeakers(3);
      final config = builder.currentConfig;

      expect(config.getExtension<bool>(LLMConfigKeys.diarize), isTrue);
      expect(config.getExtension<int>(LLMConfigKeys.numSpeakers), equals(3));
    });

    test('method chaining sets multiple keys', () {
      final builder = LLMBuilder()
          .audioFormat('wav')
          .audioQuality('high')
          .sampleRate(48000)
          .languageCode('en-US')
          .includeTimestamps(true)
          .timestampGranularity('segment');

      final config = builder.currentConfig;
      expect(config.getExtension<String>(LLMConfigKeys.audioFormat), 'wav');
      expect(config.getExtension<String>(LLMConfigKeys.audioQuality), 'high');
      expect(config.getExtension<int>(LLMConfigKeys.sampleRate), 48000);
      expect(config.getExtension<String>(LLMConfigKeys.languageCode), 'en-US');
      expect(config.getExtension<bool>(LLMConfigKeys.includeTimestamps), isTrue);
      expect(
        config.getExtension<String>(LLMConfigKeys.timestampGranularity),
        'segment',
      );
    });
  });
}

