import 'package:llm_dart_chat/llm_dart_chat.dart';
import 'package:test/test.dart';

void main() {
  group('ToolExecutionRegistry', () {
    test('dispatches to the registered tool handler by tool name', () async {
      final calls = <String>[];
      final registry = ToolExecutionRegistry(
        handlers: {
          'weather': (request) {
            calls.add(request.toolName);
            return const ToolExecutionResult.output({
              'temperature': 24,
            });
          },
        },
      );

      final result = await registry.call(
        const ToolExecutionRequest(
          chatId: 'chat-1',
          messageId: 'msg-1',
          toolCallId: 'tool-1',
          toolName: 'weather',
          input: {
            'location': 'Tokyo',
          },
        ),
      );

      expect(calls, ['weather']);
      expect(result, isNotNull);
      expect(result!.isError, isFalse);
      expect(result.output, {
        'temperature': 24,
      });
    });

    test('uses fallback when no named handler matches', () async {
      final calls = <String>[];
      final registry = ToolExecutionRegistry(
        fallback: (request) {
          calls.add(request.toolName);
          return const ToolExecutionResult.error('unsupported tool');
        },
      );

      final result = await registry.call(
        const ToolExecutionRequest(
          chatId: 'chat-1',
          messageId: 'msg-1',
          toolCallId: 'tool-1',
          toolName: 'calendar',
        ),
      );

      expect(calls, ['calendar']);
      expect(result, isNotNull);
      expect(result!.isError, isTrue);
      expect(result.output, 'unsupported tool');
    });

    test('withHandler returns a new registry without mutating the original',
        () async {
      final original = ToolExecutionRegistry();
      final updated = original.withHandler(
        'weather',
        (_) => const ToolExecutionResult.output('ok'),
      );

      expect(original.hasHandlerFor('weather'), isFalse);
      expect(updated.hasHandlerFor('weather'), isTrue);
      expect(
        await updated.call(
          const ToolExecutionRequest(
            chatId: 'chat-1',
            messageId: 'msg-1',
            toolCallId: 'tool-1',
            toolName: 'weather',
          ),
        ),
        isNotNull,
      );
    });

    test('ToolExecutionRequest.requireJsonObjectInput normalizes map input',
        () {
      final request = _toolRequest(
        input: <Object?, Object?>{
          'location': 'Tokyo',
          'days': 3,
        },
      );

      expect(request.requireJsonObjectInput(), {
        'location': 'Tokyo',
        'days': 3,
      });
    });

    test('ToolExecutionRequest.requireJsonObjectInput rejects non-map input',
        () {
      final request = _toolRequest(
        input: const ['Tokyo'],
      );

      expect(
        request.requireJsonObjectInput,
        throwsA(
          isA<ToolInputDecodeException>()
              .having((error) => error.toolName, 'toolName', 'weather')
              .having((error) => error.toolCallId, 'toolCallId', 'tool-1')
              .having(
                (error) => error.message,
                'message',
                contains('expected a JSON object input'),
              ),
        ),
      );
    });

    test('ToolExecutionRequest.requireJsonObjectInput rejects non-string keys',
        () {
      final request = _toolRequest(
        input: {
          1: 'Tokyo',
        },
      );

      expect(
        request.requireJsonObjectInput,
        throwsA(
          isA<ToolInputDecodeException>().having(
            (error) => error.message,
            'message',
            contains('input object keys must be strings'),
          ),
        ),
      );
    });

    test('ToolExecutionRequest.decodeJsonObjectInput wraps decoder failures',
        () {
      final request = _toolRequest(
        input: <Object?, Object?>{
          'location': 'Tokyo',
        },
      );

      expect(
        () => request.decodeJsonObjectInput<String>((json) {
          throw StateError('decoder crashed');
        }),
        throwsA(
          isA<ToolInputDecodeException>()
              .having((error) => error.toolName, 'toolName', 'weather')
              .having((error) => error.toolCallId, 'toolCallId', 'tool-1')
              .having((error) => error.cause, 'cause', isA<StateError>())
              .having(
                (error) => error.message,
                'message',
                contains('decoder crashed'),
              ),
        ),
      );
    });

    test('withJsonHandler decodes JSON input before invoking the handler',
        () async {
      final handledLocations = <String>[];
      final registry = ToolExecutionRegistry().withJsonHandler<String>(
        'weather',
        decode: (json) => json['location'] as String,
        handle: (request, location) {
          handledLocations.add(location);
          expect(request.toolName, 'weather');
          return ToolExecutionResult.output({
            'location': location,
          });
        },
      );

      final result = await registry.call(
        _toolRequest(
          input: <Object?, Object?>{
            'location': 'Tokyo',
          },
        ),
      );

      expect(handledLocations, ['Tokyo']);
      expect(result, isNotNull);
      expect(result!.isError, isFalse);
      expect(result.output, {
        'location': 'Tokyo',
      });
    });

    test('withJsonHandler returns a tool error when decode fails', () async {
      final registry = ToolExecutionRegistry().withJsonHandler<String>(
        'weather',
        decode: (json) => json['location'] as String,
        handle: (request, location) => ToolExecutionResult.output({
          'location': location,
        }),
      );

      final result = await registry.call(
        _toolRequest(
          input: <String, Object?>{
            'location': 42,
          },
        ),
      );

      expect(result, isNotNull);
      expect(result!.isError, isTrue);
      expect(result.output, isA<String>());
      expect(
        result.output as String,
        contains('Failed to decode tool "weather" input'),
      );
    });

    test('withJsonHandler allows overriding decode failure handling', () async {
      final registry = ToolExecutionRegistry().withJsonHandler<String>(
        'weather',
        decode: (json) => json['location'] as String,
        handle: (request, location) => ToolExecutionResult.output({
          'location': location,
        }),
        onDecodeError: (error, request) {
          expect(request.toolName, 'weather');
          expect(error.toolCallId, 'tool-1');
          return const ToolExecutionResult.error({
            'code': 'invalid_tool_input',
          });
        },
      );

      final result = await registry.call(
        _toolRequest(
          input: const ['Tokyo'],
        ),
      );

      expect(result, isNotNull);
      expect(result!.isError, isTrue);
      expect(result.output, {
        'code': 'invalid_tool_input',
      });
    });
  });
}

ToolExecutionRequest _toolRequest({
  Object? input,
  String toolName = 'weather',
}) {
  return ToolExecutionRequest(
    chatId: 'chat-1',
    messageId: 'msg-1',
    toolCallId: 'tool-1',
    toolName: toolName,
    input: input,
  );
}
