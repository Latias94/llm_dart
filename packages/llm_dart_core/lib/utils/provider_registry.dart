import '../core/capability.dart';
import 'capability_utils.dart';

/// Provider registry for managing multiple providers and their capabilities.
///
/// Useful for applications that work with multiple providers or need dynamic
/// provider selection at runtime.
class ProviderRegistry {
  final Map<String, dynamic> _providers = {};
  final Map<String, Set<LLMCapability>> _capabilities = {};
  final Map<String, Map<String, dynamic>> _metadata = {};

  void registerProvider(
    String id,
    dynamic provider, {
    Map<String, dynamic>? metadata,
  }) {
    _providers[id] = provider;
    _capabilities[id] = CapabilityUtils.getCapabilities(provider);
    _metadata[id] = metadata ?? {};
  }

  bool unregisterProvider(String id) {
    final existed = _providers.containsKey(id);
    _providers.remove(id);
    _capabilities.remove(id);
    _metadata.remove(id);
    return existed;
  }

  T? getProvider<T>(String id) {
    final provider = _providers[id];
    return provider is T ? provider : null;
  }

  bool hasCapability(String providerId, LLMCapability capability) {
    return _capabilities[providerId]?.contains(capability) ?? false;
  }

  Set<LLMCapability> getCapabilities(String providerId) {
    return _capabilities[providerId] ?? {};
  }

  List<String> findProvidersWithCapability(LLMCapability capability) {
    return _capabilities.entries
        .where((entry) => entry.value.contains(capability))
        .map((entry) => entry.key)
        .toList();
  }

  List<String> findProvidersWithAllCapabilities(Set<LLMCapability> required) {
    return _capabilities.entries
        .where((entry) => required.every((cap) => entry.value.contains(cap)))
        .map((entry) => entry.key)
        .toList();
  }

  String? findBestProvider(
    Set<LLMCapability> required, {
    Set<LLMCapability>? preferred,
  }) {
    String? bestProvider;
    var bestScore = -1;

    for (final entry in _capabilities.entries) {
      final providerId = entry.key;
      final capabilities = entry.value;

      if (!required.every((cap) => capabilities.contains(cap))) {
        continue;
      }

      var score = required.length;

      if (preferred != null) {
        score += preferred.where((cap) => capabilities.contains(cap)).length;
      }

      if (score > bestScore) {
        bestScore = score;
        bestProvider = providerId;
      }
    }

    return bestProvider;
  }

  Future<R?> withBestProvider<R>(
    Set<LLMCapability> required,
    Future<R> Function(String providerId, dynamic provider) action, {
    Set<LLMCapability>? preferred,
  }) async {
    final providerId = findBestProvider(required, preferred: preferred);
    if (providerId == null) return null;

    final provider = _providers[providerId];
    if (provider == null) return null;

    return await action(providerId, provider);
  }

  Future<R?> withCapabilityProvider<T, R>(
    LLMCapability capability,
    Future<R> Function(T provider) action,
  ) async {
    final providerIds = findProvidersWithCapability(capability);

    for (final providerId in providerIds) {
      final provider = _providers[providerId];
      if (provider is T) {
        return await action(provider);
      }
    }

    return null;
  }

  Map<String, dynamic> getMetadata(String providerId) {
    return _metadata[providerId] ?? {};
  }

  Map<String, dynamic> get providers => Map<String, dynamic>.from(_providers);

  Map<String, Set<LLMCapability>> get capabilities =>
      Map<String, Set<LLMCapability>>.from(_capabilities);
}

final globalProviderRegistry = ProviderRegistry();
