import 'package:llm_dart_anthropic/src/anthropic_stream_tool_projection.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic stream tool projection', () {
    test('emits a complete prepopulated tool call event sequence', () {
      final metadata = ProviderMetadata.forNamespace('anthropic', {
        'caller': {
          'type': 'direct',
        },
      });
      final projected = projectAnthropicToolCall(
        toolCallId: 'toolu_1',
        toolName: 'search',
        input: {
          'query': 'anthropic docs',
        },
        providerMetadata: metadata,
      );

      final events = emitAnthropicProjectedToolCallEvents(projected).toList();

      expect(events[0], isA<ToolInputStartEvent>());
      expect(events[1], isA<ToolInputDeltaEvent>());
      expect(events[2], isA<ToolInputEndEvent>());
      expect(events[3], isA<ToolCallEvent>());

      final deltaEvent = events[1] as ToolInputDeltaEvent;
      expect(deltaEvent.delta, '{"query":"anthropic docs"}');

      final toolCallEvent = events[3] as ToolCallEvent;
      expect(toolCallEvent.toolCall.toolCallId, 'toolu_1');
      expect(toolCallEvent.toolCall.toolName, 'search');
      expect(toolCallEvent.toolCall.input, {
        'query': 'anthropic docs',
      });
      expect(toolCallEvent.providerMetadata, metadata);
    });

    test('suppresses initial null input deltas for streamed tool blocks', () {
      final projected = projectAnthropicToolCall(
        toolCallId: 'toolu_2',
        toolName: 'weather',
        input: null,
        providerMetadata: null,
        emitInputDeltaForNull: false,
      );

      final events = emitAnthropicToolInputStartEvents(projected).toList();

      expect(projected.encodedInput, isEmpty);
      expect(events, hasLength(1));
      expect(events.single, isA<ToolInputStartEvent>());
    });

    test('projects malformed finished input as a tool input error', () {
      final projection = projectAnthropicFinishedToolInput(
        toolCallId: 'toolu_bad_1',
        toolName: 'weather',
        encodedInput: '{"city":',
        providerMetadata: null,
      );

      final events = projection.emitEvents().toList();

      expect(projection.hasToolCall, isFalse);
      expect(events, hasLength(1));
      expect(events.single, isA<ToolInputErrorEvent>());

      final errorEvent = events.single as ToolInputErrorEvent;
      expect(errorEvent.toolCallId, 'toolu_bad_1');
      expect(errorEvent.toolName, 'weather');
      expect(errorEvent.input, '{"city":');
      expect(
        errorEvent.errorText,
        contains('Invalid JSON tool arguments for "weather"'),
      );
    });

    test('projects provider-executed web search results and sources', () {
      final descriptorMetadata = ProviderMetadata.forNamespace('anthropic', {
        'blockIndex': 0,
        'providerToolName': 'web_search',
      });
      final contentBlock = {
        'type': 'web_search_tool_result',
        'tool_use_id': 'srvtoolu_1',
        'content': [
          {
            'url': 'https://dart.dev',
            'title': 'Dart',
            'type': 'web_search_result',
            'page_age': '1d',
          },
        ],
      };

      final events = emitAnthropicImmediateToolResultEvents(
        blockType: 'web_search_tool_result',
        contentBlock: contentBlock,
        descriptorProviderMetadata: descriptorMetadata,
        descriptorToolName: 'web_search',
        descriptorIsDynamic: true,
      ).toList();

      expect(events[0], isA<ToolResultEvent>());
      expect(events[1], isA<CustomEvent>());
      expect(events[2], isA<SourceEvent>());

      final resultEvent = events[0] as ToolResultEvent;
      expect(resultEvent.toolResult.toolCallId, 'srvtoolu_1');
      expect(resultEvent.toolResult.toolName, 'web_search');
      expect(resultEvent.toolResult.isDynamic, isTrue);
      expect(resultEvent.toolResult.toolOutput, isA<JsonToolOutput>());
      expect(resultEvent.providerMetadata?.values['anthropic'], {
        'blockIndex': 0,
        'providerToolName': 'web_search',
        'blockType': 'web_search_tool_result',
      });

      final replayEvent = events[1] as CustomEvent;
      expect(replayEvent.kind, 'anthropic.result.web_search');
      expect(replayEvent.providerMetadata, resultEvent.providerMetadata);

      final sourceEvent = events[2] as SourceEvent;
      expect(sourceEvent.source.sourceId, 'https://dart.dev');
      expect(sourceEvent.source.title, 'Dart');
      expect(sourceEvent.source.providerMetadata?.values['anthropic'], {
        'pageAge': '1d',
        'resultType': 'web_search_result',
      });
    });

    test('falls back to a raw custom event without a tool_use_id', () {
      final events = emitAnthropicImmediateToolResultEvents(
        blockType: 'web_fetch_tool_result',
        contentBlock: {
          'type': 'web_fetch_tool_result',
          'content': {
            'type': 'web_fetch_result',
          },
        },
        descriptorProviderMetadata: null,
        descriptorToolName: null,
        descriptorIsDynamic: null,
      ).toList();

      expect(events, hasLength(1));
      expect(events.single, isA<CustomEvent>());

      final customEvent = events.single as CustomEvent;
      expect(customEvent.kind, 'anthropic.web_fetch_tool_result');
      expect(customEvent.providerMetadata, isNull);
    });
  });
}
