import 'package:llm_dart/ai.dart' as ai;
import 'package:llm_dart/llm_dart.dart' as root;
import 'package:test/test.dart';

void main() {
  group('AI entrypoint', () {
    test('is an explicit alias of the provider-neutral root runtime surface',
        () {
      final root.TransportCancellation cancellation =
          ai.TransportCancellation();
      const ai.GenerateTextOptions aiRequest =
          root.GenerateTextOptions(maxOutputTokens: 32);

      expect(cancellation.isCancelled, isFalse);
      expect(aiRequest.maxOutputTokens, 32);
      expect(ai.generateText, same(root.generateText));
      expect(ai.streamText, same(root.streamText));
    });
  });
}
