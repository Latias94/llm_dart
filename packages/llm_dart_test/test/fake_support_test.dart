import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  test('FakeTransportClient forwards configured callbacks', () async {
    TransportRequest? capturedRequest;

    final client = FakeTransportClient(
      onSend: (request) async {
        capturedRequest = request;
        return const TransportResponse(statusCode: 200);
      },
    );

    final response = await client.send(
      TransportRequest(
        uri: Uri.parse('https://example.com'),
        method: TransportMethod.post,
      ),
    );

    expect(response.statusCode, 200);
    expect(capturedRequest, isNotNull);
    expect(capturedRequest!.uri, Uri.parse('https://example.com'));
  });

  test('FakeLanguageModel records the last request', () async {
    final model = FakeLanguageModel(
      onStream: (request) => Stream<LanguageModelStreamEvent>.fromIterable([
        StartEvent(),
        const FinishEvent(finishReason: FinishReason.stop),
      ]),
    );

    await model
        .doStream(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage.text('Hello'),
            ],
          ),
        )
        .drain<void>();

    expect(model.lastRequest, isNotNull);
    expect(model.lastStreamRequest, isNotNull);
    expect(model.lastRequest!.prompt.single, isA<UserPromptMessage>());
  });

  group('ProviderCodecContractRunner', () {
    test('compares JSON fixtures by value', () {
      final temp = Directory.systemTemp.createTempSync(
        'llm_dart_fixture_contract_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      File('${temp.path}/request.json').writeAsStringSync(
        jsonEncode({
          'body': {
            'messages': [
              {'role': 'user', 'content': 'Hello'},
            ],
          },
        }),
      );

      final runner = ProviderCodecContractRunner(
        fixtureRoots: [temp.path],
        label: 'test-provider',
      );

      runner.expectJsonFixture('request.json', {
        'body': {
          'messages': [
            {'role': 'user', 'content': 'Hello'},
          ],
        },
      });
    });

    test('throws a contract mismatch with fixture context', () {
      final temp = Directory.systemTemp.createTempSync(
        'llm_dart_fixture_contract_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      File('${temp.path}/request.json').writeAsStringSync(
        jsonEncode({'ok': true}),
      );

      final runner = ProviderCodecContractRunner(
        fixtureRoots: [temp.path],
        label: 'test-provider',
      );

      expect(
        () => runner.expectJsonFixture('request.json', {'ok': false}),
        throwsA(
          isA<ProviderCodecFixtureMismatch>()
              .having(
                (error) => error.relativePath,
                'relativePath',
                'request.json',
              )
              .having(
                (error) => error.toString(),
                'message',
                contains('test-provider'),
              ),
        ),
      );
    });

    test('projects language model stream events before fixture comparison', () {
      final temp = Directory.systemTemp.createTempSync(
        'llm_dart_fixture_contract_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      File('${temp.path}/stream.json').writeAsStringSync(
        jsonEncode({
          'schemaVersion': '2026-03-1',
          'kind': 'text-stream-events',
          'data': {
            'events': [
              {'type': 'start', 'warnings': <Object?>[]},
              {'type': 'finish', 'finishReason': 'stop'},
            ],
          },
        }),
      );

      final runner = ProviderCodecContractRunner(
        fixtureRoots: [temp.path],
        label: 'test-provider',
      );

      runner.expectLanguageModelStreamEventsFixture('stream.json', [
        StartEvent(),
        const FinishEvent(finishReason: FinishReason.stop),
      ]);
    });
  });

  group('ProviderTransportContractProjector', () {
    test('projects deterministic transport request JSON', () {
      const projector = ProviderTransportContractProjector();

      final request = TransportRequest(
        uri: Uri.parse('https://example.com/v1/test'),
        method: TransportMethod.post,
        headers: const {
          'authorization': 'Bearer test',
        },
        body: const {
          'ok': true,
        },
      );

      expect(projector.requestJson(request), {
        'uri': 'https://example.com/v1/test',
        'method': 'post',
        'responseType': 'json',
        'headers': {
          'authorization': 'Bearer test',
        },
        'body': {
          'ok': true,
        },
      });
    });

    test('projects multipart fields without exposing random boundary', () {
      const projector = ProviderTransportContractProjector();
      const boundary = 'fixture-boundary';
      final body = utf8.encode(
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="model_id"\r\n'
        '\r\n'
        'scribe_v1\r\n'
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="file"; filename="audio.mp3"\r\n'
        'Content-Type: audio/mpeg\r\n'
        '\r\n'
        'abc\r\n'
        '--$boundary--\r\n',
      );

      final request = TransportRequest(
        uri: Uri.parse('https://example.com/v1/transcribe'),
        method: TransportMethod.post,
        headers: const {
          'content-type': 'multipart/form-data; boundary=$boundary',
          'accept': 'application/json',
          'authorization': 'Bearer hidden',
        },
        body: body,
      );

      expect(
        projector.multipartRequestJson(
          request,
          headerNames: const ['accept'],
        ),
        {
          'uri': 'https://example.com/v1/transcribe',
          'method': 'post',
          'responseType': 'json',
          'headers': {
            'accept': 'application/json',
          },
          'multipart': {
            'model_id': 'scribe_v1',
            'file': {
              'filename': 'audio.mp3',
              'contentType': 'audio/mpeg',
              'text': 'abc',
            },
          },
        },
      );
    });
  });
}
