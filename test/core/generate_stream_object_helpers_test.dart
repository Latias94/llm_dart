// Streaming structured object helper tests (prompt-first).

import 'dart:async';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';
import '../utils/mock_provider_factory.dart';

class FakeStreamChatResponse implements ChatResponse {
  final String _text;

  FakeStreamChatResponse(this._text);

  @override
  String? get text => _text;

  @override
  List<ToolCall>? get toolCalls => const [];

  @override
  UsageInfo? get usage => null;

  @override
  String? get thinking => null;

  @override
  List<CallWarning> get warnings => const [];

  @override
  Map<String, dynamic>? get metadata => null;

  @override
  CallMetadata? get callMetadata => null;
}

class FakeStreamProvider implements ChatCapability {
  @override
  Future<ChatResponse> chat(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    return FakeStreamChatResponse('{"value":42}');
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    // Stream JSON in two chunks to exercise buffering logic.
    yield const TextDeltaEvent('{"value":');
    yield const TextDeltaEvent('42}');
    yield CompletionEvent(FakeStreamChatResponse('{"value":42}'));
  }
}

void main() {
  group('streamObject helper', () {
    setUp(() {
      LLMProviderRegistry.registerOrReplace(
        MockProviderFactory<ChatCapability>(
          providerId: 'fake-stream',
          supportedCapabilities: {
            LLMCapability.chat,
            LLMCapability.streaming,
          },
          create: (_) => FakeStreamProvider(),
        ),
      );
    });

    tearDown(() {
      LLMProviderRegistry.unregister('fake-stream');
    });

    test('should stream events and parse structured JSON', () async {
      final output = OutputSpec<int>.object(
        name: 'IntValue',
        properties: {
          'value': ParameterProperty(
            propertyType: 'integer',
            description: 'Integer value',
          ),
        },
        fromJson: (json) => json['value'] as int,
      );

      final result = streamObject<int>(
        model: 'fake-stream:test-model',
        output: output,
        prompt: 'Return a JSON object with value 42',
      );

      final events = <ChatStreamEvent>[];
      await result.events.forEach(events.add);

      expect(events.whereType<TextDeltaEvent>().isNotEmpty, isTrue);
      expect(events.whereType<CompletionEvent>().isNotEmpty, isTrue);

      final objectResult = await result.asObject;
      expect(objectResult.object, equals(42));
    });

    test('should fall back to completion text when no chunks produced',
        () async {
      // Override provider with one that sends no TextDeltaEvent chunks,
      // only a completion containing JSON in the response text.
      LLMProviderRegistry.registerOrReplace(
        MockProviderFactory<ChatCapability>(
          providerId: 'fake-stream',
          supportedCapabilities: {
            LLMCapability.chat,
            LLMCapability.streaming,
          },
          create: (_) => _CompletionOnlyStreamProvider(),
        ),
      );

      final output = OutputSpec.intValue();

      final result = streamObject<int>(
        model: 'fake-stream:test-model',
        output: output,
        prompt: 'Return a JSON object with value 13',
      );

      // We still expect a completion event even without text deltas.
      final events = <ChatStreamEvent>[];
      await result.events.forEach(events.add);
      expect(events.whereType<CompletionEvent>().isNotEmpty, isTrue);

      final objectResult = await result.asObject;
      expect(objectResult.object, equals(13));
    });

    test('should throw ResponseFormatError when JSON cannot be parsed',
        () async {
      // Provider that streams invalid JSON chunks and a final invalid text.
      LLMProviderRegistry.registerOrReplace(
        MockProviderFactory<ChatCapability>(
          providerId: 'fake-stream',
          supportedCapabilities: {
            LLMCapability.chat,
            LLMCapability.streaming,
          },
          create: (_) => _InvalidJsonStreamProvider(),
        ),
      );

      final output = OutputSpec.intValue();

      final result = streamObject<int>(
        model: 'fake-stream:test-model',
        output: output,
        prompt: 'Return invalid JSON',
      );

      expect(
        () => result.asObject,
        throwsA(isA<ResponseFormatError>()),
      );
    });

    test('should parse JSON inside fenced code block', () async {
      // Provider that wraps the JSON object in a ```json fenced block.
      LLMProviderRegistry.registerOrReplace(
        MockProviderFactory<ChatCapability>(
          providerId: 'fake-stream',
          supportedCapabilities: {
            LLMCapability.chat,
            LLMCapability.streaming,
          },
          create: (_) => _CodeFenceStreamProvider(),
        ),
      );

      final output = OutputSpec.intValue();

      final result = streamObject<int>(
        model: 'fake-stream:test-model',
        output: output,
        prompt: 'Return a JSON object with value 99 inside a code block',
      );

      final events = <ChatStreamEvent>[];
      await result.events.forEach(events.add);
      expect(events.whereType<TextDeltaEvent>().isNotEmpty, isTrue);

      final objectResult = await result.asObject;
      expect(objectResult.object, equals(99));
    });

    test('should extract first balanced JSON object from mixed text', () async {
      // Provider that emits text with an embedded JSON object and
      // additional prose before and after.
      LLMProviderRegistry.registerOrReplace(
        MockProviderFactory<ChatCapability>(
          providerId: 'fake-stream',
          supportedCapabilities: {
            LLMCapability.chat,
            LLMCapability.streaming,
          },
          create: (_) => _EmbeddedJsonStreamProvider(),
        ),
      );

      final output = OutputSpec.intValue();

      final result = streamObject<int>(
        model: 'fake-stream:test-model',
        output: output,
        prompt: 'Return a JSON object with value 7 embedded in text',
      );

      final events = <ChatStreamEvent>[];
      await result.events.forEach(events.add);
      expect(events.whereType<TextDeltaEvent>().isNotEmpty, isTrue);

      final objectResult = await result.asObject;
      expect(objectResult.object, equals(7));
    });

    test('propagates warnings from completion response', () async {
      final warnings = [
        const CallWarning(
          code: 'STREAM_WARNING',
          message: 'Test streaming warning',
        ),
      ];

      LLMProviderRegistry.registerOrReplace(
        MockProviderFactory<ChatCapability>(
          providerId: 'fake-stream',
          supportedCapabilities: {
            LLMCapability.chat,
            LLMCapability.streaming,
          },
          create: (_) => _WarningStreamProvider(warnings),
        ),
      );

      final output = OutputSpec.intValue();

      final result = streamObject<int>(
        model: 'fake-stream:test-model',
        output: output,
        prompt: 'Return a JSON object with value 5 and warnings',
      );

      final objectResult = await result.asObject;
      expect(objectResult.object, equals(5));
      expect(objectResult.textResult.warnings, equals(warnings));
    });

    test('should throw StructuredOutputError when JSON does not match schema',
        () async {
      // Provider that returns syntactically valid JSON which violates
      // the OutputSpec schema (string instead of integer).
      LLMProviderRegistry.registerOrReplace(
        MockProviderFactory<ChatCapability>(
          providerId: 'fake-stream',
          supportedCapabilities: {
            LLMCapability.chat,
            LLMCapability.streaming,
          },
          create: (_) => _SchemaMismatchStreamProvider(),
        ),
      );

      final output = OutputSpec.intValue();

      final result = streamObject<int>(
        model: 'fake-stream:test-model',
        output: output,
        prompt: 'Return JSON with a value that violates the schema',
      );

      expect(
        () => result.asObject,
        throwsA(isA<StructuredOutputError>()),
      );
    });
  });
}

/// Stream provider that only emits a completion with JSON text, without
/// intermediate [TextDeltaEvent] chunks.
class _CompletionOnlyStreamProvider implements ChatCapability {
  @override
  Future<ChatResponse> chat(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    return FakeStreamChatResponse('{"value":13}');
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    yield CompletionEvent(FakeStreamChatResponse('{"value":13}'));
  }
}

/// Stream provider that emits JSON which does not conform to the
/// OutputSpec schema (type mismatch), exercising schema validation in
/// the streaming structured object helper.
class _SchemaMismatchStreamProvider implements ChatCapability {
  static const _invalidJson = '{"value":"not-an-int"}';

  @override
  Future<ChatResponse> chat(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    return FakeStreamChatResponse(_invalidJson);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    yield const TextDeltaEvent('{"value":"');
    yield const TextDeltaEvent('not-an-int"}');
    yield CompletionEvent(FakeStreamChatResponse(_invalidJson));
  }
}

class _WarningStreamResponse implements ChatResponse {
  final String _text;
  final List<CallWarning> _warnings;

  _WarningStreamResponse(this._text, this._warnings);

  @override
  String? get text => _text;

  @override
  List<ToolCall>? get toolCalls => const [];

  @override
  UsageInfo? get usage => null;

  @override
  String? get thinking => null;

  @override
  List<CallWarning> get warnings => _warnings;

  @override
  Map<String, dynamic>? get metadata => null;

  @override
  CallMetadata? get callMetadata => null;
}

class _WarningStreamProvider implements ChatCapability {
  final List<CallWarning> _warnings;

  _WarningStreamProvider(this._warnings);

  @override
  Future<ChatResponse> chat(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    return _WarningStreamResponse('{"value":5}', _warnings);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    yield const TextDeltaEvent('{"value":5}');
    yield CompletionEvent(_WarningStreamResponse('{"value":5}', _warnings));
  }
}

/// Stream provider that emits invalid JSON so that [streamObject] fails.
class _InvalidJsonStreamProvider implements ChatCapability {
  @override
  Future<ChatResponse> chat(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    return FakeStreamChatResponse('not valid json');
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    yield const TextDeltaEvent('not ');
    yield const TextDeltaEvent('json');
    yield CompletionEvent(FakeStreamChatResponse('still not json'));
  }
}

/// Stream provider that emits a fenced ```json code block containing the
/// structured output, exercising the fenced parsing path.
class _CodeFenceStreamProvider implements ChatCapability {
  static const _payload =
      'Here is your data:\n```json\n{"value":99}\n``` Thanks.';

  @override
  Future<ChatResponse> chat(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    return FakeStreamChatResponse(_payload);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    yield const TextDeltaEvent(_payload);
    yield CompletionEvent(FakeStreamChatResponse(_payload));
  }
}

/// Stream provider that emits raw text with an embedded JSON object and
/// additional prose, exercising the "first balanced JSON object" path.
class _EmbeddedJsonStreamProvider implements ChatCapability {
  static const _payload =
      'Some intro text before JSON. {"value":7} Some trailing notes.';

  @override
  Future<ChatResponse> chat(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    return FakeStreamChatResponse(_payload);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    // Emit the payload in two chunks to exercise concatenation.
    yield const TextDeltaEvent(
      'Some intro text before JSON. {"val',
    );
    yield const TextDeltaEvent(
      'ue":7} Some trailing notes.',
    );
    yield CompletionEvent(FakeStreamChatResponse(_payload));
  }
}
