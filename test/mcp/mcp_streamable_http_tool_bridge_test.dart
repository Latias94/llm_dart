import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_mcp/llm_dart_mcp.dart';
import 'package:mcp_dart/mcp_dart.dart' as mcp;
import 'package:test/test.dart';

class _SequencedChatModel implements ChatCapability {
  final List<ChatResponse> _responses;
  int calls = 0;

  _SequencedChatModel(this._responses);

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
    final idx = calls++;
    if (idx >= _responses.length) {
      throw StateError('No more fake responses configured.');
    }
    return _responses[idx];
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) =>
      chatWithTools(
        messages,
        null,
        providerTools: providerTools,
        cancelToken: cancelToken,
      );

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async =>
      'summary';
}

class _FakeChatResponse implements ChatResponse {
  @override
  final String? text;

  @override
  final List<ToolCall>? toolCalls;

  const _FakeChatResponse({this.text, this.toolCalls});

  @override
  String? get thinking => null;

  @override
  UsageInfo? get usage => null;

  @override
  Map<String, dynamic>? get providerMetadata => null;
}

void main() {
  group('llm_dart_mcp streamable http tool bridge', () {
    test('runs a tool call through an MCP Streamable HTTP server', () async {
      final server = mcp.McpServer(
        const mcp.Implementation(name: 'fake-mcp', version: 'test'),
      );

      server.tool(
        'sum',
        description: 'Add two integers.',
        toolInputSchema: const mcp.ToolInputSchema(
          properties: {
            'a': {'type': 'integer', 'description': 'First integer'},
            'b': {'type': 'integer', 'description': 'Second integer'},
          },
          required: ['a', 'b'],
        ),
        callback: ({args, extra}) {
          final a = (args?['a'] as num?)?.toInt() ?? 0;
          final b = (args?['b'] as num?)?.toInt() ?? 0;
          return mcp.CallToolResult.fromStructuredContent(
            structuredContent: {'result': a + b},
          );
        },
      );

      final transport = mcp.StreamableHTTPServerTransport(
        options: mcp.StreamableHTTPServerTransportOptions(
          // Stateless mode: simpler for tests.
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

      final conn = await experimentalConnectMcpStreamableHttp(
        config: ExperimentalMcpStreamableHttpConfig(
          url: Uri.parse('http://127.0.0.1:${httpServer.port}/mcp'),
          serverLabel: 'fake',
        ),
        clientName: 'llm_dart_test',
        clientVersion: 'test',
      );

      try {
        final bridge = await experimentalCreateMcpToolBridge(connection: conn);
        final sumToolName = bridge.mcpToolNameToFunctionName['sum'];
        expect(sumToolName, isNotNull);

        const toolCallId = 'call_1';
        const toolArguments = '{"a":1,"b":2}';

        final model = _SequencedChatModel([
          _FakeChatResponse(
            toolCalls: [
              ToolCall(
                id: toolCallId,
                callType: 'function',
                function: FunctionCall(
                  name: sumToolName!,
                  arguments: toolArguments,
                ),
              ),
            ],
          ),
          const _FakeChatResponse(text: 'done'),
        ]);

        final result = await runToolLoop(
          model: model,
          messages: [ChatMessage.user('hi')],
          tools: bridge.toolSet.tools,
          toolHandlers: bridge.toolSet.handlers,
          maxSteps: 5,
        );

        expect(result.finalResult.text, equals('done'));
        expect(model.calls, equals(2));
      } finally {
        await conn.close();
        await sub.cancel();
        await httpServer.close(force: true);
      }
    });
  });
}
