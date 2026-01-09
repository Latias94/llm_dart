import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/builtin_tools.dart';
import 'package:llm_dart_openai/client.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:llm_dart_openai/responses.dart' as openai_responses;
import 'package:test/test.dart';

void main() {
  group('OpenAI Responses provider-native tools request mapping', () {
    test('serializes built-in tools into tools[]', () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        useResponsesAPI: true,
        builtInTools: [
          OpenAIBuiltInTools.webSearchFull(
            allowedDomains: const ['example.com'],
            externalWebAccess: true,
          ),
          OpenAIBuiltInTools.codeInterpreter(container: 'container_1'),
          OpenAIBuiltInTools.imageGeneration(
              parameters: const {'size': '1024x1024'}),
          OpenAIBuiltInTools.mcp(parameters: const {'server_label': 'test'}),
          OpenAIBuiltInTools.applyPatch(),
          OpenAIBuiltInTools.shell(),
          OpenAIBuiltInTools.localShell(),
        ],
      );

      final client = _CapturingOpenAIClient(config);
      final responses = openai_responses.OpenAIResponses(client, config);

      await responses.chat([ChatMessage.user('hi')]);

      final tools = (client.lastBody?['tools'] as List).cast<Map>();
      final types = tools.map((t) => t['type']).toList();

      expect(
        types,
        containsAll([
          'web_search',
          'code_interpreter',
          'image_generation',
          'mcp',
          'apply_patch',
          'shell',
          'local_shell',
        ]),
      );

      final webSearch = tools
          .firstWhere((t) => t['type'] == 'web_search')
          .cast<String, dynamic>();
      expect((webSearch['filters'] as Map)['allowed_domains'],
          equals(['example.com']));
      expect(webSearch['external_web_access'], isTrue);

      final codeInterpreter = tools
          .firstWhere((t) => t['type'] == 'code_interpreter')
          .cast<String, dynamic>();
      expect(codeInterpreter['container'], equals('container_1'));

      final imageGen = tools
          .firstWhere((t) => t['type'] == 'image_generation')
          .cast<String, dynamic>();
      expect(imageGen['size'], equals('1024x1024'));

      final mcp =
          tools.firstWhere((t) => t['type'] == 'mcp').cast<String, dynamic>();
      expect(mcp['server_label'], equals('test'));
    });
  });
}

class _CapturingOpenAIClient extends OpenAIClient {
  Map<String, dynamic>? lastBody;

  _CapturingOpenAIClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    lastBody = body;
    return const <String, dynamic>{};
  }
}
