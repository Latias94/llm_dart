import 'package:dio/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('DioHttpClientFactory', () {
    test('sanitizes sensitive headers and endpoints in logs', () async {
      hierarchicalLoggingEnabled = true;

      final records = <LogRecord>[];
      final logger = Logger('dio_http_client_factory_test.logging')
        ..level = Level.ALL;
      final subscription = logger.onRecord.listen(records.add);
      addTearDown(subscription.cancel);

      final dio = DioHttpClientFactory.createConfiguredDio(
        config: const DioHttpClientConfig(
          baseUrl: 'https://example.com/v1',
          defaultHeaders: {
            'Authorization': 'Bearer test-secret',
            'X-Trace-Id': 'trace-1',
          },
          timeout: Duration(seconds: 30),
          enableLogging: true,
          proxyUrl: 'http://127.0.0.1:10809',
        ),
        logger: logger,
      );

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                headers: Headers.fromMap({
                  'authorization': ['Bearer response-secret'],
                  'x-request-id': ['req_1'],
                }),
                data: const {'ok': true},
              ),
            );
          },
        ),
      );

      await dio.get('/chat?api_key=secret&token=secret');

      final combined = records.map((record) => record.message).join('\n');
      expect(combined, contains('Authorization: ***'));
      expect(combined, contains('api_key=%2A%2A%2A'));
      expect(combined, contains('token=%2A%2A%2A'));
      expect(combined, isNot(contains('Bearer test-secret')));
      expect(combined, isNot(contains('api_key=secret')));
      expect(combined, isNot(contains('token=secret')));
    });

    test('accepts proxy URLs with or without a scheme', () {
      final records = <LogRecord>[];
      final logger = Logger('dio_http_client_factory_test.proxy')
        ..level = Level.ALL;
      final subscription = logger.onRecord.listen(records.add);
      addTearDown(subscription.cancel);

      DioHttpClientFactory.validateHttpConfig(
        const DioHttpClientConfig(
          baseUrl: 'https://example.com/v1',
          defaultHeaders: {},
          proxyUrl: 'http://127.0.0.1:10809',
        ),
        logger: logger,
      );
      expect(
        records.where((record) => record.level >= Level.WARNING),
        isEmpty,
      );

      records.clear();

      DioHttpClientFactory.validateHttpConfig(
        const DioHttpClientConfig(
          baseUrl: 'https://example.com/v1',
          defaultHeaders: {},
          proxyUrl: '127.0.0.1:10809',
        ),
        logger: logger,
      );
      expect(
        records.where((record) => record.level >= Level.WARNING),
        isEmpty,
      );
    });
  });
}
