import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('GoogleCustomPartSummary', () {
    test('builds summaries for server tool calls', () {
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

      final summary = GoogleCustomPartSummary.fromPart(
        GoogleToolCallCustomPart(replay),
      );

      expect(summary.title, 'Google Search');
      expect(summary.subtitle, 'Server Tool Call');
      expect(summary.previewText, 'Dart SDK');
      expect(
        Map<String, String>.fromEntries(
          summary.fields.map((field) => MapEntry(field.label, field.value)),
        ),
        {
          'Tool': 'google_search',
          'Tool Call ID': 'srvtool_1',
          'Query': 'Dart SDK',
          'Thought Signature': 'sig_srvtool_1',
        },
      );
      expect(summary.links, isEmpty);
      expect(summary.files, isEmpty);
    });

    test('builds summaries for server tool responses', () {
      final replay = GoogleToolResponseReplay.fromToolResponse(
        {
          'id': 'srvtool_1',
          'toolType': 'google_search',
          'result': {
            'items': [
              {
                'uri': 'https://dart.dev',
                'title': 'Dart',
              },
              {
                'uri': 'https://pub.dev',
                'title': 'pub.dev',
              },
            ],
          },
        },
      );

      final summary = GoogleCustomPartSummary.fromPart(
        GoogleToolResponseCustomPart(replay),
      );

      expect(summary.title, 'Google Search');
      expect(summary.subtitle, 'Server Tool Response');
      expect(summary.previewText, 'Dart');
      expect(
        Map<String, String>.fromEntries(
          summary.fields.map((field) => MapEntry(field.label, field.value)),
        ),
        {
          'Tool': 'google_search',
          'Tool Call ID': 'srvtool_1',
          'Result Count': '2',
        },
      );
      expect(summary.links, hasLength(2));
      expect(summary.links.first.uri, Uri.parse('https://dart.dev'));
      expect(summary.links.first.title, 'Dart');
      expect(summary.files, isEmpty);
    });

    test('builds summaries for function responses with files', () {
      final replay = GoogleFunctionResponseReplay(
        toolCallId: 'call_google_2',
        toolName: 'render_chart',
        functionCallId: 'call_google_2',
        response: {
          'status': 'ok',
          'message': 'Chart rendered.',
        },
        files: const [
          GeneratedFile(
            mediaType: 'image/png',
            filename: 'chart.png',
            data: FileBytesData.constBytes([1, 2, 3]),
          ),
        ],
      );

      final summary = GoogleCustomPartSummary.fromPart(
        GoogleFunctionResponseCustomPart(replay),
      );

      expect(summary.title, 'Render Chart');
      expect(summary.subtitle, 'Function Response');
      expect(summary.previewText, 'ok');
      expect(
        Map<String, String>.fromEntries(
          summary.fields.map((field) => MapEntry(field.label, field.value)),
        ),
        {
          'Tool': 'render_chart',
          'Tool Call ID': 'call_google_2',
          'Function Call ID': 'call_google_2',
          'Status': 'ok',
          'Files': '1',
        },
      );
      expect(summary.links, isEmpty);
      expect(summary.files.single.filename, 'chart.png');
    });

    test('parses content parts through one typed summary entrypoint', () {
      final summaries = GoogleCustomPartSummary.parseContentParts([
        GoogleToolCallReplay.fromToolCall(
          {
            'id': 'srvtool_1',
            'toolType': 'google_search',
            'query': 'Dart SDK',
          },
        ).toCustomContentPart(),
        GoogleToolResponseReplay.fromToolResponse(
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
        ).toCustomContentPart(),
        const CustomContentPart(
          kind: 'openai.compaction',
          data: {
            'id': 'cmp_1',
          },
        ),
      ]);

      expect(summaries, hasLength(2));
      expect(summaries.first.title, 'Google Search');
      expect(summaries.last.subtitle, 'Server Tool Response');
    });
  });
}
