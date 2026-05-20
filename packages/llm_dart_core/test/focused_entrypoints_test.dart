import 'package:llm_dart_core/foundation.dart' as foundation;
import 'package:llm_dart_core/model.dart' as model;
import 'package:llm_dart_core/serialization.dart' as serialization;
import 'package:llm_dart_core/ui.dart' as ui;
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;
import 'package:test/test.dart';

void main() {
  group('focused entrypoints', () {
    test('foundation exposes shared primitive contracts', () {
      final metadata = foundation.ProviderMetadata({
        'test': {'enabled': true},
      });
      final prompt = foundation.UserPromptMessage.text('Hello');
      final tool = foundation.FunctionToolDefinition(
        name: 'lookup',
        inputSchema: foundation.ToolJsonSchema.object(),
      );
      final cancellation = foundation.ProviderCancellation();
      final callOptions = foundation.CallOptions(
        cancellation: cancellation,
      );

      expect(metadata['test'], {'enabled': true});
      expect(prompt.role, foundation.PromptRole.user);
      expect(tool.name, 'lookup');
      expect(callOptions.cancellation, same(cancellation));
      expect(
        foundation.ProviderCancellation.isCancel(
          const foundation.ProviderCancelledException('stop'),
        ),
        isTrue,
      );
    });

    test('model exposes self-contained model and runner contracts', () async {
      final languageModel = _EchoLanguageModel();
      final result = await model.generateText(
        model: languageModel,
        prompt: [
          model.UserPromptMessage.text('Hello'),
        ],
      );

      expect(result.text, 'echo: Hello');
      expect(result.finishReason, model.FinishReason.stop);

      final request = model.GenerateTextRequest(
        prompt: [
          model.UserPromptMessage.text('Hello'),
        ],
      );
      expect(request, isA<provider.GenerateTextRequest>());
      expect(
        model.EmbedRequest(values: const ['Hello']),
        isA<provider.EmbedRequest>(),
      );
      expect(
        model.ImageGenerationRequest(prompt: 'Draw this.'),
        isA<provider.ImageGenerationRequest>(),
      );
      expect(
        const model.SpeechGenerationRequest(
          text: 'Speak this.',
          outputFormat: 'mp3',
          instructions: 'Say it clearly.',
          speed: 1.0,
          language: 'en',
        ),
        isA<provider.SpeechGenerationRequest>(),
      );
      expect(
        const model.TranscriptionRequest(
          audioBytes: [1, 2, 3],
          mediaType: 'audio/wav',
        ),
        isA<provider.TranscriptionRequest>(),
      );
      expect(
        model.ModelCapabilityProfile(
          providerId: 'test',
          modelId: 'model',
          kind: model.ModelCapabilityKind.language,
        ),
        isA<provider.ModelCapabilityProfile>(),
      );
    });

    test('ui exposes message projection contracts', () {
      final message = ui.ChatUiMessage(
        id: 'assistant-1',
        role: ui.ChatUiRole.assistant,
        parts: const [
          ui.TextUiPart(text: 'Hello from UI'),
        ],
      );

      final mapped = const ui.ChatMessageMapper().map(message);

      expect(mapped.text, 'Hello from UI');
    });

    test('serialization exposes codecs and serialized data contracts', () {
      const codec = serialization.PromptJsonCodec();
      final envelope = codec.encodeMessages([
        serialization.UserPromptMessage.text('Serialize me'),
      ]);
      final decoded = codec.decodeMessages(envelope);

      expect(serialization.llmDartJsonSchemaVersion, '2026-03-1');
      expect(decoded.single.role, serialization.PromptRole.user);
    });
  });
}

final class _EchoLanguageModel implements model.LanguageModel {
  @override
  String get modelId => 'echo-model';

  @override
  String get providerId => 'test';

  @override
  Future<model.GenerateTextResult> doGenerate(
    model.GenerateTextRequest request,
  ) {
    final promptText = request.prompt
        .whereType<model.UserPromptMessage>()
        .expand((message) => message.parts)
        .whereType<model.TextPromptPart>()
        .map((part) => part.text)
        .join();

    return Future.value(
      model.GenerateTextResult(
        content: [
          model.TextContentPart('echo: $promptText'),
        ],
        finishReason: model.FinishReason.stop,
      ),
    );
  }

  @override
  Stream<provider.LanguageModelStreamEvent> doStream(
    model.GenerateTextRequest request,
  ) {
    return Stream<provider.LanguageModelStreamEvent>.fromIterable([
      const provider.TextStartEvent(id: 'text-1'),
      const provider.TextDeltaEvent(id: 'text-1', delta: 'echo'),
      const provider.TextEndEvent(id: 'text-1'),
      const provider.FinishEvent(finishReason: model.FinishReason.stop),
    ]);
  }
}
