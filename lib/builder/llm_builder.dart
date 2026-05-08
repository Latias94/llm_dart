export '../src/compatibility/builders/llm_builder_provider_capability_extensions.dart'
    show LLMBuilderProviderCapabilityExtensions;
export '../src/compatibility/builders/llm_builder_provider_extensions.dart'
    show LLMBuilderProviderExtensions;

import '../core/capability.dart';
import '../core/config.dart';
import '../core/llm_error.dart';
import '../core/registry.dart';
import '../models/chat_models.dart';
import '../models/tool_models.dart';
import '../src/bootstrap/root_registry_bootstrap.dart';
import '../src/compatibility/compatibility_resolver.dart';
import '../src/compatibility/config/legacy_provider_options.dart';
import 'http_config.dart';

part 'llm_builder_builds.dart';
part 'llm_builder_common_config.dart';
part 'llm_builder_internal.dart';
part 'llm_builder_legacy_provider_options.dart';
part 'llm_builder_provider_selection.dart';

/// Builder for configuring and instantiating LLM providers
///
/// Provides a fluent interface for setting various configuration
/// options like model selection, API keys, generation parameters, and
/// compatibility-facing provider selection.
class LLMBuilder {
  /// Selected provider ID (replaces backend enum)
  String? _providerId;

  /// Unified configuration being built
  LLMConfig _config = LLMConfig(
    baseUrl: '',
    model: '',
  );

  /// Creates a new empty builder instance with default values
  LLMBuilder() {
    ensureRootRegistryBootstrap();
  }
}
