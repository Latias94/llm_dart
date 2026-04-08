final class ModelResponseMetadata {
  final DateTime timestamp;
  final String modelId;
  final Map<String, String> headers;

  const ModelResponseMetadata({
    required this.timestamp,
    required this.modelId,
    this.headers = const {},
  });
}
