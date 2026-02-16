import 'dart:async';
import 'dart:io';

import 'package:mcp_dart/mcp_dart.dart' as mcp;

Future<void> main(List<String> args) async {
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
    toolOutputSchema: const mcp.ToolOutputSchema(
      properties: {
        'result': {'type': 'integer', 'description': 'Sum result'},
      },
      required: ['result'],
    ),
    callback: ({args, extra}) {
      final a = (args?['a'] as num?)?.toInt() ?? 0;
      final b = (args?['b'] as num?)?.toInt() ?? 0;
      return mcp.CallToolResult.fromStructuredContent(
        structuredContent: {'result': a + b},
      );
    },
  );

  server.tool(
    'sum_string',
    description: 'Add two integers, but return the result as a string.',
    toolInputSchema: const mcp.ToolInputSchema(
      properties: {
        'a': {'type': 'integer', 'description': 'First integer'},
        'b': {'type': 'integer', 'description': 'Second integer'},
      },
      required: ['a', 'b'],
    ),
    toolOutputSchema: const mcp.ToolOutputSchema(
      properties: {
        'result': {'type': 'integer', 'description': 'Sum result'},
      },
      required: ['result'],
    ),
    callback: ({args, extra}) {
      final a = (args?['a'] as num?)?.toInt() ?? 0;
      final b = (args?['b'] as num?)?.toInt() ?? 0;
      return mcp.CallToolResult.fromStructuredContent(
        structuredContent: {'result': '${a + b}'},
      );
    },
  );

  server.tool(
    'sum_text_json',
    description: 'Add two integers and return JSON text content.',
    toolInputSchema: const mcp.ToolInputSchema(
      properties: {
        'a': {'type': 'integer', 'description': 'First integer'},
        'b': {'type': 'integer', 'description': 'Second integer'},
      },
      required: ['a', 'b'],
    ),
    toolOutputSchema: const mcp.ToolOutputSchema(
      properties: {
        'result': {'type': 'integer', 'description': 'Sum result'},
      },
      required: ['result'],
    ),
    callback: ({args, extra}) {
      final a = (args?['a'] as num?)?.toInt() ?? 0;
      final b = (args?['b'] as num?)?.toInt() ?? 0;
      return mcp.CallToolResult.fromContent(
        content: [
          mcp.TextContent(text: '{"result":${a + b}}'),
        ],
      );
    },
  );

  server.tool(
    'sample_image',
    description: 'Return a small PNG image as MCP image content.',
    toolInputSchema: const mcp.ToolInputSchema(properties: {}),
    callback: ({args, extra}) {
      // 1x1 PNG base64 (opaque; only used for conformance tests).
      const base64Png =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/wwAAgEB/UNuG4kAAAAASUVORK5CYII=';

      return mcp.CallToolResult.fromContent(
        content: const [
          mcp.ImageContent(data: base64Png, mimeType: 'image/png'),
        ],
      );
    },
  );

  final transport = mcp.StdioServerTransport();
  transport.onclose = () {
    exit(0);
  };

  await server.connect(transport);

  // Keep the server alive; the client closing stdin triggers transport.onclose.
  await Completer<void>().future;
}
