import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('SerializationJsonSupport tool output codec', () {
    test('round-trips content output parts with provider options callbacks',
        () {
      const options = _TestPromptPartOptions('part-options');
      final encoded = SerializationJsonSupport.encodeToolOutputContentPart(
        const CustomToolOutputContentPart(
          kind: 'provider-result',
          data: {
            'ok': true,
          },
          providerOptions: options,
        ),
        encodeProviderOptions: (options, {required path}) {
          final typed = options as _TestPromptPartOptions;
          expect(path, r'$.toolOutput.parts[].providerOptions');
          return {
            'value': typed.value,
          };
        },
      );

      expect(encoded, {
        'type': 'custom',
        'kind': 'provider-result',
        'data': {
          'ok': true,
        },
        'providerOptions': {
          'value': 'part-options',
        },
      });

      final decoded = SerializationJsonSupport.decodeToolOutputContentPart(
        encoded,
        path: r'$.toolOutput.parts[0]',
        decodeProviderOptions: (value, {required path}) {
          expect(path, r'$.toolOutput.parts[0].providerOptions');
          final map = asJsonMap(value, path: path);
          return _TestPromptPartOptions(
            asJsonString(map['value'], path: '$path.value'),
          );
        },
      ) as CustomToolOutputContentPart;

      expect(decoded.kind, 'provider-result');
      expect(decoded.data, {
        'ok': true,
      });
      expect(
        (decoded.providerOptions as _TestPromptPartOptions).value,
        'part-options',
      );
    });

    test('rejects legacy prompt replay metadata on content parts', () {
      expect(
        () => SerializationJsonSupport.decodeToolOutputContentPart(
          {
            'type': 'text',
            'text': 'done',
            'providerMetadata': {
              'openai': {'id': 'legacy'},
            },
          },
          path: r'$.toolOutput.parts[0]',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Legacy prompt replay metadata is no longer supported'),
          ),
        ),
      );
    });

    test('round-trips nested content tool output', () {
      final output = ContentToolOutput(
        parts: const [
          TextToolOutputContentPart('hello'),
          JsonToolOutputContentPart({
            'value': 1,
          }),
          FileToolOutputContentPart(
            mediaType: 'text/plain',
            filename: 'note.txt',
            data: FileTextData('note'),
          ),
        ],
        providerMetadata: ProviderMetadata.forNamespace('test', {
          'id': 'out-1',
        }),
      );

      final encoded = SerializationJsonSupport.encodeToolOutput(output);
      final decoded = SerializationJsonSupport.decodeToolOutput(
        encoded,
        path: r'$.toolOutput',
      ) as ContentToolOutput;

      expect(decoded.providerMetadata, output.providerMetadata);
      expect(decoded.parts, hasLength(3));
      expect(decoded.parts[0], isA<TextToolOutputContentPart>());
      expect(decoded.parts[1], isA<JsonToolOutputContentPart>());
      expect(decoded.parts[2], isA<FileToolOutputContentPart>());
      expect((decoded.parts[2] as FileToolOutputContentPart).text, 'note');
    });
  });
}

final class _TestPromptPartOptions implements ProviderPromptPartOptions {
  final String value;

  const _TestPromptPartOptions(this.value);
}
