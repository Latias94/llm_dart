import 'package:dio/dio.dart' hide CancelToken;
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:test/test.dart';

class _FakeOpenAIClient extends OpenAIClient {
  String? lastEndpoint;
  Map<String, dynamic>? lastJsonBody;
  FormData? lastFormData;

  Map<String, dynamic> formResponse = const {'text': 'hello'};
  List<int> rawResponse = const [1, 2, 3];

  _FakeOpenAIClient(super.config);

  @override
  Future<List<int>> postRaw(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastJsonBody = body;
    return rawResponse;
  }

  @override
  Future<Map<String, dynamic>> postForm(
    String endpoint,
    FormData formData, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastFormData = formData;
    return formResponse;
  }
}

void main() {
  group('OpenAI-compatible audio providerMetadata', () {
    test('textToSpeech uses normalized providerId for metadata keys', () async {
      final config = OpenAICompatibleConfig(
        providerId: '',
        providerName: 'OpenAI-Compatible',
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o',
      );

      final client = _FakeOpenAIClient(config);
      final audio = OpenAIStyleAudio(client, config);

      final resp = await audio.textToSpeech(const TTSRequest(text: 'hi'));

      expect(client.lastEndpoint, 'audio/speech');
      expect(resp.model, openaiStyleDefaultTTSModel);

      final meta = resp.providerMetadata;
      expect(meta, isNotNull);
      expect(meta!.containsKey('openai'), isTrue);
      expect(meta.containsKey('openai.speech'), isTrue);
      expect(meta.containsKey('.speech'), isFalse);

      expect(
        meta['openai.speech'],
        equals({
          'model': openaiStyleDefaultTTSModel,
          'endpoint': 'audio/speech',
        }),
      );
    });

    test('speechToText includes endpoint + model in providerMetadata',
        () async {
      final config = OpenAICompatibleConfig(
        providerId: 'azure-openai',
        providerName: 'Azure OpenAI',
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o',
      );

      final client = _FakeOpenAIClient(config);
      client.formResponse = const {'text': 'hello'};

      final audio = OpenAIStyleAudio(client, config);

      final resp = await audio.speechToText(
        const STTRequest(
          audioData: [1, 2, 3],
          model: 'whisper-1',
        ),
      );

      expect(client.lastEndpoint, 'audio/transcriptions');
      expect(resp.text, 'hello');
      expect(resp.model, 'whisper-1');

      final meta = resp.providerMetadata;
      expect(meta, isNotNull);
      expect(meta!.containsKey('azure-openai'), isTrue);
      expect(meta.containsKey('azure-openai.transcription'), isTrue);
      expect(
        meta['azure-openai.transcription'],
        equals({
          'model': 'whisper-1',
          'endpoint': 'audio/transcriptions',
        }),
      );
    });

    test('translateAudio uses transcription capability namespace', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'openrouter',
        providerName: 'OpenRouter',
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o',
      );

      final client = _FakeOpenAIClient(config);
      client.formResponse = const {'text': 'hello'};

      final audio = OpenAIStyleAudio(client, config);

      final resp = await audio.translateAudio(
        const AudioTranslationRequest(
          audioData: [1, 2, 3],
          model: 'whisper-1',
        ),
      );

      expect(client.lastEndpoint, 'audio/translations');
      expect(resp.text, 'hello');

      final meta = resp.providerMetadata;
      expect(meta, isNotNull);
      expect(meta!.containsKey('openrouter'), isTrue);
      expect(meta.containsKey('openrouter.transcription'), isTrue);
      expect(
        meta['openrouter.transcription'],
        equals({
          'model': 'whisper-1',
          'endpoint': 'audio/translations',
        }),
      );
    });
  });
}
