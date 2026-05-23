part of 'provider_options.dart';

/// Explicitly carries both typed provider options and a JSON options bag.
///
/// Typed options remain the preferred Dart Interface. The bag is the transport
/// and cross-process seam. Provider Implementations can merge both; generic
/// typed resolvers unwrap [typedOptions] and ignore the bag.
final class ProviderInvocationOptionsBundle
    implements ProviderInvocationOptions {
  final ProviderInvocationOptions? typedOptions;
  final ProviderOptionsBag bag;

  ProviderInvocationOptionsBundle({
    this.typedOptions,
    ProviderOptionsBag? bag,
  }) : bag = bag ?? ProviderOptionsBag.empty;
}

/// Convenience constructor for a typed/bag invocation options bundle.
ProviderInvocationOptions? providerInvocationOptions({
  ProviderInvocationOptions? typedOptions,
  ProviderOptionsBag? bag,
}) {
  final hasTyped = typedOptions != null;
  final hasBag = bag != null && bag.isNotEmpty;

  if (!hasTyped && !hasBag) {
    return null;
  }

  if (!hasTyped) {
    return bag;
  }

  if (!hasBag) {
    return typedOptions;
  }

  return ProviderInvocationOptionsBundle(
    typedOptions: typedOptions,
    bag: bag,
  );
}

/// Returns the JSON provider options bag carried by invocation options.
ProviderOptionsBag? providerOptionsBagFromInvocationOptions(
  ProviderInvocationOptions? options,
) {
  return switch (options) {
    null => null,
    ProviderOptionsBag() => options,
    ProviderInvocationOptionsBundle(:final typedOptions, :final bag) =>
      ProviderOptionsBag.mergeNullable(
        bag.isEmpty ? null : bag,
        typedOptions is ProviderInvocationOptionsBagProjection
            ? typedOptions.toProviderOptionsBag()
            : null,
      ),
    ProviderInvocationOptionsBagProjection() => options.toProviderOptionsBag(),
    _ => null,
  };
}

/// Returns the typed provider options carried by invocation options.
ProviderInvocationOptions? typedProviderOptionsFromInvocationOptions(
  ProviderInvocationOptions? options,
) {
  return switch (options) {
    null => null,
    ProviderOptionsBag() => null,
    ProviderInvocationOptionsBundle(:final typedOptions) => typedOptions,
    _ => options,
  };
}

/// Returns one provider namespace from an invocation options bag.
JsonMap? providerOptionsNamespaceFromInvocationOptions(
  ProviderInvocationOptions? options,
  String provider,
) {
  return providerOptionsBagFromInvocationOptions(options)?.namespace(provider);
}

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

/// Typed provider options that can project themselves into JSON bag form.
///
/// This keeps typed options as the primary Dart Interface while giving
/// cross-process seams a provider-owned JSON representation when a concrete
/// options object knows how to preserve itself.
abstract interface class ProviderInvocationOptionsBagProjection
    implements ProviderInvocationOptions {
  const ProviderInvocationOptionsBagProjection();

  ProviderOptionsBag toProviderOptionsBag();
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
  final typedOptions = typedProviderOptionsFromInvocationOptions(options);
  if (typedOptions == null) {
    return null;
  }

  if (typedOptions is T) {
    return typedOptions;
  }

  throw ArgumentError.value(
    typedOptions,
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
