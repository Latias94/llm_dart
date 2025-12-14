import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'dart:typed_data';

void main() {
  group('Audio Models Tests', () {
    group('AudioProcessingMode Enum', () {
      test('should have correct values', () {
        expect(AudioProcessingMode.values, hasLength(3));
        expect(AudioProcessingMode.values, contains(AudioProcessingMode.batch));
        expect(AudioProcessingMode.values,
            contains(AudioProcessingMode.streaming));
        expect(
            AudioProcessingMode.values, contains(AudioProcessingMode.realtime));
      });
    });

    group('AudioQuality Enum', () {
      test('should have correct values', () {
        expect(AudioQuality.values, hasLength(4));
        expect(AudioQuality.values, contains(AudioQuality.low));
        expect(AudioQuality.values, contains(AudioQuality.standard));
        expect(AudioQuality.values, contains(AudioQuality.high));
        expect(AudioQuality.values, contains(AudioQuality.ultra));
      });
    });

    group('AudioFormat Enum', () {
      test('should have correct values', () {
        final formats = AudioFormat.values;
        expect(formats, contains(AudioFormat.mp3));
        expect(formats, contains(AudioFormat.wav));
        expect(formats, contains(AudioFormat.flac));
        expect(formats, contains(AudioFormat.aac));
        expect(formats, contains(AudioFormat.ogg));
        expect(formats, contains(AudioFormat.opus));
        expect(formats, contains(AudioFormat.pcm));
      });
    });

    group('TimestampGranularity Enum', () {
      test('should have correct values', () {
        expect(TimestampGranularity.values, hasLength(4));
        expect(
            TimestampGranularity.values, contains(TimestampGranularity.none));
        expect(
            TimestampGranularity.values, contains(TimestampGranularity.word));
        expect(TimestampGranularity.values,
            contains(TimestampGranularity.character));
        expect(TimestampGranularity.values,
            contains(TimestampGranularity.segment));
      });
    });

    group('TTSRequest', () {
      test('should create with required fields', () {
        final request = TTSRequest(
          text: 'Hello, world!',
        );

        expect(request.text, equals('Hello, world!'));
        expect(request.voice, isNull);
        expect(request.model, isNull);
        expect(request.speed, isNull);
        expect(request.format, isNull);
      });

      test('should create with all fields', () {
        final request = TTSRequest(
          text: 'Hello, world!',
          voice: 'alloy',
          model: 'tts-1',
          speed: 1.2,
          format: 'mp3_44100_128',
          quality: 'high',
          stability: 0.8,
          similarityBoost: 0.9,
          style: 0.1,
          useSpeakerBoost: true,
          includeTimestamps: true,
          optimizeStreamingLatency: 2,
          enableLogging: false,
        );

        expect(request.text, equals('Hello, world!'));
        expect(request.voice, equals('alloy'));
        expect(request.model, equals('tts-1'));
        expect(request.speed, equals(1.2));
        expect(request.format, equals('mp3_44100_128'));
        expect(request.quality, equals('high'));
        expect(request.stability, equals(0.8));
        expect(request.similarityBoost, equals(0.9));
        expect(request.style, equals(0.1));
        expect(request.useSpeakerBoost, isTrue);
        expect(request.includeTimestamps, isTrue);
        expect(request.optimizeStreamingLatency, equals(2));
        expect(request.enableLogging, isFalse);
      });

      test('should serialize to JSON correctly', () {
        final request = TTSRequest(
          text: 'Hello, world!',
          voice: 'alloy',
          model: 'tts-1',
          speed: 1.2,
          format: 'mp3_44100_128',
        );

        final json = request.toJson();
        expect(json['text'], equals('Hello, world!'));
        expect(json['voice'], equals('alloy'));
        expect(json['model'], equals('tts-1'));
        expect(json['speed'], equals(1.2));
        expect(json['format'], equals('mp3_44100_128'));
      });
    });

    group('TTSResponse', () {
      test('should create with required fields', () {
        final audioData = Uint8List.fromList([1, 2, 3, 4]);
        final response = TTSResponse(
          audioData: audioData,
        );

        expect(response.audioData, equals(audioData));
        expect(response.contentType, isNull);
        expect(response.duration, isNull);
      });

      test('should create with all fields', () {
        final audioData = Uint8List.fromList([1, 2, 3, 4]);
        final response = TTSResponse(
          audioData: audioData,
          contentType: 'audio/mpeg',
          duration: 5.0,
          sampleRate: 44100,
          voice: 'alloy',
          model: 'tts-1',
          usage: UsageInfo(
            promptTokens: 10,
            completionTokens: 0,
            totalTokens: 10,
          ),
        );

        expect(response.audioData, equals(audioData));
        expect(response.contentType, equals('audio/mpeg'));
        expect(response.duration, equals(5.0));
        expect(response.sampleRate, equals(44100));
        expect(response.voice, equals('alloy'));
        expect(response.model, equals('tts-1'));
        expect(response.usage, isNotNull);
      });
    });

    group('STTRequest', () {
      test('should create from audio data', () {
        final audioData = Uint8List.fromList([1, 2, 3, 4]);
        final request = STTRequest.fromAudio(
          audioData,
          model: 'whisper-1',
          language: 'en',
        );

        expect(request.audioData, equals(audioData));
        expect(request.filePath, isNull);
        expect(request.model, equals('whisper-1'));
        expect(request.language, equals('en'));
      });

      test('should create from cloud storage URL', () {
        const url = 'https://storage.example.com/audio.mp3';
        final request = STTRequest.fromCloudUrl(
          url,
          model: 'whisper-1',
        );

        expect(request.cloudStorageUrl, equals(url));
        expect(request.audioData, isNull);
        expect(request.filePath, isNull);
        expect(request.model, equals('whisper-1'));
      });

      test('should serialize to JSON correctly', () {
        final audioData = Uint8List.fromList([1, 2, 3, 4]);
        final request = STTRequest.fromAudio(
          audioData,
          model: 'whisper-1',
          language: 'en',
          format: 'mp3',
          includeWordTiming: true,
          includeConfidence: true,
          temperature: 0.2,
          timestampGranularity: TimestampGranularity.word,
          diarize: true,
          numSpeakers: 2,
          tagAudioEvents: true,
          webhook: false,
          prompt: 'Transcribe this audio',
          responseFormat: 'json',
          enableLogging: false,
        );

        final json = request.toJson();
        expect(json['audio_data'], equals(audioData));
        expect(json['model'], equals('whisper-1'));
        expect(json['language'], equals('en'));
        expect(json['format'], equals('mp3'));
        expect(json['include_word_timing'], isTrue);
        expect(json['include_confidence'], isTrue);
        expect(json['temperature'], equals(0.2));
        expect(json['timestamp_granularity'], equals('word'));
        expect(json['diarize'], isTrue);
        expect(json['num_speakers'], equals(2));
        expect(json['tag_audio_events'], isTrue);
        expect(json['webhook'], equals(false));
        expect(json['prompt'], equals('Transcribe this audio'));
        expect(json['response_format'], equals('json'));
        expect(json['enable_logging'], isFalse);
      });
    });

    group('STTResponse', () {
      test('should create with required fields', () {
        final response = STTResponse(
          text: 'Hello, world!',
        );

        expect(response.text, equals('Hello, world!'));
        expect(response.language, isNull);
        expect(response.duration, isNull);
        expect(response.segments, isNull);
      });

      test('should create with all fields', () {
        final response = STTResponse(
          text: 'Hello, world!',
          language: 'en',
          duration: 2.0,
          confidence: 0.98,
          model: 'whisper-1',
          usage: UsageInfo(
            promptTokens: 0,
            completionTokens: 5,
            totalTokens: 5,
          ),
        );

        expect(response.text, equals('Hello, world!'));
        expect(response.language, equals('en'));
        expect(response.duration, equals(2.0));
        expect(response.confidence, equals(0.98));
        expect(response.model, equals('whisper-1'));
        expect(response.usage, isNotNull);
      });
    });
  });
}
