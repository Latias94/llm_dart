import 'dart:developer' as developer;

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
    developer.log(
      'Skipped unavailable $label provider factory.',
      name: 'RootRegistryBootstrap',
      level: 500,
    );
    return;
  }

  LLMProviderRegistry.registerOrReplace(factory);
}

LLMProviderFactory<ChatCapability>? _createOpenAIFactory() {
  try {
    return OpenAIProviderFactory();
  } catch (error, stackTrace) {
    developer.log(
      'Failed to create OpenAI factory.',
      name: 'RootRegistryBootstrap',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

LLMProviderFactory<ChatCapability>? _createAnthropicFactory() {
  try {
    return AnthropicProviderFactory();
  } catch (error, stackTrace) {
    developer.log(
      'Failed to create Anthropic factory.',
      name: 'RootRegistryBootstrap',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

LLMProviderFactory? _createDeepSeekFactory() {
  try {
    return DeepSeekProviderFactory();
  } catch (error, stackTrace) {
    developer.log(
      'Failed to create DeepSeek factory.',
      name: 'RootRegistryBootstrap',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

LLMProviderFactory<ChatCapability>? _createOllamaFactory() {
  try {
    return OllamaProviderFactory();
  } catch (error, stackTrace) {
    developer.log(
      'Failed to create Ollama factory.',
      name: 'RootRegistryBootstrap',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

LLMProviderFactory? _createGoogleFactory() {
  try {
    return GoogleProviderFactory();
  } catch (error, stackTrace) {
    developer.log(
      'Failed to create Google factory.',
      name: 'RootRegistryBootstrap',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

LLMProviderFactory? _createXAIFactory() {
  try {
    return XAIProviderFactory();
  } catch (error, stackTrace) {
    developer.log(
      'Failed to create xAI factory.',
      name: 'RootRegistryBootstrap',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

LLMProviderFactory? _createPhindFactory() {
  try {
    return PhindProviderFactory();
  } catch (error, stackTrace) {
    developer.log(
      'Failed to create Phind factory.',
      name: 'RootRegistryBootstrap',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

LLMProviderFactory? _createGroqFactory() {
  try {
    return GroqProviderFactory();
  } catch (error, stackTrace) {
    developer.log(
      'Failed to create Groq factory.',
      name: 'RootRegistryBootstrap',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

LLMProviderFactory<ChatCapability>? _createElevenLabsFactory() {
  try {
    return ElevenLabsProviderFactory();
  } catch (error, stackTrace) {
    developer.log(
      'Failed to create ElevenLabs factory.',
      name: 'RootRegistryBootstrap',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

void _registerOpenAICompatibleProviders() {
  try {
    OpenAICompatibleProviderRegistrar.registerAll();
    developer.log(
      'Registered OpenAI-compatible providers.',
      name: 'RootRegistryBootstrap',
      level: 500,
    );
  } catch (error, stackTrace) {
    developer.log(
      'Failed to register OpenAI-compatible providers.',
      name: 'RootRegistryBootstrap',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
