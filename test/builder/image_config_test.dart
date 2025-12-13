import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LLMBuilder image extensions', () {
    test('imageSize() sets LLMConfigKeys.imageSize', () {
      final builder = LLMBuilder().imageSize('1024x1024');
      expect(
        builder.currentConfig.getExtension<String>(LLMConfigKeys.imageSize),
        equals('1024x1024'),
      );
    });

    test('batchSize() sets LLMConfigKeys.batchSize', () {
      final builder = LLMBuilder().batchSize(4);
      expect(
        builder.currentConfig.getExtension<int>(LLMConfigKeys.batchSize),
        equals(4),
      );
    });

    test('imageSeed() sets LLMConfigKeys.imageSeed', () {
      final builder = LLMBuilder().imageSeed('12345');
      expect(
        builder.currentConfig.getExtension<String>(LLMConfigKeys.imageSeed),
        equals('12345'),
      );
    });

    test('numInferenceSteps() sets LLMConfigKeys.numInferenceSteps', () {
      final builder = LLMBuilder().numInferenceSteps(50);
      expect(
        builder.currentConfig
            .getExtension<int>(LLMConfigKeys.numInferenceSteps),
        equals(50),
      );
    });

    test('guidanceScale() sets LLMConfigKeys.guidanceScale', () {
      final builder = LLMBuilder().guidanceScale(7.5);
      expect(
        builder.currentConfig.getExtension<double>(LLMConfigKeys.guidanceScale),
        equals(7.5),
      );
    });

    test('promptEnhancement() sets LLMConfigKeys.promptEnhancement', () {
      final builder = LLMBuilder().promptEnhancement(true);
      expect(
        builder.currentConfig
            .getExtension<bool>(LLMConfigKeys.promptEnhancement),
        isTrue,
      );
    });

    test('method chaining sets multiple keys', () {
      final builder = LLMBuilder()
          .imageSize('512x512')
          .batchSize(2)
          .imageSeed('67890')
          .numInferenceSteps(30)
          .guidanceScale(8.0)
          .promptEnhancement(true);

      final config = builder.currentConfig;
      expect(config.getExtension<String>(LLMConfigKeys.imageSize), '512x512');
      expect(config.getExtension<int>(LLMConfigKeys.batchSize), 2);
      expect(config.getExtension<String>(LLMConfigKeys.imageSeed), '67890');
      expect(config.getExtension<int>(LLMConfigKeys.numInferenceSteps), 30);
      expect(config.getExtension<double>(LLMConfigKeys.guidanceScale), 8.0);
      expect(config.getExtension<bool>(LLMConfigKeys.promptEnhancement), isTrue);
    });
  });
}

