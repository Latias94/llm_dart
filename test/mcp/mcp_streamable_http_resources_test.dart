import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_mcp/llm_dart_mcp.dart';
import 'package:mcp_dart/mcp_dart.dart' as mcp;
import 'package:test/test.dart';

void main() {
  group('llm_dart_mcp streamable http resources', () {
    test('lists resources and reads as prompt parts', () async {
      final server = mcp.McpServer(
        const mcp.Implementation(name: 'fake-mcp', version: 'test'),
      );

      server.resource(
        'hello',
        'test://hello',
        (uri, extra) => mcp.ReadResourceResult(
          contents: [
            mcp.TextResourceContents(
              uri: uri.toString(),
              mimeType: 'text/plain',
              text: 'Hello from MCP',
            ),
          ],
        ),
        metadata: (description: 'Greeting', mimeType: 'text/plain'),
      );

      server.resource(
        'blob',
        'test://blob',
        (uri, extra) => mcp.ReadResourceResult(
          contents: [
            mcp.BlobResourceContents(
              uri: uri.toString(),
              mimeType: 'application/octet-stream',
              blob: base64Encode([1, 2, 3, 4]),
            ),
          ],
        ),
        metadata: (
          description: 'Binary payload',
          mimeType: 'application/octet-stream'
        ),
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
        final listed = await client.listResources();
        expect(
          listed.resources.map((r) => r.uri),
          containsAll(<String>['test://hello', 'test://blob']),
        );

        final streamed =
            await client.streamResources().map((e) => e.uri).toList();
        expect(
          streamed,
          containsAll(<String>['test://hello', 'test://blob']),
        );

        await expectLater(
          () => client.streamResources(maxPages: 0).toList(),
          throwsA(isA<InvalidRequestError>()),
        );

        final textParts =
            await client.readResourceAsPromptParts(uri: 'test://hello');
        expect(textParts, hasLength(1));
        expect(textParts.single, isA<TextPart>());
        expect((textParts.single as TextPart).text, equals('Hello from MCP'));

        final blobParts =
            await client.readResourceAsPromptParts(uri: 'test://blob');
        expect(blobParts, hasLength(1));
        expect(blobParts.single, isA<FilePart>());
        final file = blobParts.single as FilePart;
        expect(file.mime.mimeType, equals('application/octet-stream'));
        expect(file.data, equals(<int>[1, 2, 3, 4]));

        await expectLater(
          () => client.readResourceAsPromptParts(
            uri: 'test://blob',
            maxBytesPerBlob: 1,
          ),
          throwsA(isA<InvalidRequestError>()),
        );
      } finally {
        await client.close();
        await sub.cancel();
        await httpServer.close(force: true);
      }
    });
  });
}
