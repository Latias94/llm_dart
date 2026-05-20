import 'package:llm_dart_google/src/google_custom_part_summary_projection.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('Google custom part summary projection', () {
    test('formats provider tool names for display', () {
      expect(googleCustomPartDisplayToolName('google_search'), 'Google Search');
      expect(
          googleCustomPartDisplayToolName('codeExecution'), 'Code Execution');
      expect(googleCustomPartDisplayToolName('render-chart'), 'Render Chart');
      expect(googleCustomPartDisplayToolName(''), '');
    });

    test('extracts metadata, status text, and preview values', () {
      expect(
        googleCustomPartMetadataString(
          const ProviderMetadata({
            'google': {
              'thoughtSignature': 'sig_123',
            },
          }),
          'thoughtSignature',
        ),
        'sig_123',
      );
      expect(googleCustomPartStatusText({'status': 'ok'}), 'ok');
      expect(googleCustomPartStatusText({'message': 'done'}), 'done');
      expect(googleCustomPartPreviewFromValue({'text': 'hello'}), 'hello');
      expect(googleCustomPartPreviewFromValue(42), '42');
      expect(googleCustomPartPreviewText('abcd', maxLength: 3), 'ab…');
    });

    test('projects response links and result count', () {
      final payload = {
        'result': {
          'items': [
            {
              'uri': 'https://dart.dev',
              'title': 'Dart',
            },
            {
              'url': 'not a uri',
              'title': 'skip',
            },
            {
              'url': 'https://pub.dev',
            },
          ],
        },
      };

      final links = googleCustomPartResponseLinks(payload);

      expect(googleCustomPartResponseItemCount(payload), 3);
      expect(links, hasLength(2));
      expect(links.first.uri, Uri.parse('https://dart.dev'));
      expect(links.first.title, 'Dart');
      expect(links.last.uri, Uri.parse('https://pub.dev'));
      expect(links.last.title, isNull);
    });
  });
}
