import 'package:llm_dart/legacy.dart';
import 'package:llm_dart_transport/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('ElevenLabsClient', () {
    test('postFormData wraps plain-text STT responses into a text map',
        () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: 'hello from stt',
              ),
            );
          },
        ),
      );

      final client = ElevenLabsClient(
        ElevenLabsConfig(
          apiKey: 'test-key',
          dioOverrides: ImmutableDioClientOverrides(customDio: dio),
        ),
      );

      final response = await client.postFormData(
        'speech-to-text',
        FormData.fromMap({
          'model_id': 'scribe_v1',
        }),
      );

      expect(response, {
        'text': 'hello from stt',
      });
    });
  });
}
