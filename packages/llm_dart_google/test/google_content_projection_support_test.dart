import 'package:llm_dart_google/src/google_content_projection_support.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('Google projected tool projection', () {
    test('maps projected tool calls to content parts and stream events', () {
      const metadata = ProviderMetadata({
        'google': {
          'thoughtSignature': 'sig_tool',
        },
      });
      const projected = GoogleProjectedToolCall(
        toolCallId: 'code-execution-0',
        toolName: 'code_execution',
        input: {
          'language': 'PYTHON',
          'code': 'print("hi")',
        },
        encodedInput: '{"language":"PYTHON","code":"print(\\"hi\\")"}',
        providerExecuted: true,
        isDynamic: true,
        providerMetadata: metadata,
      );

      final contentPart = googleProjectedToolCallContentPart(projected);
      expect(contentPart.providerMetadata, metadata);
      expect(contentPart.toolCall.toolCallId, 'code-execution-0');
      expect(contentPart.toolCall.toolName, 'code_execution');
      expect(contentPart.toolCall.providerExecuted, isTrue);
      expect(contentPart.toolCall.isDynamic, isTrue);
      expect(contentPart.toolCall.input, {
        'language': 'PYTHON',
        'code': 'print("hi")',
      });

      final events = emitGoogleProjectedToolCallEvents(projected).toList();
      expect(events, hasLength(4));

      final start = events[0] as ToolInputStartEvent;
      expect(start.toolCallId, 'code-execution-0');
      expect(start.toolName, 'code_execution');
      expect(start.providerExecuted, isTrue);
      expect(start.isDynamic, isTrue);
      expect(start.providerMetadata, metadata);

      final delta = events[1] as ToolInputDeltaEvent;
      expect(delta.toolCallId, 'code-execution-0');
      expect(delta.delta, '{"language":"PYTHON","code":"print(\\"hi\\")"}');
      expect(delta.providerMetadata, metadata);

      final end = events[2] as ToolInputEndEvent;
      expect(end.toolCallId, 'code-execution-0');
      expect(end.providerMetadata, metadata);

      final toolCall = events[3] as ToolCallEvent;
      expect(toolCall.providerMetadata, metadata);
      expect(toolCall.toolCall.toolCallId, 'code-execution-0');
      expect(toolCall.toolCall.toolName, 'code_execution');
      expect(toolCall.toolCall.providerExecuted, isTrue);
      expect(toolCall.toolCall.isDynamic, isTrue);
    });

    test('maps projected tool results to content parts and stream events', () {
      const metadata = ProviderMetadata({
        'google': {
          'outcome': 'OUTCOME_OK',
        },
      });
      final output = ToolOutput.fromValue({
        'outcome': 'OUTCOME_OK',
        'output': 'hi',
      });
      final projected = GoogleProjectedToolResult(
        toolCallId: 'code-execution-0',
        toolName: 'code_execution',
        toolOutput: output,
        isDynamic: true,
        providerMetadata: metadata,
      );

      final contentPart = googleProjectedToolResultContentPart(projected);
      expect(contentPart.providerMetadata, metadata);
      expect(contentPart.toolResult.toolCallId, 'code-execution-0');
      expect(contentPart.toolResult.toolName, 'code_execution');
      expect(contentPart.toolResult.toolOutput, same(output));
      expect(contentPart.toolResult.isDynamic, isTrue);
      expect(contentPart.toolResult.output, {
        'outcome': 'OUTCOME_OK',
        'output': 'hi',
      });

      final event = googleProjectedToolResultEvent(projected);
      expect(event.providerMetadata, metadata);
      expect(event.toolResult.toolCallId, 'code-execution-0');
      expect(event.toolResult.toolName, 'code_execution');
      expect(event.toolResult.toolOutput, same(output));
      expect(event.toolResult.isDynamic, isTrue);
      expect(event.toolResult.output, {
        'outcome': 'OUTCOME_OK',
        'output': 'hi',
      });
    });
  });
}
