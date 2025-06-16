import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('AudioConfig', () {
    late AudioConfig config;

    setUp(() {
      config = AudioConfig();
    });

    test('creates empty configuration by default', () {
      final result = config.build();
      expect(result, isEmpty);
    });

    test('format() sets audio format', () {
      config.format('mp3');
      final result = config.build();
      expect(result['audioFormat'], equals('mp3'));
    });

    test('quality() sets audio quality', () {
      config.quality('high');
      final result = config.build();
      expect(result['audioQuality'], equals('high'));
    });

    test('sampleRate() sets sample rate', () {
      config.sampleRate(44100);
      final result = config.build();
      expect(result['sampleRate'], equals(44100));
    });

    test('languageCode() sets language code', () {
      config.languageCode('en-US');
      final result = config.build();
      expect(result['languageCode'], equals('en-US'));
    });

    test('voice() sets voice name', () {
      config.voice('alloy');
      final result = config.build();
      expect(result['voice'], equals('alloy'));
    });

    test('voiceId() sets voice ID for ElevenLabs', () {
      config.voiceId('voice-123');
      final result = config.build();
      expect(result['voiceId'], equals('voice-123'));
    });

    test('stability() sets stability parameter', () {
      config.stability(0.5);
      final result = config.build();
      expect(result['stability'], equals(0.5));
    });

    test('similarityBoost() sets similarity boost parameter', () {
      config.similarityBoost(0.8);
      final result = config.build();
      expect(result['similarityBoost'], equals(0.8));
    });

    test('style() sets style parameter', () {
      config.style(0.3);
      final result = config.build();
      expect(result['style'], equals(0.3));
    });

    test('useSpeakerBoost() enables speaker boost', () {
      config.useSpeakerBoost(true);
      final result = config.build();
      expect(result['useSpeakerBoost'], isTrue);
    });

    test('diarize() enables diarization', () {
      config.diarize(true);
      final result = config.build();
      expect(result['diarize'], isTrue);
    });

    test('numSpeakers() sets number of speakers', () {
      config.numSpeakers(3);
      final result = config.build();
      expect(result['numSpeakers'], equals(3));
    });

    test('includeTimestamps() enables timestamp inclusion', () {
      config.includeTimestamps(true);
      final result = config.build();
      expect(result['includeTimestamps'], isTrue);
    });

    test('timestampGranularity() sets timestamp granularity', () {
      config.timestampGranularity('word');
      final result = config.build();
      expect(result['timestampGranularity'], equals('word'));
    });

    test('method chaining works correctly', () {
      final result = config
          .format('wav')
          .quality('high')
          .sampleRate(48000)
          .languageCode('en-US')
          .voice('nova')
          .build();

      expect(result['audioFormat'], equals('wav'));
      expect(result['audioQuality'], equals('high'));
      expect(result['sampleRate'], equals(48000));
      expect(result['languageCode'], equals('en-US'));
      expect(result['voice'], equals('nova'));
    });

    test('ElevenLabs specific configuration', () {
      final result = config
          .voiceId('voice-123')
          .stability(0.7)
          .similarityBoost(0.9)
          .style(0.4)
          .useSpeakerBoost(true)
          .build();

      expect(result['voiceId'], equals('voice-123'));
      expect(result['stability'], equals(0.7));
      expect(result['similarityBoost'], equals(0.9));
      expect(result['style'], equals(0.4));
      expect(result['useSpeakerBoost'], isTrue);
    });

    test('STT specific configuration', () {
      final result = config
          .diarize(true)
          .numSpeakers(2)
          .includeTimestamps(true)
          .timestampGranularity('segment')
          .build();

      expect(result['diarize'], isTrue);
      expect(result['numSpeakers'], equals(2));
      expect(result['includeTimestamps'], isTrue);
      expect(result['timestampGranularity'], equals('segment'));
    });

    test('build() returns a copy of the configuration', () {
      config.format('mp3');
      final result1 = config.build();
      final result2 = config.build();

      expect(identical(result1, result2), isFalse);
      expect(result1, equals(result2));
    });

    test('configuration can be modified after build', () {
      config.format('mp3');
      final result1 = config.build();

      config.quality('high');
      final result2 = config.build();

      expect(result1.length, equals(1));
      expect(result2.length, equals(2));
      expect(result1['audioFormat'], equals('mp3'));
      expect(result2['audioFormat'], equals('mp3'));
      expect(result2['audioQuality'], equals('high'));
    });
  });
}
