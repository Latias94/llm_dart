import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('JsonSchema', () {
    test('normalizes object schemas as immutable JSON maps', () {
      final schema = JsonSchema.object(
        properties: {
          'name': JsonSchema.string().toJson(),
        },
        required: const ['name'],
      );

      expect(schema.toJson(), {
        'type': 'object',
        'properties': {
          'name': {
            'type': 'string',
          },
        },
        'required': ['name'],
      });
      expect(() => schema.toJson()['type'] = 'array', throwsUnsupportedError);
    });
  });

  group('UsageStats', () {
    test('merges nullable token counts', () {
      expect(
        const UsageStats(inputTokens: 2).mergedWith(
          const UsageStats(outputTokens: 3, totalTokens: 5),
        ),
        const UsageStats(inputTokens: 2, outputTokens: 3, totalTokens: 5),
      );
    });
  });

  group('ModelWarning', () {
    test('uses value equality', () {
      expect(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          message: 'not supported',
          field: 'temperature',
        ),
        const ModelWarning(
          type: ModelWarningType.unsupported,
          message: 'not supported',
          field: 'temperature',
        ),
      );
    });
  });

  group('SerializationJsonSupport', () {
    test('encodes provider-owned shared data structures', () {
      final encoded = SerializationJsonSupport.encodeGeneratedFile(
        const GeneratedFile(
          mediaType: 'text/plain',
          filename: 'note.txt',
          data: FileTextData('hello'),
        ),
      );

      expect(encoded, {
        'mediaType': 'text/plain',
        'filename': 'note.txt',
        'data': {
          'type': 'text',
          'text': 'hello',
        },
      });
      expect(
        SerializationJsonSupport.decodeGeneratedFile(
          encoded,
          path: r'$.file',
        ).text,
        'hello',
      );
    });
  });
}
