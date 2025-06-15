import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('ImageConfig', () {
    late ImageConfig config;

    setUp(() {
      config = ImageConfig();
    });

    test('creates empty configuration by default', () {
      final result = config.build();
      expect(result, isEmpty);
    });

    test('size() sets image size', () {
      config.size('1024x1024');
      final result = config.build();
      expect(result['imageSize'], equals('1024x1024'));
    });

    test('batchSize() sets batch size', () {
      config.batchSize(4);
      final result = config.build();
      expect(result['batchSize'], equals(4));
    });

    test('seed() sets image seed', () {
      config.seed('12345');
      final result = config.build();
      expect(result['imageSeed'], equals('12345'));
    });

    test('numInferenceSteps() sets number of inference steps', () {
      config.numInferenceSteps(50);
      final result = config.build();
      expect(result['numInferenceSteps'], equals(50));
    });

    test('guidanceScale() sets guidance scale', () {
      config.guidanceScale(7.5);
      final result = config.build();
      expect(result['guidanceScale'], equals(7.5));
    });

    test('promptEnhancement() enables prompt enhancement', () {
      config.promptEnhancement(true);
      final result = config.build();
      expect(result['promptEnhancement'], isTrue);
    });

    test('promptEnhancement() disables prompt enhancement', () {
      config.promptEnhancement(false);
      final result = config.build();
      expect(result['promptEnhancement'], isFalse);
    });

    test('method chaining works correctly', () {
      final result = config
          .size('512x512')
          .batchSize(2)
          .seed('67890')
          .numInferenceSteps(30)
          .guidanceScale(8.0)
          .promptEnhancement(true)
          .build();

      expect(result['imageSize'], equals('512x512'));
      expect(result['batchSize'], equals(2));
      expect(result['imageSeed'], equals('67890'));
      expect(result['numInferenceSteps'], equals(30));
      expect(result['guidanceScale'], equals(8.0));
      expect(result['promptEnhancement'], isTrue);
    });

    test('build() returns a copy of the configuration', () {
      config.size('1024x1024');
      final result1 = config.build();
      final result2 = config.build();

      expect(identical(result1, result2), isFalse);
      expect(result1, equals(result2));
    });

    test('configuration can be modified after build', () {
      config.size('512x512');
      final result1 = config.build();

      config.batchSize(3);
      final result2 = config.build();

      expect(result1.length, equals(1));
      expect(result2.length, equals(2));
      expect(result1['imageSize'], equals('512x512'));
      expect(result2['imageSize'], equals('512x512'));
      expect(result2['batchSize'], equals(3));
    });

    test('handles different image sizes', () {
      final sizes = ['256x256', '512x512', '1024x1024', '1792x1024'];

      for (final size in sizes) {
        config = ImageConfig().size(size);
        final result = config.build();
        expect(result['imageSize'], equals(size));
      }
    });

    test('handles different guidance scale values', () {
      final scales = [1.0, 5.0, 7.5, 10.0, 15.0];

      for (final scale in scales) {
        config = ImageConfig().guidanceScale(scale);
        final result = config.build();
        expect(result['guidanceScale'], equals(scale));
      }
    });

    test('handles different inference step values', () {
      final steps = [10, 20, 30, 50, 100];

      for (final step in steps) {
        config = ImageConfig().numInferenceSteps(step);
        final result = config.build();
        expect(result['numInferenceSteps'], equals(step));
      }
    });
  });
}
