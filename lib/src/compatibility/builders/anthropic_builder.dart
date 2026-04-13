import '../../../builder/llm_builder.dart';
import '../../../core/capability.dart';
import '../../../providers/anthropic/mcp_models.dart';

/// Anthropic-specific legacy builder DSL layered on top of [LLMBuilder].
class AnthropicBuilder {
  final LLMBuilder _baseBuilder;

  AnthropicBuilder(this._baseBuilder);

  /// Sets metadata for the request.
  AnthropicBuilder metadata(Map<String, dynamic> data) {
    _baseBuilder.extension('metadata', data);
    return this;
  }

  /// Sets the container ID for workbench usage.
  AnthropicBuilder container(String containerId) {
    _baseBuilder.extension('container', containerId);
    return this;
  }

  /// Sets MCP (Model Context Protocol) servers.
  AnthropicBuilder mcpServers(List<AnthropicMCPServer> servers) {
    _baseBuilder.extension('mcpServers', servers);
    return this;
  }

  /// Configure for development with tracking metadata.
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

  /// Configure for production with comprehensive tracking.
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

  /// Configure for workbench usage.
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

  /// Configure for research with experiment tracking.
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

  /// Configure with MCP servers for enhanced capabilities.
  AnthropicBuilder withMcpServers({
    String? fileServerUrl,
    String? databaseServerUrl,
    String? webServerUrl,
    List<AnthropicMCPServer>? customServers,
  }) {
    final servers = <AnthropicMCPServer>[];

    if (fileServerUrl != null) {
      servers.add(
        AnthropicMCPServer.url(name: 'file_server', url: fileServerUrl),
      );
    }

    if (databaseServerUrl != null) {
      servers.add(
        AnthropicMCPServer.url(
          name: 'database_server',
          url: databaseServerUrl,
        ),
      );
    }

    if (webServerUrl != null) {
      servers.add(
        AnthropicMCPServer.url(name: 'web_server', url: webServerUrl),
      );
    }

    if (customServers != null) {
      servers.addAll(customServers);
    }

    return mcpServers(servers);
  }

  /// Builds and returns a configured LLM provider instance.
  Future<ChatCapability> build() async {
    return _baseBuilder.build();
  }

  /// Builds a provider with FileManagementCapability.
  Future<FileManagementCapability> buildFileManagement() async {
    return _baseBuilder.buildFileManagement();
  }

  /// Builds a provider with ModelListingCapability.
  Future<ModelListingCapability> buildModelListing() async {
    return _baseBuilder.buildModelListing();
  }
}
