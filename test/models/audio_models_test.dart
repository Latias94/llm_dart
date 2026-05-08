import 'dart:typed_data';

import 'package:llm_dart/models/audio_models.dart';
import 'package:llm_dart/models/usage_models.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('Audio Models Tests', () {
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
        expect(request.providerOptions, isNull);
      });

      test('should retain provider invocation options', () {
        const options = _TestAudioProviderOptions();
        const request = TTSRequest(
          text: 'Hello, world!',
          providerOptions: options,
        );

        expect(request.providerOptions, same(options));
        expect(request.toJson().containsKey('provider_options'), isFalse);
      });

      test('should create with all fields', () {
        final request = TTSRequest(
          text: 'Hello, world!',
          voice: 'alloy',
          model: 'tts-1',
          speed: 1.2,
          format: 'mp3_44100_128',
          quality: 'high',
          sampleRate: 44100,
          languageCode: 'en',
        );

        expect(request.text, equals('Hello, world!'));
        expect(request.voice, equals('alloy'));
        expect(request.model, equals('tts-1'));
        expect(request.speed, equals(1.2));
        expect(request.format, equals('mp3_44100_128'));
        expect(request.quality, equals('high'));
        expect(request.sampleRate, equals(44100));
        expect(request.languageCode, equals('en'));
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
        final providerMetadata = ProviderMetadata.forNamespace(
          'elevenlabs',
          {'requestId': 'req_123'},
        );
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
          providerMetadata: providerMetadata,
        );

        expect(response.audioData, equals(audioData));
        expect(response.contentType, equals('audio/mpeg'));
        expect(response.duration, equals(5.0));
        expect(response.sampleRate, equals(44100));
        expect(response.voice, equals('alloy'));
        expect(response.model, equals('tts-1'));
        expect(response.usage, isNotNull);
        expect(
          response.providerMetadata?.namespace('elevenlabs')?['requestId'],
          equals('req_123'),
        );
      });

      test('should serialize provider metadata', () {
        final response = TTSResponse(
          audioData: const [1, 2, 3],
          providerMetadata: ProviderMetadata.forNamespace(
            'openai',
            {'responseFormat': 'mp3'},
          ),
        );

        final json = response.toJson();
        expect(
          json['provider_metadata']['openai']['responseFormat'],
          equals('mp3'),
        );

        final restored = TTSResponse.fromJson(json);
        expect(
          restored.providerMetadata?.namespace('openai')?['responseFormat'],
          equals('mp3'),
        );
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
        expect(request.providerOptions, isNull);
      });

      test('should retain provider invocation options', () {
        const options = _TestAudioProviderOptions();
        final request = STTRequest.fromAudio(
          [1, 2, 3],
          providerOptions: options,
        );

        expect(request.providerOptions, same(options));
        expect(request.toJson().containsKey('provider_options'), isFalse);
      });

      test('should create from source URL', () {
        const url = 'https://storage.example.com/audio.mp3';
        final request = STTRequest.fromSourceUrl(
          url,
          model: 'whisper-1',
        );

        expect(request.sourceUrl, equals(url));
        expect(request.audioData, isNull);
        expect(request.filePath, isNull);
        expect(request.model, equals('whisper-1'));
      });

      test('should serialize source URL correctly', () {
        const url = 'https://storage.example.com/audio.mp3';
        final request = STTRequest.fromSourceUrl(url);

        final json = request.toJson();
        expect(json['source_url'], equals(url));
        expect(json['cloud_storage_url'], equals(url));

        final restored = STTRequest.fromJson(json);
        expect(restored.sourceUrl, equals(url));
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
          timestampGranularity: TimestampGranularity.word,
        );

        final json = request.toJson();
        expect(json['audio_data'], equals(audioData));
        expect(json['model'], equals('whisper-1'));
        expect(json['language'], equals('en'));
        expect(json['format'], equals('mp3'));
        expect(json['include_word_timing'], isTrue);
        expect(json['include_confidence'], isTrue);
        expect(json['timestamp_granularity'], equals('word'));
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
        final providerMetadata = ProviderMetadata.forNamespace(
          'openai',
          {'durationSeconds': 2.0},
        );
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
          providerMetadata: providerMetadata,
        );

        expect(response.text, equals('Hello, world!'));
        expect(response.language, equals('en'));
        expect(response.duration, equals(2.0));
        expect(response.confidence, equals(0.98));
        expect(response.model, equals('whisper-1'));
        expect(response.usage, isNotNull);
        expect(
          response.providerMetadata?.namespace('openai')?['durationSeconds'],
          equals(2.0),
        );
      });
    });
  });
}

final class _TestAudioProviderOptions implements ProviderInvocationOptions {
  const _TestAudioProviderOptions();
}
