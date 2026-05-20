import 'package:llm_dart_google/src/google_stream_lifecycle_projection.dart';
import 'package:llm_dart_google/src/google_stream_state.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('Google stream lifecycle projection', () {
    test('captures chunk metadata and emits response metadata once', () {
      final state = GoogleGenerateContentStreamState();

      captureGoogleStreamChunkMetadata(
        {
          'responseId': 'resp_1',
          'modelVersion': 'gemini-3-pro-preview',
          'usageMetadata': {
            'promptTokenCount': 1,
          },
        },
        state,
      );

      final first = maybeCreateGoogleStreamResponseMetadataEvent(state);
      final second = maybeCreateGoogleStreamResponseMetadataEvent(state);

      expect(first, isA<ResponseMetadataEvent>());
      expect((first as ResponseMetadataEvent).responseId, 'resp_1');
      expect(first.modelId, 'gemini-3-pro-preview');
      expect(second, isNull);
      expect(state.usageMetadata, containsPair('promptTokenCount', 1));
    });

    test('captures candidate metadata and emits a single finish event', () {
      final state = GoogleGenerateContentStreamState()
        ..currentTextBlockId = 'text_1'
        ..hasClientToolCalls = true
        ..usageMetadata = {
          'promptTokenCount': 2,
          'candidatesTokenCount': 3,
          'thoughtsTokenCount': 1,
        };

      captureGoogleStreamCandidateMetadata(
        {
          'finishReason': 'STOP',
          'finishMessage': 'done',
          'groundingMetadata': {
            'groundingChunks': [],
          },
          'urlContextMetadata': {
            'urlMetadata': [],
          },
          'safetyRatings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'probability': 'NEGLIGIBLE',
            },
          ],
        },
        state,
      );

      final events = emitGoogleStreamFinish(state).toList();
      final repeated = emitGoogleStreamFinish(state).toList();

      expect(events.first, isA<TextEndEvent>());
      final finish = events.whereType<FinishEvent>().single;
      expect(finish.finishReason, FinishReason.toolCalls);
      expect(finish.rawFinishReason, 'STOP');
      expect(finish.usage?.totalTokens, 6);
      expect(
        finish.providerMetadata?.namespace('google'),
        allOf(
          containsPair('finishMessage', 'done'),
          contains('groundingMetadata'),
          contains('urlContextMetadata'),
          contains('safetyRatings'),
          contains('usageMetadata'),
        ),
      );
      expect(state.finished, isTrue);
      expect(state.currentTextBlockId, isNull);
      expect(repeated, isEmpty);
    });
  });
}
