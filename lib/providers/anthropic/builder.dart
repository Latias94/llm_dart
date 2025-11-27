import '../../builder/llm_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'mcp_models.dart';

/// Anthropic-specific LLM builder with provider-specific configuration methods
///
/// This builder provides a layered configuration approach where Anthropic-specific
/// parameters are handled separately from the generic LLMBuilder, keeping the
/// main builder clean and focused.
///
/// Use this for Anthropic-specific parameters only. For common parameters like
/// apiKey, model, temperature, etc., continue using the base LLMBuilder methods.
class AnthropicBuilder {
  final LLMBuilder _baseBuilder;

  AnthropicBuilder(this._baseBuilder);

  // ========== Anthropic-specific configuration methods ==========

  /// Sets metadata for the request
  ///
  /// An object describing metadata about the request. This can be used
  /// for tracking, analytics, or other purposes. The metadata will be
  /// included in the request to Anthropic's API.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .anthropic((anthropic) => anthropic
  ///         .metadata({
  ///           'user_id': 'user123',
  ///           'session_id': 'session456',
  ///           'application': 'my_app',
  ///         }))
  ///     .apiKey(apiKey)
  ///     .build();
  /// ```
  AnthropicBuilder metadata(Map<String, dynamic> data) {
    _baseBuilder.extension(LLMConfigKeys.metadata, data);
    return this;
  }

  /// Sets the container ID for workbench usage
  ///
  /// When using Anthropic Workbench or containerized environments,
  /// this parameter specifies the container identifier for the request.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .anthropic((anthropic) => anthropic
  ///         .container('workbench-container-123'))
  ///     .apiKey(apiKey)
  ///     .build();
  /// ```
  AnthropicBuilder container(String containerId) {
    _baseBuilder.extension(LLMConfigKeys.container, containerId);
    return this;
  }

  /// Sets MCP (Model Context Protocol) servers
  ///
  /// Configures MCP servers that provide additional context and capabilities
  /// to the model. MCP servers can provide tools, resources, and other
  /// contextual information to enhance the model's capabilities.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .anthropic((anthropic) => anthropic
  ///         .mcpServers([
  ///           AnthropicMCPServer.url(
  ///             name: 'file_server',
  ///             url: 'https://example.com/mcp',
  ///           ),
  ///           AnthropicMCPServer.url(
  ///             name: 'database_server',
  ///             url: 'https://example.com/mcp2',
  ///           ),
  ///         ]))
  ///     .apiKey(apiKey)
  ///     .build();
  /// ```
  AnthropicBuilder mcpServers(List<AnthropicMCPServer> servers) {
    _baseBuilder.extension(LLMConfigKeys.mcpServers, servers);
    return this;
  }

  // ========== Convenience methods for common configurations ==========

  /// Configure for development with tracking metadata
  ///
  /// Sets up metadata for development tracking including environment
  /// and version information.
  AnthropicBuilder forDevelopment({
    String? userId,
    String? sessionId,
    String? version,
  }) {
    final metadata = <String, dynamic>{
      'environment': 'development',
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (userId != null) metadata['user_id'] = userId;
    if (sessionId != null) metadata['session_id'] = sessionId;
    if (version != null) metadata['version'] = version;

    return this.metadata(metadata);
  }

  /// Configure for production with comprehensive tracking
  ///
  /// Sets up metadata for production tracking with detailed information
  /// for analytics and monitoring.
  AnthropicBuilder forProduction({
    required String userId,
    required String sessionId,
    required String applicationName,
    String? version,
    Map<String, dynamic>? additionalMetadata,
  }) {
    final metadata = <String, dynamic>{
      'environment': 'production',
      'user_id': userId,
      'session_id': sessionId,
      'application': applicationName,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (version != null) metadata['version'] = version;
    if (additionalMetadata != null) metadata.addAll(additionalMetadata);

    return this.metadata(metadata);
  }

  /// Configure for workbench usage
  ///
  /// Sets up configuration for use with Anthropic Workbench,
  /// including container and metadata settings.
  AnthropicBuilder forWorkbench({
    required String containerId,
    String? projectName,
    String? experimentId,
  }) {
    final metadata = <String, dynamic>{
      'environment': 'workbench',
      'container_id': containerId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (projectName != null) metadata['project'] = projectName;
    if (experimentId != null) metadata['experiment_id'] = experimentId;

    return container(containerId).metadata(metadata);
  }

  /// Configure for research with experiment tracking
  ///
  /// Sets up metadata for research and experimentation with
  /// detailed tracking information.
  AnthropicBuilder forResearch({
    required String experimentId,
    required String researcherId,
    String? hypothesis,
    Map<String, dynamic>? experimentParameters,
  }) {
    final metadata = <String, dynamic>{
      'environment': 'research',
      'experiment_id': experimentId,
      'researcher_id': researcherId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (hypothesis != null) metadata['hypothesis'] = hypothesis;
    if (experimentParameters != null) {
      metadata['experiment_parameters'] = experimentParameters;
    }

    return this.metadata(metadata);
  }

  /// Configure with MCP servers for enhanced capabilities
  ///
  /// Sets up common MCP server configurations for file access,
  /// database connectivity, and other external resources.
  AnthropicBuilder withMcpServers({
    String? fileServerUrl,
    String? databaseServerUrl,
    String? webServerUrl,
    List<AnthropicMCPServer>? customServers,
  }) {
    final servers = <AnthropicMCPServer>[];

    if (fileServerUrl != null) {
      servers
          .add(AnthropicMCPServer.url(name: 'file_server', url: fileServerUrl));
    }

    if (databaseServerUrl != null) {
      servers.add(AnthropicMCPServer.url(
          name: 'database_server', url: databaseServerUrl));
    }

    if (webServerUrl != null) {
      servers
          .add(AnthropicMCPServer.url(name: 'web_server', url: webServerUrl));
    }

    if (customServers != null) {
      servers.addAll(customServers);
    }

    return mcpServers(servers);
  }

  /// Configure Anthropic server-side web search (web_search_20250305 tool).
  ///
  /// This is a provider-specific helper that:
  /// - Enables web search via [LLMConfigKeys.webSearchEnabled].
  /// - Stores a [WebSearchConfig] tuned for Anthropic in
  ///   [LLMConfigKeys.webSearchConfig].
  ///
  /// The underlying Anthropic provider then maps this configuration to the
  /// official `web_search_20250305` tool fields:
  /// - [maxUses] → `max_uses`
  /// - [allowedDomains] → `allowed_domains`
  /// - [blockedDomains] → `blocked_domains`
  /// - [location] → `user_location`
  AnthropicBuilder webSearch({
    int? maxUses,
    List<String>? allowedDomains,
    List<String>? blockedDomains,
    WebSearchLocation? location,
  }) {
    // Signal that web search should be enabled for this provider.
    _baseBuilder.enableWebSearch();

    // Store a provider-agnostic configuration that the Anthropic provider
    // will translate to its native web search tool parameters.
    final config = WebSearchConfig.anthropic(
      maxUses: maxUses ?? 5,
      allowedDomains: allowedDomains,
      blockedDomains: blockedDomains,
      location: location,
    );

    _baseBuilder.extension(LLMConfigKeys.webSearchConfig, config);
    return this;
  }

  // ========== Build methods ==========

  /// Builds and returns a configured LLM provider instance
  Future<ChatCapability> build() async {
    return _baseBuilder.build();
  }

  /// Builds a provider with FileManagementCapability
  Future<FileManagementCapability> buildFileManagement() async {
    return _baseBuilder.buildFileManagement();
  }

  /// Builds a provider with ModelListingCapability
  Future<ModelListingCapability> buildModelListing() async {
    return _baseBuilder.buildModelListing();
  }
}
