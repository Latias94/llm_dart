/// Image generation configuration builder for legacy compatibility providers.
class ImageConfig {
  final Map<String, dynamic> _config = {};

  /// Sets image size.
  ImageConfig size(String size) {
    _config['imageSize'] = size;
    return this;
  }

  /// Sets batch size for generation.
  ImageConfig batchSize(int size) {
    _config['batchSize'] = size;
    return this;
  }

  /// Sets seed for reproducible generation.
  ImageConfig seed(String seed) {
    _config['imageSeed'] = seed;
    return this;
  }

  /// Sets number of inference steps.
  ImageConfig numInferenceSteps(int steps) {
    _config['numInferenceSteps'] = steps;
    return this;
  }

  /// Sets guidance scale.
  ImageConfig guidanceScale(double scale) {
    _config['guidanceScale'] = scale;
    return this;
  }

  /// Enables prompt enhancement.
  ImageConfig promptEnhancement(bool enabled) {
    _config['promptEnhancement'] = enabled;
    return this;
  }

  /// Get the configuration map.
  Map<String, dynamic> build() => Map.from(_config);
}
