part of 'models.dart';

final class _OpenAIModelsPricingSupport {
  const _OpenAIModelsPricingSupport();

  Map<String, dynamic> getModelPricing(String modelId) {
    const pricingMap = {
      'gpt-4': {'input': 0.03, 'output': 0.06, 'unit': 'per 1K tokens'},
      'gpt-4-turbo': {'input': 0.01, 'output': 0.03, 'unit': 'per 1K tokens'},
      'gpt-3.5-turbo': {
        'input': 0.0015,
        'output': 0.002,
        'unit': 'per 1K tokens',
      },
      'text-embedding-3-large': {'input': 0.00013, 'unit': 'per 1K tokens'},
      'text-embedding-3-small': {'input': 0.00002, 'unit': 'per 1K tokens'},
      'dall-e-3': {'price': 0.04, 'unit': 'per image (1024×1024)'},
      'dall-e-2': {'price': 0.02, 'unit': 'per image (1024×1024)'},
      'whisper-1': {'price': 0.006, 'unit': 'per minute'},
      'tts-1': {'price': 0.015, 'unit': 'per 1K characters'},
    };

    return pricingMap[modelId] ?? {'price': 'Unknown', 'unit': 'Unknown'};
  }
}
