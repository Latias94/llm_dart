import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_ollama/llm_dart_ollama.dart';

/// Administrative helper for managing Ollama models and server state.
///
/// This class provides a convenient, high-level API on top of
/// [OllamaProvider] for common management operations such as:
/// - Listing local and running models
/// - Inspecting model details
/// - Copying and deleting models
/// - Pulling and pushing models
/// - Querying server version
class OllamaAdmin {
  final OllamaProvider _provider;

  /// Create an admin helper from an existing [OllamaProvider].
  const OllamaAdmin(this._provider);

  /// Create an admin helper from an [OllamaConfig].
  factory OllamaAdmin.fromConfig(OllamaConfig config) {
    return OllamaAdmin(OllamaProvider(config));
  }

  /// Create an admin helper for a local Ollama instance.
  ///
  /// [baseUrl] should point to the Ollama HTTP API root, typically
  /// `http://localhost:11434/` or `http://localhost:11434`.
  factory OllamaAdmin.local({
    String baseUrl = 'http://localhost:11434/',
    String model = 'llama3.2',
  }) {
    final normalizedBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';

    final config = OllamaConfig(
      baseUrl: normalizedBaseUrl,
      model: model,
    );
    return OllamaAdmin(OllamaProvider(config));
  }

  /// Expose the underlying provider for advanced scenarios.
  OllamaProvider get provider => _provider;

  /// List models that are available locally (`GET /api/tags`).
  Future<List<AIModel>> listLocalModels({CancellationToken? cancelToken}) {
    return _provider.models(cancelToken: cancelToken);
  }

  /// List models that are currently loaded into memory (`GET /api/ps`).
  Future<List<Map<String, dynamic>>> listRunningModels({
    CancellationToken? cancelToken,
  }) {
    return _provider.listRunningModels(cancelToken: cancelToken);
  }

  /// Show detailed information about a model (`POST /api/show`).
  Future<Map<String, dynamic>> showModel(
    String model, {
    bool verbose = false,
    CancellationToken? cancelToken,
  }) {
    // The underlying implementation already supports the full response;
    // the verbose flag is kept for future extension.
    return _provider.showModel(model, cancelToken: cancelToken).then((json) {
      if (!verbose) return json;
      return json;
    });
  }

  /// Copy a model to a new name (`POST /api/copy`).
  Future<void> copyModel(
    String source,
    String destination, {
    CancellationToken? cancelToken,
  }) {
    return _provider.copyModel(
      source,
      destination,
      cancelToken: cancelToken,
    );
  }

  /// Delete a model and its data (`DELETE /api/delete`).
  Future<void> deleteModel(
    String model, {
    CancellationToken? cancelToken,
  }) {
    return _provider.deleteModel(model, cancelToken: cancelToken);
  }

  /// Pull a model from the Ollama library (`POST /api/pull`).
  ///
  /// Returns the final status object, typically `{ "status": "success" }`.
  Future<Map<String, dynamic>> pullModel(
    String model, {
    bool insecure = false,
    CancellationToken? cancelToken,
  }) {
    return _provider.pullModel(
      model,
      insecure: insecure,
      cancelToken: cancelToken,
    );
  }

  /// Push a model to a remote library (`POST /api/push`).
  ///
  /// Returns the final status object, typically `{ "status": "success" }`.
  Future<Map<String, dynamic>> pushModel(
    String model, {
    bool insecure = false,
    CancellationToken? cancelToken,
  }) {
    return _provider.pushModel(
      model,
      insecure: insecure,
      cancelToken: cancelToken,
    );
  }

  /// Get Ollama server version information (`GET /api/version`).
  Future<Map<String, dynamic>> serverVersion({CancellationToken? cancelToken}) {
    return _provider.serverVersion(cancelToken: cancelToken);
  }
}
