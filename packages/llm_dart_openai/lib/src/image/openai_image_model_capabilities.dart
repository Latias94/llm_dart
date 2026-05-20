int resolveOpenAIImageMaxImagesPerCall(String modelId) {
  return switch (modelId) {
    'dall-e-2' => 10,
    'dall-e-3' => 1,
    'chatgpt-image-latest' => 10,
    'gpt-image-1' => 10,
    'gpt-image-1-mini' => 10,
    'gpt-image-1.5' => 10,
    'gpt-image-2' => 10,
    _ => 1,
  };
}

bool shouldIncludeOpenAIImageResponseFormat(String modelId) {
  return !hasDefaultOpenAIImageResponseFormat(modelId);
}

bool hasDefaultOpenAIImageResponseFormat(String modelId) {
  const defaultResponseFormatPrefixes = [
    'chatgpt-image-',
    'gpt-image-1-mini',
    'gpt-image-1.5',
    'gpt-image-1',
    'gpt-image-2',
  ];

  return defaultResponseFormatPrefixes.any(modelId.startsWith);
}
