import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'dart:convert';

/// Mock tool execution capability for testing
class MockToolExecutionCapability extends ToolExecutionCapability {
  final Map<String, Future<ToolResult> Function(ToolCall)> _executors = {};
  final Map<String, Exception> _executorErrors = {};

  @override
  Map<String, Future<ToolResult> Function(ToolCall toolCall)>
      get toolExecutors => _executors;

  @override
  Future<ToolResult> executeTool(ToolCall toolCall) async {
    final toolName = toolCall.function.name;

    // Check if we should simulate an error
    if (_executorErrors.containsKey(toolName)) {
      throw _executorErrors[toolName]!;
    }

    // Check if we have a registered executor
    if (_executors.containsKey(toolName)) {
      return await _executors[toolName]!(toolCall);
    }

    // Default behavior - return error for unknown tools
    return ToolResult.error(
      toolCallId: toolCall.id,
      errorMessage: 'Unknown tool: $toolName',
    );
  }

  @override
  void registerToolExecutor(
    String toolName,
    Future<ToolResult> Function(ToolCall toolCall) executor,
  ) {
    _executors[toolName] = executor;
  }

  /// Register an executor that will throw an error
  void registerErrorExecutor(String toolName, Exception error) {
    _executorErrors[toolName] = error;
  }

  /// Clear all registered executors
  void clearExecutors() {
    _executors.clear();
    _executorErrors.clear();
  }
}

void main() {
  group('Tool Execution Tests', () {
    late MockToolExecutionCapability capability;

    setUp(() {
      capability = MockToolExecutionCapability();
    });

    tearDown(() {
      capability.clearExecutors();
    });

    group('Single Tool Execution', () {
      test('should execute tool successfully', () async {
        // Register a simple calculator executor
        capability.registerToolExecutor('calculate', (toolCall) async {
          final args =
              jsonDecode(toolCall.function.arguments) as Map<String, dynamic>;
          final expression = args['expression'] as String;

          // Simple calculation simulation
          if (expression == '2+2') {
            return ToolResult.success(
              toolCallId: toolCall.id,
              content: '4',
              metadata: {'calculation': expression},
            );
          }

          return ToolResult.error(
            toolCallId: toolCall.id,
            errorMessage: 'Unsupported expression: $expression',
          );
        });

        final toolCall = ToolCall(
          id: 'call_123',
          callType: 'function',
          function: FunctionCall(
            name: 'calculate',
            arguments: '{"expression": "2+2"}',
          ),
        );

        final result = await capability.executeTool(toolCall);

        expect(result.toolCallId, equals('call_123'));
        expect(result.content, equals('4'));
        expect(result.isError, isFalse);
        expect(result.metadata?['calculation'], equals('2+2'));
      });

      test('should handle tool execution error', () async {
        capability.registerToolExecutor('failing_tool', (toolCall) async {
          return ToolResult.error(
            toolCallId: toolCall.id,
            errorMessage: 'Tool execution failed',
            metadata: {'error_type': 'execution_error'},
          );
        });

        final toolCall = ToolCall(
          id: 'call_456',
          callType: 'function',
          function: FunctionCall(
            name: 'failing_tool',
            arguments: '{}',
          ),
        );

        final result = await capability.executeTool(toolCall);

        expect(result.toolCallId, equals('call_456'));
        expect(result.isError, isTrue);
        expect(result.content, equals('Tool execution failed'));
        expect(result.metadata?['error_type'], equals('execution_error'));
      });

      test('should handle unknown tool', () async {
        final toolCall = ToolCall(
          id: 'call_789',
          callType: 'function',
          function: FunctionCall(
            name: 'unknown_tool',
            arguments: '{}',
          ),
        );

        final result = await capability.executeTool(toolCall);

        expect(result.toolCallId, equals('call_789'));
        expect(result.isError, isTrue);
        expect(result.content, contains('Unknown tool'));
      });

      test('should handle executor throwing exception', () async {
        capability.registerErrorExecutor(
            'throwing_tool', Exception('Executor threw exception'));

        final toolCall = ToolCall(
          id: 'call_exception',
          callType: 'function',
          function: FunctionCall(
            name: 'throwing_tool',
            arguments: '{}',
          ),
        );

        expect(() => capability.executeTool(toolCall), throwsException);
      });
    });

    group('Multiple Tool Execution', () {
      test('should execute multiple tools successfully', () async {
        // Register multiple executors
        capability.registerToolExecutor('add', (toolCall) async {
          final args =
              jsonDecode(toolCall.function.arguments) as Map<String, dynamic>;
          final a = args['a'] as num;
          final b = args['b'] as num;
          return ToolResult.success(
            toolCallId: toolCall.id,
            content: (a + b).toString(),
          );
        });

        capability.registerToolExecutor('multiply', (toolCall) async {
          final args =
              jsonDecode(toolCall.function.arguments) as Map<String, dynamic>;
          final a = args['a'] as num;
          final b = args['b'] as num;
          return ToolResult.success(
            toolCallId: toolCall.id,
            content: (a * b).toString(),
          );
        });

        final toolCalls = [
          ToolCall(
            id: 'call_add',
            callType: 'function',
            function: FunctionCall(
              name: 'add',
              arguments: '{"a": 5, "b": 3}',
            ),
          ),
          ToolCall(
            id: 'call_multiply',
            callType: 'function',
            function: FunctionCall(
              name: 'multiply',
              arguments: '{"a": 4, "b": 7}',
            ),
          ),
        ];

        final results = await capability.executeToolsParallel(toolCalls);

        expect(results, hasLength(2));
        expect(results[0].content, equals('8'));
        expect(results[1].content, equals('28'));
        expect(results.every((r) => !r.isError), isTrue);
      });

      test('should handle mixed success and failure', () async {
        capability.registerToolExecutor('success_tool', (toolCall) async {
          return ToolResult.success(
            toolCallId: toolCall.id,
            content: 'Success!',
          );
        });

        capability.registerToolExecutor('failure_tool', (toolCall) async {
          return ToolResult.error(
            toolCallId: toolCall.id,
            errorMessage: 'Failed!',
          );
        });

        final toolCalls = [
          ToolCall(
            id: 'call_success',
            callType: 'function',
            function: FunctionCall(
              name: 'success_tool',
              arguments: '{}',
            ),
          ),
          ToolCall(
            id: 'call_failure',
            callType: 'function',
            function: FunctionCall(
              name: 'failure_tool',
              arguments: '{}',
            ),
          ),
        ];

        final results = await capability.executeToolsParallel(toolCalls);

        expect(results, hasLength(2));
        expect(results[0].isError, isFalse);
        expect(results[0].content, equals('Success!'));
        expect(results[1].isError, isTrue);
        expect(results[1].content, equals('Failed!'));
      });

      test('should handle execution with continue on error', () async {
        capability.registerToolExecutor('normal_tool', (toolCall) async {
          return ToolResult.success(
            toolCallId: toolCall.id,
            content: 'Normal execution',
          );
        });

        capability.registerErrorExecutor(
            'throwing_tool', Exception('Tool throws'));

        final toolCalls = [
          ToolCall(
            id: 'call_normal',
            callType: 'function',
            function: FunctionCall(
              name: 'normal_tool',
              arguments: '{}',
            ),
          ),
          ToolCall(
            id: 'call_throwing',
            callType: 'function',
            function: FunctionCall(
              name: 'throwing_tool',
              arguments: '{}',
            ),
          ),
          ToolCall(
            id: 'call_normal2',
            callType: 'function',
            function: FunctionCall(
              name: 'normal_tool',
              arguments: '{}',
            ),
          ),
        ];

        final config = ParallelToolConfig(continueOnError: true);
        final results =
            await capability.executeToolsParallel(toolCalls, config: config);

        // Should have results for first tool, error result for second, and result for third
        expect(results, hasLength(3));
        expect(results[0].isError, isFalse);
        expect(results[1].isError, isTrue);
        expect(results[1].content, contains('Tool execution failed'));
        expect(results[2].isError, isFalse);
      });

      test('should stop on first error when continueOnError is false',
          () async {
        capability.registerToolExecutor('normal_tool', (toolCall) async {
          return ToolResult.success(
            toolCallId: toolCall.id,
            content: 'Normal execution',
          );
        });

        capability.registerErrorExecutor(
            'throwing_tool', Exception('Tool throws'));

        final toolCalls = [
          ToolCall(
            id: 'call_normal',
            callType: 'function',
            function: FunctionCall(
              name: 'normal_tool',
              arguments: '{}',
            ),
          ),
          ToolCall(
            id: 'call_throwing',
            callType: 'function',
            function: FunctionCall(
              name: 'throwing_tool',
              arguments: '{}',
            ),
          ),
          ToolCall(
            id: 'call_normal2',
            callType: 'function',
            function: FunctionCall(
              name: 'normal_tool',
              arguments: '{}',
            ),
          ),
        ];

        final config = ParallelToolConfig(continueOnError: false);
        final results =
            await capability.executeToolsParallel(toolCalls, config: config);

        // Should have results for first tool and error result for second, but not third
        expect(results, hasLength(2));
        expect(results[0].isError, isFalse);
        expect(results[1].isError, isTrue);
      });
    });

    group('Tool Registration', () {
      test('should register and use tool executor', () async {
        var executorCalled = false;

        capability.registerToolExecutor('test_tool', (toolCall) async {
          executorCalled = true;
          return ToolResult.success(
            toolCallId: toolCall.id,
            content: 'Executor called',
          );
        });

        final toolCall = ToolCall(
          id: 'call_test',
          callType: 'function',
          function: FunctionCall(
            name: 'test_tool',
            arguments: '{}',
          ),
        );

        final result = await capability.executeTool(toolCall);

        expect(executorCalled, isTrue);
        expect(result.content, equals('Executor called'));
      });

      test('should override existing executor', () async {
        // Register first executor
        capability.registerToolExecutor('override_tool', (toolCall) async {
          return ToolResult.success(
            toolCallId: toolCall.id,
            content: 'First executor',
          );
        });

        // Register second executor (should override)
        capability.registerToolExecutor('override_tool', (toolCall) async {
          return ToolResult.success(
            toolCallId: toolCall.id,
            content: 'Second executor',
          );
        });

        final toolCall = ToolCall(
          id: 'call_override',
          callType: 'function',
          function: FunctionCall(
            name: 'override_tool',
            arguments: '{}',
          ),
        );

        final result = await capability.executeTool(toolCall);

        expect(result.content, equals('Second executor'));
      });
    });
  });
}
