import 'package:llm_dart_provider_utils/utils/request_metadata_options.dart';
import 'package:test/test.dart';

void main() {
  group('emitRequestMetadataEnabled', () {
    test('reads emitRequestMetadata', () {
      const providerOptions = <String, Map<String, dynamic>>{
        'foo': {'emitRequestMetadata': true},
      };
      expect(emitRequestMetadataEnabled(providerOptions, 'foo'), isTrue);
    });

    test('supports fallbackProviderId', () {
      const providerOptions = <String, Map<String, dynamic>>{
        'fallback': {'emitRequestMetadata': true},
      };
      expect(
        emitRequestMetadataEnabled(
          providerOptions,
          'foo',
          fallbackProviderId: 'fallback',
        ),
        isTrue,
      );
    });
  });
}
