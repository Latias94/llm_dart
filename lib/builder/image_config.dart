import 'package:llm_dart_core/llm_dart_core.dart';

/// Image generation configuration builder.
///
/// 注意：这是一个遗留的配置构建器，仅用于与旧代码和测试兼容。
/// 新代码请优先使用 `LLMBuilder` 上的图像相关方法：
/// `imageSize`, `batchSize`, `imageSeed`, `numInferenceSteps` 等，
/// 这些方法会直接通过 [LLMConfigKeys] 写入统一的扩展配置。
@Deprecated(
  'ImageConfig is legacy. Use LLMBuilder image helpers like '
  'imageSize(), batchSize(), imageSeed(), numInferenceSteps(), '
  'guidanceScale(), and promptEnhancement() instead.',
)
class ImageConfig {
  final Map<String, dynamic> _config = {};

  /// Sets image size
  ImageConfig size(String size) {
    _config[LLMConfigKeys.imageSize] = size;
    return this;
  }

  /// Sets batch size for generation
  ImageConfig batchSize(int size) {
    _config[LLMConfigKeys.batchSize] = size;
    return this;
  }

  /// Sets seed for reproducible generation
  ImageConfig seed(String seed) {
    _config[LLMConfigKeys.imageSeed] = seed;
    return this;
  }

  /// Sets number of inference steps
  ImageConfig numInferenceSteps(int steps) {
    _config[LLMConfigKeys.numInferenceSteps] = steps;
    return this;
  }

  /// Sets guidance scale
  ImageConfig guidanceScale(double scale) {
    _config[LLMConfigKeys.guidanceScale] = scale;
    return this;
  }

  /// Enables prompt enhancement
  ImageConfig promptEnhancement(bool enabled) {
    _config[LLMConfigKeys.promptEnhancement] = enabled;
    return this;
  }

  /// Get the configuration map
  Map<String, dynamic> build() => Map.from(_config);
}
