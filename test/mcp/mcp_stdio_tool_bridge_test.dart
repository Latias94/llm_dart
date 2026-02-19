import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_mcp/llm_dart_mcp.dart';
import 'package:test/test.dart';

class _SequencedChatModel implements ChatCapability {
  final List<ChatResponse> _responses;
  int calls = 0;
  final List<List<ChatMessage>> callMessages = <List<ChatMessage>>[];
  final List<List<Tool>?> callTools = <List<Tool>?>[];

  _SequencedChatModel(this._responses);

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
    callMessages.add(List<ChatMessage>.unmodifiable(messages));
    callTools.add(
      tools == null ? null : List<Tool>.unmodifiable(tools),
    );
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
  group('llm_dart_mcp stdio tool bridge', () {
    test('runs a tool call through an MCP stdio server', () async {
      final dartExe = Platform.resolvedExecutable;
      final serverScript = 'test/utils/fakes/mcp_fake_stdio_server.dart';

      final conn = await experimentalConnectMcpStdio(
        config: ExperimentalMcpStdioConfig(
          command: dartExe,
          args: ['run', serverScript],
          serverLabel: 'fake',
        ),
        clientName: 'llm_dart_test',
        clientVersion: 'test',
      );

      try {
        final bridge = await experimentalCreateMcpToolBridge(
          connection: conn,
        );

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

        expect(model.callMessages, hasLength(2));

        final secondCallMessages = model.callMessages[1];
        expect(secondCallMessages, hasLength(3));

        final toolUseMessage = secondCallMessages[1];
        expect(toolUseMessage.messageType, isA<ToolUseMessage>());
        final toolUseCalls =
            (toolUseMessage.messageType as ToolUseMessage).toolCalls;
        expect(toolUseCalls.single.function.name, equals(sumToolName));
        expect(toolUseCalls.single.id, equals(toolCallId));

        final toolResultMessage = secondCallMessages[2];
        expect(toolResultMessage.messageType, isA<ToolResultMessage>());
        final results =
            (toolResultMessage.messageType as ToolResultMessage).results;
        expect(results, hasLength(1));
        final resultCall = results.single;
        expect(resultCall.id, equals(toolCallId));
        expect(resultCall.function.name, equals(sumToolName));
        expect(
            jsonDecode(resultCall.function.arguments), equals({'result': 3}));
      } finally {
        await conn.close();
      }
    });

    test('maps MCP content blocks to v3 tool-result output envelope', () async {
      final dartExe = Platform.resolvedExecutable;
      final serverScript = 'test/utils/fakes/mcp_fake_stdio_server.dart';

      final conn = await experimentalConnectMcpStdio(
        config: ExperimentalMcpStdioConfig(
          command: dartExe,
          args: ['run', serverScript],
          serverLabel: 'fake',
        ),
        clientName: 'llm_dart_test',
        clientVersion: 'test',
      );

      try {
        final bridge = await experimentalCreateMcpToolBridge(connection: conn);

        final imageToolName = bridge.mcpToolNameToFunctionName['sample_image'];
        expect(imageToolName, isNotNull);

        const toolCallId = 'call_1';

        final model = _SequencedChatModel([
          _FakeChatResponse(
            toolCalls: [
              ToolCall(
                id: toolCallId,
                callType: 'function',
                function: FunctionCall(
                  name: imageToolName!,
                  arguments: '{}',
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

        final toolResultMessage = model.callMessages[1][2];
        final results =
            (toolResultMessage.messageType as ToolResultMessage).results;
        expect(results, hasLength(1));

        final decoded = jsonDecode(results.single.function.arguments);
        expect(decoded, isA<Map>());
        final map = (decoded as Map).cast<String, dynamic>();
        expect(map['type'], equals('content'));

        final value = map['value'];
        expect(value, isA<List>());
        final items = (value as List).cast<Map>();
        expect(items, isNotEmpty);

        final first = items.first.cast<String, dynamic>();
        expect(first['type'], equals('image-data'));
        expect(first['mediaType'], equals('image/png'));
        expect(first['data'], isA<String>());
      } finally {
        await conn.close();
      }
    });

    test('validates structuredContent against outputSchema when configured',
        () async {
      final dartExe = Platform.resolvedExecutable;
      final serverScript = 'test/utils/fakes/mcp_fake_stdio_server.dart';

      final conn = await experimentalConnectMcpStdio(
        config: ExperimentalMcpStdioConfig(
          command: dartExe,
          args: ['run', serverScript],
          serverLabel: 'fake',
        ),
        clientName: 'llm_dart_test',
        clientVersion: 'test',
      );

      try {
        final bridge = await experimentalCreateMcpToolBridge(
          connection: conn,
          options: ExperimentalMcpToolBridgeOptions(
            outputSchemasByMcpToolName: {
              'sum': Schema.object(
                'sum output',
                properties: {'result': Schema.integer('sum')},
                required: ['result'],
              ),
              'sum_string': Schema.object(
                'sum output',
                properties: {'result': Schema.integer('sum')},
                required: ['result'],
              ),
            },
          ),
        );

        final sumToolName = bridge.mcpToolNameToFunctionName['sum'];
        final sumStringToolName =
            bridge.mcpToolNameToFunctionName['sum_string'];
        expect(sumToolName, isNotNull);
        expect(sumStringToolName, isNotNull);

        final sumHandler = bridge.toolSet.handlers[sumToolName!];
        final sumStringHandler = bridge.toolSet.handlers[sumStringToolName!];
        expect(sumHandler, isNotNull);
        expect(sumStringHandler, isNotNull);

        const rawArguments = '{"a":1,"b":2}';
        final callOk = V3ToolCall(
          toolCallId: 'call_ok',
          toolName: sumToolName,
          input: rawArguments,
        );
        final ok = await sumHandler!(
          const {'a': 1, 'b': 2},
          ToolExecutionOptions(
            toolCallId: 'call_ok',
            toolName: sumToolName,
            rawArguments: rawArguments,
            messages: const [],
            stepIndex: 0,
            toolCall: callOk,
          ),
        );
        expect(ok, equals({'result': 3}));

        await expectLater(
          () => Future.value(
            sumStringHandler!(
              const {'a': 1, 'b': 2},
              ToolExecutionOptions(
                toolCallId: 'call_bad',
                toolName: sumStringToolName,
                rawArguments: rawArguments,
                messages: const [],
                stepIndex: 0,
                toolCall: V3ToolCall(
                  toolCallId: 'call_bad',
                  toolName: sumStringToolName,
                  input: rawArguments,
                ),
              ),
            ),
          ),
          throwsA(isA<ToolOutputValidationError>()),
        );
      } finally {
        await conn.close();
      }
    });

    test('infers outputSchema from MCP tool definitions by default', () async {
      final dartExe = Platform.resolvedExecutable;
      final serverScript = 'test/utils/fakes/mcp_fake_stdio_server.dart';

      final conn = await experimentalConnectMcpStdio(
        config: ExperimentalMcpStdioConfig(
          command: dartExe,
          args: ['run', serverScript],
          serverLabel: 'fake',
        ),
        clientName: 'llm_dart_test',
        clientVersion: 'test',
      );

      try {
        final bridge = await experimentalCreateMcpToolBridge(connection: conn);

        final sumToolName = bridge.mcpToolNameToFunctionName['sum'];
        final sumStringToolName =
            bridge.mcpToolNameToFunctionName['sum_string'];
        final sumTextJsonToolName =
            bridge.mcpToolNameToFunctionName['sum_text_json'];
        expect(sumToolName, isNotNull);
        expect(sumStringToolName, isNotNull);
        expect(sumTextJsonToolName, isNotNull);

        final sumHandler = bridge.toolSet.handlers[sumToolName!];
        final sumStringHandler = bridge.toolSet.handlers[sumStringToolName!];
        final sumTextJsonHandler =
            bridge.toolSet.handlers[sumTextJsonToolName!];
        expect(sumHandler, isNotNull);
        expect(sumStringHandler, isNotNull);
        expect(sumTextJsonHandler, isNotNull);

        const rawArguments = '{"a":1,"b":2}';
        final callOk = V3ToolCall(
          toolCallId: 'call_ok',
          toolName: sumToolName,
          input: rawArguments,
        );
        final ok = await sumHandler!(
          const {'a': 1, 'b': 2},
          ToolExecutionOptions(
            toolCallId: 'call_ok',
            toolName: sumToolName,
            rawArguments: rawArguments,
            messages: const [],
            stepIndex: 0,
            toolCall: callOk,
          ),
        );
        expect(ok, equals({'result': 3}));

        final callText = V3ToolCall(
          toolCallId: 'call_text',
          toolName: sumTextJsonToolName,
          input: rawArguments,
        );
        final okText = await sumTextJsonHandler!(
          const {'a': 1, 'b': 2},
          ToolExecutionOptions(
            toolCallId: 'call_text',
            toolName: sumTextJsonToolName,
            rawArguments: rawArguments,
            messages: const [],
            stepIndex: 0,
            toolCall: callText,
          ),
        );
        expect(okText, equals({'result': 3}));

        await expectLater(
          () => Future.value(
            sumStringHandler!(
              const {'a': 1, 'b': 2},
              ToolExecutionOptions(
                toolCallId: 'call_bad',
                toolName: sumStringToolName,
                rawArguments: rawArguments,
                messages: const [],
                stepIndex: 0,
                toolCall: V3ToolCall(
                  toolCallId: 'call_bad',
                  toolName: sumStringToolName,
                  input: rawArguments,
                ),
              ),
            ),
          ),
          throwsA(isA<ToolOutputValidationError>()),
        );
      } finally {
        await conn.close();
      }
    });
  });
}
