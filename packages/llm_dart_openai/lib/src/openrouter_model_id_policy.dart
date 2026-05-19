String resolveOpenRouterOnlineModelId(String modelId) {
  if (modelId.endsWith(':online')) {
    return modelId;
  }

  if (modelId.contains('deepseek-r1')) {
    throw UnsupportedError(
      'OpenRouter online-model shaping is not supported for DeepSeek R1 traffic.',
    );
  }

  return '$modelId:online';
}
