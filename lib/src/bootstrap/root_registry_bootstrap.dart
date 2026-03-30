import 'package:logging/logging.dart';

import '../../core/capability.dart';
import '../../core/registry.dart';
import '../../providers/factories/anthropic_factory.dart';
import '../../providers/factories/deepseek_factory.dart';
import '../../providers/factories/elevenlabs_factory.dart';
import '../../providers/factories/google_factory.dart';
import '../../providers/factories/groq_factory.dart';
import '../../providers/factories/ollama_factory.dart';
import '../../providers/factories/openai_compatible_factory.dart';
import '../../providers/factories/openai_factory.dart';
import '../../providers/factories/phind_factory.dart';
import '../../providers/factories/xai_factory.dart';

final Logger _logger = Logger('RootRegistryBootstrap');
bool _bootstrapConfigured = false;

/// Ensures the root package built-in provider registrar is configured.
void ensureRootRegistryBootstrap() {
  if (_bootstrapConfigured) {
    return;
  }

  LLMProviderRegistry.configureBuiltinRegistrar(_registerRootBuiltinProviders);
  _bootstrapConfigured = true;
}

void _registerRootBuiltinProviders() {
  _registerIfPresent(_createOpenAIFactory(), label: 'OpenAI');
  _registerIfPresent(_createAnthropicFactory(), label: 'Anthropic');
  _registerIfPresent(_createDeepSeekFactory(), label: 'DeepSeek');
  _registerIfPresent(_createOllamaFactory(), label: 'Ollama');
  _registerIfPresent(_createGoogleFactory(), label: 'Google');
  _registerIfPresent(_createXAIFactory(), label: 'xAI');
  _registerIfPresent(_createPhindFactory(), label: 'Phind');
  _registerIfPresent(_createGroqFactory(), label: 'Groq');
  _registerIfPresent(_createElevenLabsFactory(), label: 'ElevenLabs');
  _registerOpenAICompatibleProviders();
}

void _registerIfPresent(
  LLMProviderFactory? factory, {
  required String label,
}) {
  if (factory == null) {
    _logger.fine('Skipped unavailable $label provider factory.');
    return;
  }

  LLMProviderRegistry.registerOrReplace(factory);
}

LLMProviderFactory<ChatCapability>? _createOpenAIFactory() {
  try {
    return OpenAIProviderFactory();
  } catch (e) {
    _logger.warning('Failed to create OpenAI factory: $e');
    return null;
  }
}

LLMProviderFactory<ChatCapability>? _createAnthropicFactory() {
  try {
    return AnthropicProviderFactory();
  } catch (e) {
    _logger.warning('Failed to create Anthropic factory: $e');
    return null;
  }
}

LLMProviderFactory? _createDeepSeekFactory() {
  try {
    return DeepSeekProviderFactory();
  } catch (e) {
    _logger.warning('Failed to create DeepSeek factory: $e');
    return null;
  }
}

LLMProviderFactory<ChatCapability>? _createOllamaFactory() {
  try {
    return OllamaProviderFactory();
  } catch (e) {
    _logger.warning('Failed to create Ollama factory: $e');
    return null;
  }
}

LLMProviderFactory? _createGoogleFactory() {
  try {
    return GoogleProviderFactory();
  } catch (e) {
    _logger.warning('Failed to create Google factory: $e');
    return null;
  }
}

LLMProviderFactory? _createXAIFactory() {
  try {
    return XAIProviderFactory();
  } catch (e) {
    _logger.warning('Failed to create xAI factory: $e');
    return null;
  }
}

LLMProviderFactory? _createPhindFactory() {
  try {
    return PhindProviderFactory();
  } catch (e) {
    _logger.warning('Failed to create Phind factory: $e');
    return null;
  }
}

LLMProviderFactory? _createGroqFactory() {
  try {
    return GroqProviderFactory();
  } catch (e) {
    _logger.warning('Failed to create Groq factory: $e');
    return null;
  }
}

LLMProviderFactory<ChatCapability>? _createElevenLabsFactory() {
  try {
    return ElevenLabsProviderFactory();
  } catch (e) {
    _logger.warning('Failed to create ElevenLabs factory: $e');
    return null;
  }
}

void _registerOpenAICompatibleProviders() {
  try {
    OpenAICompatibleProviderRegistrar.registerAll();
    _logger.fine('Registered OpenAI-compatible providers.');
  } catch (e) {
    _logger.warning('Failed to register OpenAI-compatible providers: $e');
  }
}
