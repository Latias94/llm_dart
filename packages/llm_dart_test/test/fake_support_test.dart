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
}
