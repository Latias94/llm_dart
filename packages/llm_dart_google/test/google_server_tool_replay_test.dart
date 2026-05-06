import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:test/test.dart';

void main() {
  group('Google server-side tool replay helpers', () {
    test('round-trip GoogleToolCallReplay through custom prompt parts', () {
      final replay = GoogleToolCallReplay.fromToolCall(
        {
          'id': 'srvtool_1',
          'toolType': 'google_search',
          'query': 'Dart SDK',
        },
        providerMetadata: const ProviderMetadata({
          'google': {
            'thoughtSignature': 'sig_srvtool_1',
          },
        }),
      );

      final promptPart = replay.toCustomPromptPart();
      final parsed = GoogleToolCallReplay.tryParsePromptPart(promptPart);

      expect(parsed, isNotNull);
      expect(parsed!.toolCallId, 'srvtool_1');
      expect(parsed.toolName, 'google_search');
      expect(parsed.toolCall, {
        'id': 'srvtool_1',
        'toolType': 'google_search',
        'query': 'Dart SDK',
      });
      expect(
        parsed.providerMetadata?.values['google'],
        allOf(
          containsPair('serverToolPart', 'toolCall'),
          containsPair('toolCallId', 'srvtool_1'),
          containsPair('toolType', 'google_search'),
          containsPair('thoughtSignature', 'sig_srvtool_1'),
        ),
      );
      expect(parsed.toJson(), replay.toJson());
    });

    test('round-trip GoogleToolResponseReplay through custom events', () {
      final replay = GoogleToolResponseReplay.fromToolResponse(
        {
          'id': 'srvtool_1',
          'toolType': 'google_search',
          'result': {
            'items': [
              {
                'uri': 'https://dart.dev',
              },
            ],
          },
        },
      );

      final event = replay.toCustomEvent();
      final parsed = GoogleToolResponseReplay.tryParseEvent(event);

      expect(parsed, isNotNull);
      expect(parsed!.toolCallId, 'srvtool_1');
      expect(parsed.toolName, 'google_search');
      expect(parsed.toolResponse, {
        'id': 'srvtool_1',
        'toolType': 'google_search',
        'result': {
          'items': [
            {
              'uri': 'https://dart.dev',
            },
          ],
        },
      });
      expect(parsed.toJson(), replay.toJson());
    });
  });
}
