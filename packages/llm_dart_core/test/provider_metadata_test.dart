import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderMetadata', () {
    test('builds namespaced metadata and omits null values', () {
      final metadata = ProviderMetadata.forNamespace('google', {
        'thoughtSignature': 'sig_1',
        'debug': null,
      });

      expect(metadata, isNotNull);
      expect(metadata!.containsNamespace('google'), isTrue);
      expect(
        metadata.namespace('google'),
        {
          'thoughtSignature': 'sig_1',
        },
      );
    });

    test('deep merges namespace payloads without dropping sibling fields', () {
      const left = ProviderMetadata({
        'openai': {
          'itemId': 'msg_1',
          'approval': {
            'state': 'waiting',
          },
        },
      });
      const right = ProviderMetadata({
        'openai': {
          'approval': {
            'decision': 'approved',
          },
          'callPhase': 'completed',
        },
        'google': {
          'thoughtSignature': 'sig_2',
        },
      });

      final merged = ProviderMetadata.mergeNullable(left, right);

      expect(
        merged,
        const ProviderMetadata({
          'openai': {
            'itemId': 'msg_1',
            'approval': {
              'state': 'waiting',
              'decision': 'approved',
            },
            'callPhase': 'completed',
          },
          'google': {
            'thoughtSignature': 'sig_2',
          },
        }),
      );
    });

    test('rejects flat top-level values on serialization', () {
      const metadata = ProviderMetadata({
        'provider': 'openai',
      });

      expect(metadata.toJsonMap, throwsFormatException);
    });

    test('rejects invalid namespace keys on serialization', () {
      const metadata = ProviderMetadata({
        'OpenAI': {
          'itemId': 'msg_1',
        },
      });

      expect(metadata.toJsonMap, throwsFormatException);
    });
  });
}
