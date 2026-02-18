import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:test/test.dart';

void main() {
  group('readProviderMetadata', () {
    test('returns null when providerMetadata is null', () {
      final value = readProviderMetadata<Map<String, dynamic>>(null, 'openai');
      expect(value, isNull);
    });

    test('prefers base provider id key over providerId', () {
      final meta = <String, dynamic>{
        'openai': {'id': 'base'},
        'openai.chat': {'id': 'alias'},
      };

      final value = readProviderMetadata<Map>(meta, 'openai.chat');
      expect(value, equals({'id': 'base'}));
    });

    test('falls back to providerId key when base is absent', () {
      final meta = <String, dynamic>{
        'openai.chat': {'id': 'alias'},
      };

      final value = readProviderMetadata<Map>(meta, 'openai.chat');
      expect(value, equals({'id': 'alias'}));
    });

    test('prefers base key for namespaced provider ids (xai.responses -> xai)',
        () {
      final meta = <String, dynamic>{
        'xai': {'id': 'base'},
        'xai.responses': {'id': 'alias'},
      };

      final value = readProviderMetadata<Map>(meta, 'xai.responses');
      expect(value, equals({'id': 'base'}));
    });

    test('falls back to namespaced provider id key when base is absent', () {
      final meta = <String, dynamic>{
        'xai.responses': {'id': 'alias'},
      };

      final value = readProviderMetadata<Map>(meta, 'xai.responses');
      expect(value, equals({'id': 'alias'}));
    });

    test('falls back to common capability aliases when direct keys are absent',
        () {
      final meta = <String, dynamic>{
        'openai.responses': {'id': 'responses'},
      };

      final value = readProviderMetadata<Map>(meta, 'openai.chat');
      expect(value, equals({'id': 'responses'}));
    });

    test('falls back to single-entry map when providerId is unknown', () {
      final meta = <String, dynamic>{
        'some-provider': {'id': 'only'},
      };

      final value = readProviderMetadata<Map>(meta, 'unknown');
      expect(value, equals({'id': 'only'}));
    });

    test('returns null when no match and map has multiple entries', () {
      final meta = <String, dynamic>{
        'a': {'id': 1},
        'b': {'id': 2},
      };

      final value = readProviderMetadata<Map>(meta, 'openai');
      expect(value, isNull);
    });
  });
}
