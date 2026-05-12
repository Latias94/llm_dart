/// Provider-owned model construction settings.
///
/// These options select or configure a concrete provider model instance. They
/// are not response metadata.
abstract interface class ProviderModelOptions {
  const ProviderModelOptions();
}

/// Provider-owned request customization settings.
///
/// Implementations use these typed options for input-side provider features
/// that do not belong in shared `GenerateTextOptions`. Response observations
/// and replay details belong in `ProviderMetadata` instead.
abstract interface class ProviderInvocationOptions {
  const ProviderInvocationOptions();
}

/// Resolves provider-owned model settings to the expected concrete type.
T resolveProviderModelOptions<T extends ProviderModelOptions>(
  ProviderModelOptions options, {
  required String parameterName,
  required String expectedTypeName,
  String? usageContext,
}) {
  if (options is T) {
    return options;
  }

  throw ArgumentError.value(
    options,
    parameterName,
    _expectedProviderOptionMessage(
      expectedTypeName: expectedTypeName,
      usageContext: usageContext,
    ),
  );
}

/// Resolves nullable provider-owned invocation options to the expected type.
T? resolveProviderInvocationOptions<T extends ProviderInvocationOptions>(
  ProviderInvocationOptions? options, {
  required String parameterName,
  required String expectedTypeName,
  String? usageContext,
}) {
  if (options == null) {
    return null;
  }

  if (options is T) {
    return options;
  }

  throw ArgumentError.value(
    options,
    parameterName,
    _expectedProviderOptionMessage(
      expectedTypeName: expectedTypeName,
      usageContext: usageContext,
    ),
  );
}

String _expectedProviderOptionMessage({
  required String expectedTypeName,
  required String? usageContext,
}) {
  if (usageContext == null || usageContext.isEmpty) {
    return 'Expected $expectedTypeName.';
  }

  return 'Expected $expectedTypeName for $usageContext.';
}
