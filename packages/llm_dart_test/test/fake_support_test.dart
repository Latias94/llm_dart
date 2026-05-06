import 'dart:async';

import 'package:llm_dart_core/model.dart';
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
      onStream: (request) => Stream<TextStreamEvent>.fromIterable([
        StartEvent(),
        const FinishEvent(finishReason: FinishReason.stop),
      ]),
    );

    await model
        .stream(
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
}
