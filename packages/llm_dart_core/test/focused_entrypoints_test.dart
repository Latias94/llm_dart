import 'package:llm_dart_core/foundation.dart' as foundation;
import 'package:llm_dart_core/model.dart' as model;
import 'package:llm_dart_core/serialization.dart' as serialization;
import 'package:llm_dart_core/ui.dart' as ui;
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

      expect(metadata['test'], {'enabled': true});
      expect(prompt.role, foundation.PromptRole.user);
      expect(tool.name, 'lookup');
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
  Future<model.GenerateTextResult> generate(model.GenerateTextRequest request) {
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
  Stream<model.TextStreamEvent> stream(model.GenerateTextRequest request) {
    return Stream<model.TextStreamEvent>.fromIterable([
      const model.TextStartEvent(id: 'text-1'),
      const model.TextDeltaEvent(id: 'text-1', delta: 'echo'),
      const model.TextEndEvent(id: 'text-1'),
      const model.FinishEvent(finishReason: model.FinishReason.stop),
    ]);
  }
}
