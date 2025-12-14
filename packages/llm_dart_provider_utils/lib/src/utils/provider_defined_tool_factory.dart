import 'package:llm_dart_core/llm_dart_core.dart';

/// Factory helper for provider-defined tools.
///
/// This utility pairs a declarative [Tool] schema (exposed to the model)
/// with a strongly-typed execute function that works on domain-specific
/// argument and result types. It then produces an [ExecutableTool] that
/// can be consumed by agents and helper APIs.
///
/// The main goal is to reduce boilerplate when implementing tools that
/// are defined by a provider package (for example xAI web search tools),
/// while keeping the agent runtime generic and provider-agnostic.
class ProviderDefinedToolFactory<TArgs, TOutput> {
  /// Declarative tool schema exposed to the model.
  final Tool schema;

  /// Strongly-typed execute function for this tool.
  ///
  /// The [TArgs] type represents a structured view over the raw JSON
  /// arguments passed by the model, and [TOutput] represents the
  /// structured result before it is converted back to JSON.
  final Future<TOutput> Function(TArgs args) execute;

  const ProviderDefinedToolFactory({
    required this.schema,
    required this.execute,
  });

  /// Convert this factory into an [ExecutableTool] for use with agents.
  ///
  /// [decodeArgs] converts the raw JSON arguments into [TArgs], while
  /// [encodeResult] converts the structured [TOutput] result back into
  /// a JSON-compatible map for the agent runtime.
  ExecutableTool toExecutableTool({
    required TArgs Function(Map<String, dynamic> rawArgs) decodeArgs,
    required Map<String, dynamic> Function(TOutput output) encodeResult,
  }) {
    return ExecutableTool(
      schema: schema,
      execute: (raw) async {
        final args = decodeArgs(raw);
        final result = await execute(args);
        return encodeResult(result);
      },
    );
  }
}

/// Convenience helper for creating an [ExecutableTool] directly.
///
/// This is a lightweight wrapper around [ProviderDefinedToolFactory] for
/// cases where you do not need to keep the factory instance around.
ExecutableTool createProviderDefinedExecutableTool<TArgs, TOutput>({
  required Tool schema,
  required Future<TOutput> Function(TArgs args) execute,
  required TArgs Function(Map<String, dynamic> rawArgs) decodeArgs,
  required Map<String, dynamic> Function(TOutput output) encodeResult,
}) {
  final factory = ProviderDefinedToolFactory<TArgs, TOutput>(
    schema: schema,
    execute: execute,
  );
  return factory.toExecutableTool(
    decodeArgs: decodeArgs,
    encodeResult: encodeResult,
  );
}
