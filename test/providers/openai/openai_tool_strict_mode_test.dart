import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/chat.dart';
import 'package:llm_dart_openai/client.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:llm_dart_openai/responses.dart' as openai_responses;
import 'package:test/test.dart';

void main() {
  Tool toolNamed(String name, {bool? strict}) {
    return Tool.function(
      name: name,
      description: 'tool',
      parameters: const ParametersSchema(
        schemaType: 'object',
        properties: {},
        required: [],
      ),
      strict: strict,
    );
  }

  group('OpenAI Chat tools strict mode (AI SDK parity)', () {
    test('passes through strict=true/false and omits undefined', () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
      );

      final client = _CapturingOpenAIClient(
        config,
        response: const {
          'choices': [
            {
              'message': {'role': 'assistant', 'content': 'ok'}
            }
          ],
        },
      );
      final chat = OpenAIChat(client, config);

      await chat.chatWithTools(
        [ChatMessage.user('hi')],
        [
          toolNamed('strictTrue', strict: true),
          toolNamed('strictFalse', strict: false),
          toolNamed('strictUnset'),
        ],
      );

      final tools = (client.lastBody?['tools'] as List).cast<Map>();
      expect(tools, hasLength(3));

      Map<String, dynamic> functionOf(String toolName) => tools
          .cast<Map>()
          .map((e) => e.cast<String, dynamic>())
          .firstWhere((t) => (t['function'] as Map)['name'] == toolName)[
              'function']
          .cast<String, dynamic>();

      expect(functionOf('strictTrue')['strict'], isTrue);
      expect(functionOf('strictFalse')['strict'], isFalse);
      expect(functionOf('strictUnset').containsKey('strict'), isFalse);
    });
  });

  group('OpenAI Responses tools strict mode (AI SDK parity)', () {
    test('passes through strict=true/false and omits undefined', () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        useResponsesAPI: true,
      );

      final client = _CapturingOpenAIClient(
        config,
        response: const <String, dynamic>{},
      );
      final responses = openai_responses.OpenAIResponses(client, config);

      await responses.chatWithTools(
        [ChatMessage.user('hi')],
        [
          toolNamed('strictTrue', strict: true),
          toolNamed('strictFalse', strict: false),
          toolNamed('strictUnset'),
        ],
      );

      final tools = (client.lastBody?['tools'] as List).cast<Map>();
      expect(tools, hasLength(3));

      Map<String, dynamic> toolDef(String name) => tools
          .cast<Map>()
          .map((e) => e.cast<String, dynamic>())
          .firstWhere((t) => t['name'] == name)
          .cast<String, dynamic>();

      expect(toolDef('strictTrue')['strict'], isTrue);
      expect(toolDef('strictFalse')['strict'], isFalse);
      expect(toolDef('strictUnset').containsKey('strict'), isFalse);
    });
  });
}

class _CapturingOpenAIClient extends OpenAIClient {
  final Map<String, dynamic> _response;
  Map<String, dynamic>? lastBody;

  _CapturingOpenAIClient(super.config, {required Map<String, dynamic> response})
      : _response = response;

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    lastBody = body;
    return _response;
  }
}

