import 'dart:convert';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  final fixtures = ProviderCodecContractRunner.forWorkspacePackage(
    'llm_dart_elevenlabs',
    label: 'ElevenLabs fixture contract',
  );

  group('ElevenLabs fixture contract', () {
    test('locks speech request transport contract', () async {
      TransportRequest? capturedRequest;

      final model = ElevenLabs(
        apiKey: 'test-key',
        baseUrl: 'https://api.elevenlabs.io/v1/',
        transport: FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              headers: {
                'content-type': 'audio/mpeg',
                'x-request-id': 'req_123',
              },
              body: [1, 2, 3, 4],
            );
          },
        ),
      ).speechModel(
        'eleven_multilingual_v2',
        settings: const ElevenLabsSpeechModelSettings(
          headers: {
            'x-settings': '1',
          },
          defaultVoiceId: 'voice_default',
          stability: 0.3,
          similarityBoost: 0.4,
          style: 0.5,
          useSpeakerBoost: true,
        ),
      );

      await generateSpeech(
        model: model,
        text: 'Hello world.',
        outputFormat: 'pcm',
        language: 'en',
        speed: 1.1,
        callOptions: const CallOptions(
          timeout: Duration(seconds: 5),
          headers: {
            'x-request': 'request-header',
          },
          providerOptions: ElevenLabsSpeechOptions(
            pronunciationDictionaryLocators: [
              ElevenLabsPronunciationDictionaryLocator(
                pronunciationDictionaryId: 'dict_1',
                versionId: 'v1',
              ),
            ],
            seed: 7,
            previousText: 'Earlier text.',
            nextText: 'Later text.',
            previousRequestIds: ['req_prev'],
            nextRequestIds: ['req_next'],
            textNormalization: ElevenLabsTextNormalization.off,
            applyLanguageTextNormalization: true,
            enableLogging: false,
            optimizeStreamingLatency: 2,
            stability: 0.8,
            similarityBoost: 0.9,
            style: 1.0,
            useSpeakerBoost: false,
          ),
        ),
      );

      fixtures.expectJsonFixture(
        'elevenlabs/speech_request_contract_golden.json',
        _transportRequestJson(capturedRequest!),
      );
    });

    test('locks transcription multipart transport contract', () async {
      TransportRequest? capturedRequest;

      final model = ElevenLabs(
        apiKey: 'test-key',
        transport: FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'text': 'hello world',
              },
            );
          },
        ),
      ).transcriptionModel(
        'scribe_v1',
        settings: const ElevenLabsTranscriptionModelSettings(
          headers: {
            'x-settings': '1',
          },
        ),
      );

      await transcribe(
        model: model,
        audioBytes: utf8.encode('abc'),
        mediaType: 'audio/mpeg',
        callOptions: const CallOptions(
          timeout: Duration(seconds: 5),
          headers: {
            'x-request': 'request-header',
          },
          providerOptions: ElevenLabsTranscriptionOptions(
            languageCode: 'en',
            tagAudioEvents: false,
            numSpeakers: 2,
            timestampGranularity:
                ElevenLabsTranscriptionTimestampGranularity.character,
            diarize: true,
            fileFormat: ElevenLabsTranscriptionFileFormat.pcmS16le16,
            enableLogging: false,
          ),
        ),
      );

      fixtures.expectJsonFixture(
        'elevenlabs/transcription_request_contract_golden.json',
        _multipartTransportRequestJson(capturedRequest!),
      );
    });
  });
}

Map<String, Object?> _transportRequestJson(TransportRequest request) {
  return {
    'uri': request.uri.toString(),
    'method': request.method.name,
    'responseType': request.responseType.name,
    'headers': request.headers,
    'body': request.body,
  };
}

Map<String, Object?> _multipartTransportRequestJson(TransportRequest request) {
  return {
    'uri': request.uri.toString(),
    'method': request.method.name,
    'responseType': request.responseType.name,
    'headers': {
      'xi-api-key': request.headers['xi-api-key'],
      'x-settings': request.headers['x-settings'],
      'x-request': request.headers['x-request'],
      'accept': request.headers['accept'],
    },
    'multipart': _multipartFields(request),
  };
}

Map<String, Object?> _multipartFields(TransportRequest request) {
  final contentType = request.headers['content-type'];
  final boundary = RegExp(r'boundary=([^;]+)').firstMatch(contentType!)![1]!;
  final body = utf8.decode(request.body! as List<int>);
  final fields = <String, Object?>{};

  for (final rawPart in body.split('--$boundary')) {
    final part = rawPart.trim();
    if (part.isEmpty || part == '--') {
      continue;
    }

    final sections = part.split('\r\n\r\n');
    if (sections.length != 2) {
      continue;
    }

    final headerLines = sections.first.split('\r\n');
    final content = sections.last.replaceFirst(RegExp(r'\r\n--$'), '');
    final disposition = headerLines.firstWhere(
      (line) => line.startsWith('Content-Disposition:'),
    );
    final name = RegExp(r'name="([^"]+)"').firstMatch(disposition)![1]!;
    final filename = RegExp(r'filename="([^"]+)"').firstMatch(disposition)?[1];

    if (filename == null) {
      fields[name] = content;
      continue;
    }

    final contentTypeLine = headerLines.firstWhere(
      (line) => line.startsWith('Content-Type:'),
    );
    fields[name] = {
      'filename': filename,
      'contentType': contentTypeLine.substring('Content-Type:'.length).trim(),
      'text': content,
    };
  }

  return fields;
}
