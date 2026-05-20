import 'dart:convert';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_openai/src/transcription/openai_transcription_model_body.dart';
import 'package:llm_dart_openai/src/transcription/openai_transcription_model_request.dart';
import 'package:llm_dart_openai/src/transcription/openai_transcription_options.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI transcription multipart body projection', () {
    test('maps transcription options to OpenAI multipart fields', () {
      final body = buildOpenAITranscriptionMultipartBody(
        modelId: 'whisper-1',
        request: TranscriptionRequest(
          audioBytes: utf8.encode('abc'),
          mediaType: 'audio/wav',
        ),
        options: const OpenAITranscriptionOptions(
          include: ['logprobs'],
          language: 'en',
          prompt: 'Prefer short output.',
          temperature: 0.2,
          responseFormat: OpenAITranscriptionResponseFormat.verboseJson,
          timestampGranularities: [
            OpenAITranscriptionTimestampGranularity.word,
          ],
        ),
        responseFormat: OpenAITranscriptionResponseFormat.verboseJson,
      );

      final bodyText = utf8.decode(body.bytes);

      expect(body.contentType, startsWith('multipart/form-data; boundary='));
      expect(bodyText, contains('name="file"; filename="audio.wav"'));
      expect(bodyText, contains('Content-Type: audio/wav'));
      expect(bodyText, contains('name="model"'));
      expect(bodyText, contains('whisper-1'));
      expect(bodyText, contains('name="include[]"'));
      expect(bodyText, contains('logprobs'));
      expect(bodyText, contains('name="language"'));
      expect(bodyText, contains('en'));
      expect(bodyText, contains('name="prompt"'));
      expect(bodyText, contains('Prefer short output.'));
      expect(bodyText, contains('name="temperature"'));
      expect(bodyText, contains('0.2'));
      expect(bodyText, contains('name="response_format"'));
      expect(bodyText, contains('verbose_json'));
      expect(bodyText, contains('name="timestamp_granularities[]"'));
      expect(bodyText, contains('word'));
    });

    test('defaults temperature when provider options are present', () {
      final body = buildOpenAITranscriptionMultipartBody(
        modelId: 'gpt-4o-transcribe',
        request: TranscriptionRequest(
          audioBytes: utf8.encode('abc'),
          mediaType: 'audio/mpeg',
        ),
        options: const OpenAITranscriptionOptions(
          timestampGranularities: [
            OpenAITranscriptionTimestampGranularity.word,
          ],
        ),
        responseFormat: OpenAITranscriptionResponseFormat.json,
      );

      final bodyText = utf8.decode(body.bytes);

      expect(bodyText, contains('name="file"; filename="audio.mp3"'));
      expect(bodyText, contains('name="temperature"'));
      expect(bodyText, contains('0'));
      expect(bodyText, contains('name="response_format"'));
      expect(bodyText, contains('json'));
      expect(bodyText, contains('name="timestamp_granularities[]"'));
      expect(bodyText, contains('word'));
    });

    test('uses bin extension for unknown audio media types', () {
      final body = buildOpenAITranscriptionMultipartBody(
        modelId: 'whisper-1',
        request: TranscriptionRequest(
          audioBytes: utf8.encode('abc'),
          mediaType: 'audio/custom',
        ),
        options: null,
        responseFormat: OpenAITranscriptionResponseFormat.json,
      );

      final bodyText = utf8.decode(body.bytes);

      expect(bodyText, contains('name="file"; filename="audio.bin"'));
      expect(bodyText, isNot(contains('name="temperature"')));
      expect(bodyText, contains('name="response_format"'));
      expect(bodyText, contains('json'));
    });

    test('normalizes media type parameters for generated filenames', () {
      final body = buildOpenAITranscriptionMultipartBody(
        modelId: 'whisper-1',
        request: TranscriptionRequest(
          audioBytes: utf8.encode('abc'),
          mediaType: 'Audio/MPEG; codecs=mp3',
        ),
        options: null,
        responseFormat: OpenAITranscriptionResponseFormat.json,
      );

      final bodyText = utf8.decode(body.bytes);

      expect(bodyText, contains('name="file"; filename="audio.mp3"'));
    });

    test('resolves transcription options from provider options bag', () {
      final options = resolveOpenAITranscriptionProviderOptions(
        CallOptions(
          providerOptions: ProviderOptionsBag.forProvider('openai', {
            'include': ['logprobs'],
            'language': 'en',
            'prompt': 'Prefer short output.',
            'temperature': 0.3,
            'response_format': 'verbose_json',
            'timestamp_granularities': ['segment'],
          }),
        ),
      );
      final responseFormat = resolveOpenAITranscriptionResponseFormat(
        modelId: 'whisper-1',
        options: options,
      );
      final body = buildOpenAITranscriptionMultipartBody(
        modelId: 'whisper-1',
        request: TranscriptionRequest(
          audioBytes: utf8.encode('abc'),
          mediaType: 'audio/wav',
        ),
        options: options,
        responseFormat: responseFormat,
      );
      final bodyText = utf8.decode(body.bytes);

      expect(bodyText, contains('logprobs'));
      expect(bodyText, contains('en'));
      expect(bodyText, contains('Prefer short output.'));
      expect(bodyText, contains('0.3'));
      expect(bodyText, contains('verbose_json'));
      expect(bodyText, contains('segment'));
    });
  });
}
