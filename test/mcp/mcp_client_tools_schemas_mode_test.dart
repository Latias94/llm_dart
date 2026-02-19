import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_mcp/llm_dart_mcp.dart';
import 'package:test/test.dart';

void main() {
  group('llm_dart_mcp client tools schemas mode', () {
    test('schemas=none disables outputSchema inference', () async {
      final dartExe = Platform.resolvedExecutable;
      final serverScript = 'test/utils/fakes/mcp_fake_stdio_server.dart';

      final client = await experimentalCreateMcpStdioClient(
        config: ExperimentalMcpStdioConfig(
          command: dartExe,
          args: ['run', serverScript],
          serverLabel: 'fake',
        ),
        clientName: 'llm_dart_test',
        clientVersion: 'test',
      );

      try {
        final bridge = await client.tools(schemas: ToolSchemas.none);
        final sumStringToolName =
            bridge.mcpToolNameToFunctionName['sum_string'];
        expect(sumStringToolName, isNotNull);

        final handler = bridge.toolSet.handlers[sumStringToolName!];
        expect(handler, isNotNull);

        // The MCP server returns `{"result":"3"}` (string). With schemas=none we
        // keep best-effort behavior and don't validate against outputSchema.
        const rawArguments = '{"a":1,"b":2}';
        final toolCall = V3ToolCall(
          toolCallId: 'call_1',
          toolName: sumStringToolName,
          input: rawArguments,
        );

        final out = await handler!(
          const {'a': 1, 'b': 2},
          ToolExecutionOptions(
            toolCallId: 'call_1',
            toolName: sumStringToolName,
            rawArguments: rawArguments,
            messages: const [],
            stepIndex: 0,
            toolCall: toolCall,
          ),
        );
        expect(out, equals({'result': '3'}));
      } finally {
        await client.close();
      }
    });
  });
}
