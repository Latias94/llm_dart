import 'package:llm_dart_core/llm_dart_core.dart';
import 'capability_utils.dart';

/// Enterprise-grade provider registry for managing multiple providers
/// and their capabilities. Useful for applications that work with
/// multiple LLM providers or need dynamic provider selection.
class ProviderRegistry {
  final Map<String, dynamic> _providers = {};
  final Map<String, Set<LLMCapability>> _capabilities = {};
  final Map<String, Map<String, dynamic>> _metadata = {};

  /// Register a provider with optional metadata
  void registerProvider(
    String id,
    dynamic provider, {
    Map<String, dynamic>? metadata,
  }) {
    _providers[id] = provider;
    _capabilities[id] = CapabilityUtils.getCapabilities(provider);
    _metadata[id] = metadata ?? {};
  }

  /// Unregister a provider
  bool unregisterProvider(String id) {
    final existed = _providers.containsKey(id);
    _providers.remove(id);
    _capabilities.remove(id);
    _metadata.remove(id);
    return existed;
  }

  /// Get a registered provider by ID
  T? getProvider<T>(String id) {
    final provider = _providers[id];
    return provider is T ? provider : null;
  }

  /// Check if a provider supports a capability
  bool hasCapability(String providerId, LLMCapability capability) {
    return _capabilities[providerId]?.contains(capability) ?? false;
  }

  /// Get all capabilities for a provider
  Set<LLMCapability> getCapabilities(String providerId) {
    return _capabilities[providerId] ?? {};
  }

  /// Find providers that support a specific capability
  List<String> findProvidersWithCapability(LLMCapability capability) {
    return _capabilities.entries
        .where((entry) => entry.value.contains(capability))
        .map((entry) => entry.key)
        .toList();
  }

  /// Find providers that support all required capabilities
  List<String> findProvidersWithAllCapabilities(Set<LLMCapability> required) {
    return _capabilities.entries
        .where((entry) => required.every((cap) => entry.value.contains(cap)))
        .map((entry) => entry.key)
        .toList();
  }

  /// Find the best provider for a set of requirements
  /// Returns the provider with the most matching capabilities
  String? findBestProvider(
    Set<LLMCapability> required, {
    Set<LLMCapability>? preferred,
  }) {
    String? bestProvider;
    int bestScore = -1;

    for (final entry in _capabilities.entries) {
      final providerId = entry.key;
      final capabilities = entry.value;

      // Must have all required capabilities
      if (!required.every((cap) => capabilities.contains(cap))) {
        continue;
      }

      // Calculate score based on preferred capabilities
      int score = required.length; // Base score for meeting requirements

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

  /// Execute action with the best available provider
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

  /// Execute action with capability-specific provider
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

  /// Get capability matrix for all providers
  Map<String, Set<LLMCapability>> getCapabilityMatrix() {
    return Map.from(_capabilities);
  }

  /// Get detailed provider information
  RegistryProviderInfo? getProviderInfo(String id) {
    final provider = _providers[id];
    if (provider == null) return null;

    return RegistryProviderInfo(
      id: id,
      provider: provider,
      capabilities: _capabilities[id] ?? {},
      metadata: _metadata[id] ?? {},
    );
  }

  /// Get all registered provider IDs
  List<String> getProviderIds() {
    return _providers.keys.toList();
  }

  /// Get providers count
  int get providerCount => _providers.length;

  /// Check if registry is empty
  bool get isEmpty => _providers.isEmpty;

  /// Clear all providers
  void clear() {
    _providers.clear();
    _capabilities.clear();
    _metadata.clear();
  }

  /// Get registry statistics
  RegistryStats getStats() {
    final allCapabilities = _capabilities.values.expand((caps) => caps).toSet();

    final capabilityCount = <LLMCapability, int>{};
    for (final capability in allCapabilities) {
      capabilityCount[capability] = _capabilities.values
          .where((caps) => caps.contains(capability))
          .length;
    }

    return RegistryStats(
      totalProviders: _providers.length,
      totalCapabilities: allCapabilities.length,
      capabilityDistribution: capabilityCount,
      averageCapabilitiesPerProvider: _providers.isEmpty
          ? 0.0
          : _capabilities.values
                  .map((caps) => caps.length)
                  .reduce((a, b) => a + b) /
              _providers.length,
    );
  }

  /// Validate all providers against requirements
  Map<String, CapabilityValidationReport> validateAllProviders(
    Set<LLMCapability> required,
  ) {
    final reports = <String, CapabilityValidationReport>{};

    for (final providerId in _providers.keys) {
      final provider = _providers[providerId]!;
      reports[providerId] =
          CapabilityUtils.validateProvider(provider, required);
    }

    return reports;
  }
}

/// Information about a registered provider in the registry
class RegistryProviderInfo {
  final String id;
  final dynamic provider;
  final Set<LLMCapability> capabilities;
  final Map<String, dynamic> metadata;

  const RegistryProviderInfo({
    required this.id,
    required this.provider,
    required this.capabilities,
    required this.metadata,
  });

  @override
  String toString() {
    return 'RegistryProviderInfo(id: $id, capabilities: ${capabilities.length}, metadata: ${metadata.keys.length} keys)';
  }
}

/// Registry statistics
class RegistryStats {
  final int totalProviders;
  final int totalCapabilities;
  final Map<LLMCapability, int> capabilityDistribution;
  final double averageCapabilitiesPerProvider;

  const RegistryStats({
    required this.totalProviders,
    required this.totalCapabilities,
    required this.capabilityDistribution,
    required this.averageCapabilitiesPerProvider,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Registry Statistics:');
    buffer.writeln('  Total Providers: $totalProviders');
    buffer.writeln('  Total Capabilities: $totalCapabilities');
    buffer.writeln(
        '  Average Capabilities per Provider: ${averageCapabilitiesPerProvider.toStringAsFixed(1)}');

    if (capabilityDistribution.isNotEmpty) {
      buffer.writeln('  Capability Distribution:');
      for (final entry in capabilityDistribution.entries) {
        final percentage =
            (entry.value / totalProviders * 100).toStringAsFixed(1);
        buffer.writeln(
            '    ${entry.key.name}: ${entry.value} providers ($percentage%)');
      }
    }

    return buffer.toString();
  }
}

/// Singleton instance for global provider registry
final globalProviderRegistry = ProviderRegistry();
