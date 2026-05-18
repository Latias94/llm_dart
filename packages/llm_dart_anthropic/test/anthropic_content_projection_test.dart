import 'dart:convert';

import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_anthropic/src/anthropic_cache_control.dart';
import 'package:llm_dart_anthropic/src/anthropic_file_source_encoder.dart';
import 'package:llm_dart_anthropic/src/anthropic_tool_output_encoder.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic content projection', () {
    test('applies Anthropic cache control from prompt part options', () {
      final block = const AnthropicCacheControlEncoder().applyToBlock(
        {
          'type': 'text',
          'text': 'Reusable input',
        },
        providerOptions: const AnthropicPromptPartOptions(
          cacheControl: AnthropicCacheControl.ephemeral(ttl: '1h'),
        ),
        path: 'user.text',
      );

      expect(
        block,
        {
          'type': 'text',
          'text': 'Reusable input',
          'cache_control': {
            'type': 'ephemeral',
            'ttl': '1h',
          },
        },
      );
    });

    test('encodes user document sources with Anthropic file references', () {
      final source = const AnthropicFileSourceEncoder().encodeUserBinarySource(
        mediaType: 'application/pdf',
        data: FileProviderReferenceData(
          ProviderReference({'anthropic': 'file_123'}),
        ),
        path: 'user.document',
      );

      expect(
        source,
        {
          'type': 'file',
          'file_id': 'file_123',
        },
      );
    });

    test('encodes structured tool outputs behind one interface', () {
      final output = const AnthropicToolOutputEncoder().encode(
        ContentToolOutput(
          parts: [
            const TextToolOutputContentPart(
              'forecast',
              providerOptions: AnthropicPromptPartOptions(
                cacheControl: AnthropicCacheControl.ephemeral(ttl: '5m'),
              ),
            ),
            const JsonToolOutputContentPart({
              'ok': true,
            }),
            FileToolOutputContentPart(
              mediaType: 'text/plain',
              filename: 'notes.txt',
              data: FileBytesData(utf8.encode('hello')),
            ),
          ],
        ),
        path: 'toolResult(toolu_1).output',
      );

      expect(
        output,
        [
          {
            'type': 'text',
            'text': 'forecast',
            'cache_control': {
              'type': 'ephemeral',
              'ttl': '5m',
            },
          },
          {
            'type': 'text',
            'text': '{"ok":true}',
          },
          {
            'type': 'document',
            'source': {
              'type': 'base64',
              'media_type': 'text/plain',
              'data': 'aGVsbG8=',
            },
            'title': 'notes.txt',
          },
        ],
      );
    });
  });
}
