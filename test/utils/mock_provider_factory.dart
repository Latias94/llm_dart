import 'package:llm_dart/llm_dart.dart';

/// Generic [LLMProviderFactory] implementation for tests.
///
/// This factory allows tests to easily register a provider in the
/// [LLMProviderRegistry] without introducing provider-specific
/// factories. Callers supply a function that creates the concrete
/// [ChatCapability] instance for a given [LLMConfig].
class MockProviderFactory<T extends ChatCapability>
    extends LLMProviderFactory<T> {
  @override
  final String providerId;

  @override
  final Set<LLMCapability> supportedCapabilities;

  final T Function(LLMConfig config) _create;
  final bool Function(LLMConfig config)? _validate;

  MockProviderFactory({
    required this.providerId,
    required this.supportedCapabilities,
    required T Function(LLMConfig config) create,
    bool Function(LLMConfig config)? validate,
  })  : _create = create,
        _validate = validate;

  @override
  T create(LLMConfig config) => _create(config);

  @override
  bool validateConfig(LLMConfig config) => _validate?.call(config) ?? true;

  @override
  LLMConfig getDefaultConfig() => LLMConfig(
        baseUrl: '',
        model: '',
      );
}
