import 'package:llm_dart_core/llm_dart_core.dart';

/// Helper to emit provider-executed tool lifecycle parts with deduplication.
///
/// Provider tools are executed server-side (web search, file search, code
/// execution, MCP, etc.) and must never become local function `toolCalls`.
///
/// This emitter centralizes the common "emit once per id" logic used by
/// streaming parsers.
class ProviderToolPartEmitter {
  final String providerMetadataNamespace;

  final Set<String> _emittedCallIds = <String>{};
  final Set<String> _emittedResultIds = <String>{};

  ProviderToolPartEmitter({
    required this.providerMetadataNamespace,
  });

  void reset() {
    _emittedCallIds.clear();
    _emittedResultIds.clear();
  }

  Map<String, dynamic>? _providerMetadata(Map<String, dynamic>? payload) {
    if (payload == null || payload.isEmpty) return null;
    return {providerMetadataNamespace: payload};
  }

  LLMProviderToolCallPart? call({
    required String toolCallId,
    required String toolName,
    Object? input,
    bool? providerExecuted,
    bool? supportsDeferredResults,
    bool? isDynamic,
    Map<String, dynamic>? providerMetadataPayload,
  }) {
    if (!_emittedCallIds.add(toolCallId)) return null;
    return LLMProviderToolCallPart(
      toolCallId: toolCallId,
      toolName: toolName,
      input: input,
      providerExecuted: providerExecuted,
      supportsDeferredResults: supportsDeferredResults,
      isDynamic: isDynamic,
      providerMetadata: _providerMetadata(providerMetadataPayload),
    );
  }

  LLMProviderToolResultPart? result({
    required String toolCallId,
    required String toolName,
    required Object? result,
    bool? isError,
    bool? isDynamic,
    Map<String, dynamic>? providerMetadataPayload,
  }) {
    if (!_emittedResultIds.add(toolCallId)) return null;
    return LLMProviderToolResultPart(
      toolCallId: toolCallId,
      toolName: toolName,
      result: result,
      isError: isError,
      isDynamic: isDynamic,
      providerMetadata: _providerMetadata(providerMetadataPayload),
    );
  }
}
