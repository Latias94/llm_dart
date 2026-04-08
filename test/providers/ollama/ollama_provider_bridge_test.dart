import 'package:dio/dio.dart';
import 'package:llm_dart/legacy.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('OllamaProvider bridge delegation', () {
    test('chat delegates replay-safe requests to the community model codec',
        () async {
      RequestOptions? capturedOptions;
      Object? capturedBody;
      final dio = _buildResolvedDio((options) {
        capturedOptions = options;
        capturedBody = options.data;
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'model': 'llama3.2',
            'done': true,
            'message': {
              'content': 'Done',
            },
          },
        );
      });

      final provider = OllamaProvider(
        OllamaConfig(
          baseUrl: 'http://localhost:11434/',
          model: 'llama3.2',
          dioOverrides: ImmutableDioClientOverrides(customDio: dio),
        ),
      );

      final toolCall = ToolCall(
        id: 'tool-1',
        callType: 'function',
        function: const FunctionCall(
          name: 'weather',
          arguments: '{"city":"Shanghai"}',
        ),
      );

      final response = await provider.chat([
        ChatMessage.user('What is the weather?'),
        ChatMessage.toolUse(toolCalls: [toolCall]),
        ChatMessage.toolResult(results: [toolCall]),
      ]);

      expect(response.text, 'Done');
      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.uri.path, '/api/chat');
      expect(
        capturedBody,
        {
          'model': 'llama3.2',
          'messages': [
            {
              'role': 'user',
              'content': 'What is the weather?',
            },
            {
              'role': 'assistant',
              'content': '',
              'tool_calls': [
                {
                  'type': 'function',
                  'function': {
                    'index': 0,
                    'name': 'weather',
                    'arguments': {
                      'city': 'Shanghai',
                    },
                  },
                },
              ],
            },
            {
              'role': 'tool',
              'tool_name': 'weather',
              'content': '{"city":"Shanghai"}',
            },
          ],
          'stream': false,
          'keep_alive': '5m',
        },
      );
    });

    test('chat falls back to the legacy shell for named messages', () async {
      RequestOptions? capturedOptions;
      Object? capturedBody;
      final dio = _buildResolvedDio((options) {
        capturedOptions = options;
        capturedBody = options.data;
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'message': {
              'content': 'Done',
            },
          },
        );
      });

      final provider = OllamaProvider(
        OllamaConfig(
          baseUrl: 'http://localhost:11434/',
          model: 'llama3.2',
          dioOverrides: ImmutableDioClientOverrides(customDio: dio),
        ),
      );

      final response = await provider.chat([
        ChatMessage.system('You are helpful.', name: 'system-a'),
        ChatMessage.user('Hello'),
      ]);

      expect(response.text, 'Done');
      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.uri.path, '/api/chat');
      expect(
        capturedBody,
        {
          'model': 'llama3.2',
          'messages': [
            {
              'role': 'system',
              'name': 'system-a',
              'content': 'You are helpful.',
            },
            {
              'role': 'user',
              'content': 'Hello',
            },
          ],
          'stream': false,
          'keep_alive': '5m',
        },
      );
    });

    test('embed delegates to the community embedding model', () async {
      RequestOptions? capturedOptions;
      Object? capturedBody;
      final dio = _buildResolvedDio((options) {
        capturedOptions = options;
        capturedBody = options.data;
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'embeddings': [
              [0.1, 0.2, 0.3],
            ],
          },
        );
      });

      final provider = OllamaProvider(
        OllamaConfig(
          baseUrl: 'http://localhost:11434/',
          model: 'nomic-embed-text',
          dioOverrides: ImmutableDioClientOverrides(customDio: dio),
        ),
      );

      final embeddings = await provider.embed(['hello']);

      expect(
        embeddings,
        [
          [0.1, 0.2, 0.3],
        ],
      );
      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.uri.path, '/api/embed');
      expect(
        capturedBody,
        {
          'model': 'nomic-embed-text',
          'input': ['hello'],
        },
      );
    });
  });
}

Dio _buildResolvedDio(
    Response<dynamic> Function(RequestOptions options) handle) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(handle(options)),
    ),
  );
  return dio;
}
