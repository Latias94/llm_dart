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
    test('uses value equality with stable feature and setting fields', () {
      expect(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          message: 'not supported',
          feature: 'temperature',
        ),
        const ModelWarning(
          type: ModelWarningType.unsupported,
          message: 'not supported',
          feature: 'temperature',
        ),
      );
      expect(
        const ModelWarning(
          type: ModelWarningType.deprecated,
          message: 'Use responseFormat instead.',
          setting: 'jsonMode',
        ).field,
        'jsonMode',
      );
      expect(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          message: 'not supported',
          feature: 'temperature',
        ),
        const ModelWarning(
          type: ModelWarningType.unsupported,
          message: 'not supported',
          field: 'temperature',
        ),
      );
      expect(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          message: 'not supported',
          field: 'temperature',
        ).feature,
        'temperature',
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

    test('round-trips source references with legacy kind inference', () {
      final source = SourceReference(
        kind: SourceReferenceKind.url,
        sourceId: 'src-1',
        uri: Uri.parse('https://example.com/doc'),
        title: 'Doc',
        providerMetadata: const ProviderMetadata({
          'openai': {'index': 1},
        }),
      );

      final encoded = SerializationJsonSupport.encodeSourceReference(source);

      expect(encoded, {
        'kind': 'url',
        'sourceId': 'src-1',
        'uri': 'https://example.com/doc',
        'title': 'Doc',
        'providerMetadata': {
          'openai': {'index': 1},
        },
      });
      expect(
        SerializationJsonSupport.decodeSourceReference(
          encoded,
          path: r'$.source',
        ).providerMetadata,
        source.providerMetadata,
      );
      expect(
        SerializationJsonSupport.decodeSourceReference(
          {
            'sourceId': 'doc-1',
          },
          path: r'$.source',
        ).kind,
        SourceReferenceKind.document,
      );
      expect(
        SerializationJsonSupport.decodeSourceReference(
          {
            'sourceId': 'url-1',
            'uri': 'https://example.com',
          },
          path: r'$.source',
        ).kind,
        SourceReferenceKind.url,
      );
    });

    test('round-trips model warnings with new and legacy target fields', () {
      const warning = ModelWarning(
        type: ModelWarningType.deprecated,
        message: 'Use responseFormat instead.',
        setting: 'jsonMode',
      );

      final encoded = SerializationJsonSupport.encodeModelWarning(warning);

      expect(encoded, {
        'type': 'deprecated',
        'message': 'Use responseFormat instead.',
        'setting': 'jsonMode',
        'field': 'jsonMode',
      });
      expect(
        SerializationJsonSupport.decodeModelWarning(
          encoded,
          path: r'$.warning',
        ),
        warning,
      );

      final legacy = SerializationJsonSupport.decodeModelWarning(
        {
          'type': 'unsupported',
          'details': 'temperature is ignored.',
          'field': 'temperature',
        },
        path: r'$.warning',
      );

      expect(legacy.message, 'temperature is ignored.');
      expect(legacy.feature, 'temperature');
      expect(legacy.setting, isNull);
      expect(legacy.field, 'temperature');
    });

    test('round-trips shared tool call and result content', () {
      final encodedCall = SerializationJsonSupport.encodeToolCallContent(
        const ToolCallContent(
          toolCallId: 'call-1',
          toolName: 'lookup',
          input: {
            'city': 'London',
          },
          providerExecuted: true,
          isDynamic: true,
          title: 'Weather lookup',
        ),
      );

      expect(encodedCall, {
        'toolCallId': 'call-1',
        'toolName': 'lookup',
        'input': {
          'city': 'London',
        },
        'providerExecuted': true,
        'isDynamic': true,
        'title': 'Weather lookup',
      });
      final decodedCall = SerializationJsonSupport.decodeToolCallContent(
        {
          ...encodedCall,
          'dynamic': true,
          'isDynamic': null,
        },
        path: r'$.toolCall',
      );
      expect(decodedCall.toolCallId, 'call-1');
      expect(decodedCall.isDynamic, isTrue);
      expect(decodedCall.providerExecuted, isTrue);

      final encodedResult = SerializationJsonSupport.encodeToolResultContent(
        ToolResultContent(
          toolCallId: 'call-1',
          toolName: 'lookup',
          toolOutput: const ErrorTextToolOutput('not found'),
          preliminary: true,
          isDynamic: true,
        ),
      );

      expect(encodedResult['toolOutput'], {
        'type': 'error-text',
        'value': 'not found',
      });
      final decodedResult = SerializationJsonSupport.decodeToolResultContent(
        encodedResult,
        path: r'$.toolResult',
      );
      expect(decodedResult.toolCallId, 'call-1');
      expect(decodedResult.isError, isTrue);
      expect(decodedResult.output, 'not found');
      expect(decodedResult.preliminary, isTrue);
      expect(decodedResult.isDynamic, isTrue);

      final legacyResult = SerializationJsonSupport.decodeToolResultContent(
        {
          'toolCallId': 'call-2',
          'toolName': 'legacy',
          'output': 'bad input',
          'isError': true,
        },
        path: r'$.toolResult',
      );
      expect(legacyResult.toolOutput, isA<ErrorTextToolOutput>());
    });
  });
}
