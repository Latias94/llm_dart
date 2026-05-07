part of 'provider_compat.dart';

mixin OpenAIProviderCapabilitiesMixin implements ProviderCapabilities {
  OpenAIProviderSupport get _support;

  @override
  Set<LLMCapability> get supportedCapabilities =>
      _support.supportedCapabilities;

  @override
  bool supports(LLMCapability capability) {
    return _support.supports(capability);
  }
}
