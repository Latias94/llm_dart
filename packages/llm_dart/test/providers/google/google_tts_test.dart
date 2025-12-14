import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('Google TTS', () {
    test('GoogleTTSRequest.singleSpeaker creates valid request', () {
      final request = GoogleTTSRequest.singleSpeaker(
        text: 'Hello, world!',
        voiceName: 'Kore',
      );

      expect(request.text, equals('Hello, world!'));
      expect(request.voiceConfig, isNotNull);
      expect(
          request.voiceConfig!.prebuiltVoiceConfig!.voiceName, equals('Kore'));
      expect(request.multiSpeakerVoiceConfig, isNull);
    });

    test('GoogleTTSRequest.multiSpeaker creates valid request', () {
      final request = GoogleTTSRequest.multiSpeaker(
        text: 'Joe: Hello\nJane: Hi there!',
        speakers: [
          GoogleSpeakerVoiceConfig(
            speaker: 'Joe',
            voiceConfig: GoogleVoiceConfig.prebuilt('Kore'),
          ),
          GoogleSpeakerVoiceConfig(
            speaker: 'Jane',
            voiceConfig: GoogleVoiceConfig.prebuilt('Puck'),
          ),
        ],
      );

      expect(request.text, equals('Joe: Hello\nJane: Hi there!'));
      expect(request.voiceConfig, isNull);
      expect(request.multiSpeakerVoiceConfig, isNotNull);
      expect(request.multiSpeakerVoiceConfig!.speakerVoiceConfigs.length,
          equals(2));
    });

    test('GoogleTTSRequest.toJson generates correct structure', () {
      final request = GoogleTTSRequest.singleSpeaker(
        text: 'Test text',
        voiceName: 'Kore',
        model: 'gemini-2.5-flash-preview-tts',
      );

      final json = request.toJson();

      expect(json['contents'], isA<List>());
      expect(json['contents'][0]['parts'][0]['text'], equals('Test text'));
      expect(json['generationConfig']['responseModalities'], equals(['AUDIO']));
      expect(
          json['generationConfig']['speechConfig']['voiceConfig'], isNotNull);
      expect(json['model'], equals('gemini-2.5-flash-preview-tts'));
    });

    test('GoogleVoiceConfig.prebuilt creates correct configuration', () {
      final voiceConfig = GoogleVoiceConfig.prebuilt('Puck');
      final json = voiceConfig.toJson();

      expect(json['prebuiltVoiceConfig']['voiceName'], equals('Puck'));
    });

    test('GoogleTTSCapability.getPredefinedVoices returns all 30 voices', () {
      final voices = GoogleTTSCapability.getPredefinedVoices();

      expect(voices.length, equals(30));

      // Check some specific voices
      final voiceNames = voices.map((v) => v.name).toSet();
      expect(voiceNames.contains('Kore'), isTrue);
      expect(voiceNames.contains('Puck'), isTrue);
      expect(voiceNames.contains('Zephyr'), isTrue);
      expect(voiceNames.contains('Enceladus'), isTrue);
      expect(voiceNames.contains('Sulafat'), isTrue);
    });

    test(
        'GoogleTTSCapability.getSupportedLanguageCodes returns all 24 languages',
        () {
      final languages = GoogleTTSCapability.getSupportedLanguageCodes();

      expect(languages.length, equals(24));

      // Check some specific languages
      expect(languages.contains('en-US'), isTrue);
      expect(languages.contains('ja-JP'), isTrue);
      expect(languages.contains('zh-CN'), isFalse); // Not in the supported list
      expect(languages.contains('fr-FR'), isTrue);
      expect(languages.contains('de-DE'), isTrue);
    });

    test('GoogleTTSResponse.fromApiResponse parses valid response', () {
      final apiResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'inlineData': {
                    'data': 'SGVsbG8gV29ybGQ=', // "Hello World" in base64
                    'mimeType': 'audio/pcm',
                  }
                }
              ]
            }
          }
        ],
        'usageMetadata': {
          'promptTokenCount': 10,
          'candidatesTokenCount': 5,
          'totalTokenCount': 15,
        },
        'modelVersion': 'gemini-2.5-flash-preview-tts',
      };

      final response = GoogleTTSResponse.fromApiResponse(apiResponse);

      expect(response.audioData, isNotEmpty);
      expect(response.contentType, equals('audio/pcm'));
      expect(response.usage, isNotNull);
      expect(response.usage!.promptTokens, equals(10));
      expect(response.usage!.completionTokens, equals(5));
      expect(response.usage!.totalTokens, equals(15));
      expect(response.model, equals('gemini-2.5-flash-preview-tts'));
    });

    test('GoogleTTSResponse.fromApiResponse throws on missing audio data', () {
      final apiResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'No audio data here'}
              ]
            }
          }
        ],
      };

      expect(
        () => GoogleTTSResponse.fromApiResponse(apiResponse),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('GoogleTTSRequest validates voice configuration requirement', () {
      expect(
        () => GoogleTTSRequest(
          text: 'Test',
          // Neither voiceConfig nor multiSpeakerVoiceConfig provided
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('GoogleSpeakerVoiceConfig creates correct JSON structure', () {
      final speakerConfig = GoogleSpeakerVoiceConfig(
        speaker: 'TestSpeaker',
        voiceConfig: GoogleVoiceConfig.prebuilt('Kore'),
      );

      final json = speakerConfig.toJson();

      expect(json['speaker'], equals('TestSpeaker'));
      expect(json['voiceConfig']['prebuiltVoiceConfig']['voiceName'],
          equals('Kore'));
    });

    test('GoogleVoiceInfo serialization works correctly', () {
      final voiceInfo = GoogleVoiceInfo(
        name: 'TestVoice',
        description: 'Test Description',
        category: 'Test Category',
        supportsMultiSpeaker: false,
      );

      final json = voiceInfo.toJson();
      final restored = GoogleVoiceInfo.fromJson(json);

      expect(restored.name, equals(voiceInfo.name));
      expect(restored.description, equals(voiceInfo.description));
      expect(restored.category, equals(voiceInfo.category));
      expect(restored.supportsMultiSpeaker,
          equals(voiceInfo.supportsMultiSpeaker));
    });

    test('GoogleTTSStreamEvent types are correctly defined', () {
      final audioEvent = GoogleTTSAudioDataEvent(data: [1, 2, 3]);
      final metadataEvent = GoogleTTSMetadataEvent(contentType: 'audio/pcm');
      final errorEvent = GoogleTTSErrorEvent(message: 'Test error');

      expect(audioEvent, isA<GoogleTTSStreamEvent>());
      expect(metadataEvent, isA<GoogleTTSStreamEvent>());
      expect(errorEvent, isA<GoogleTTSStreamEvent>());

      expect(audioEvent.data, equals([1, 2, 3]));
      expect(metadataEvent.contentType, equals('audio/pcm'));
      expect(errorEvent.message, equals('Test error'));
    });
  });
}
