import 'dart:io';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_mcp/llm_dart_mcp.dart';
import 'package:mcp_dart/mcp_dart.dart' as mcp;
import 'package:test/test.dart';

void main() {
  group('llm_dart_mcp streamable http prompts', () {
    test('lists prompts and converts prompts/get to Prompt IR', () async {
      final server = mcp.McpServer(
        const mcp.Implementation(name: 'fake-mcp', version: 'test'),
      );

      server.prompt(
        'greet',
        description: 'Greets a user.',
        argsSchema: const {
          'name': mcp.PromptArgumentDefinition(
            description: 'User name.',
            required: true,
            type: String,
          ),
        },
        callback: (args, extra) {
          final name = (args?['name'] as String?) ?? 'world';
          return mcp.GetPromptResult(
            description: 'Greeting prompt',
            messages: [
              mcp.PromptMessage(
                role: mcp.PromptMessageRole.assistant,
                content: mcp.TextContent(text: 'hi $name'),
              ),
            ],
          );
        },
      );

      final transport = mcp.StreamableHTTPServerTransport(
        options: mcp.StreamableHTTPServerTransportOptions(
          sessionIdGenerator: () => null,
        ),
      );
      await server.connect(transport);

      final httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final sub = httpServer.listen((req) async {
        if (req.uri.path != '/mcp') {
          req.response.statusCode = HttpStatus.notFound;
          await req.response.close();
          return;
        }
        await transport.handleRequest(req);
      });

      final client = await experimentalCreateMcpStreamableHttpClient(
        config: ExperimentalMcpStreamableHttpConfig(
          url: Uri.parse('http://127.0.0.1:${httpServer.port}/mcp'),
          serverLabel: 'fake',
        ),
        clientName: 'llm_dart_test',
        clientVersion: 'test',
      );

      try {
        final listed = await client.listPrompts();
        expect(listed.prompts.map((p) => p.name), contains('greet'));

        final streamed =
            await client.streamPrompts().map((e) => e.name).toList();
        expect(streamed, contains('greet'));

        await expectLater(
          () => client.streamPrompts(maxPages: 0).toList(),
          throwsA(isA<InvalidRequestError>()),
        );

        final prompt = await client.getPromptAsPrompt(
          name: 'greet',
          arguments: const {'name': 'Ada'},
        );
        expect(prompt.messages, hasLength(1));
        expect(prompt.messages.single.role, equals(PromptRole.assistant));
        expect(prompt.messages.single.parts, hasLength(1));
        expect(prompt.messages.single.parts.single, isA<TextPart>());
        expect(
          (prompt.messages.single.parts.single as TextPart).text,
          equals('hi Ada'),
        );
      } finally {
        await client.close();
        await sub.cancel();
        await httpServer.close(force: true);
      }
    });
  });
}
