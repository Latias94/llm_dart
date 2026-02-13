import 'package:llm_dart_core/llm_dart_core.dart';

import 'types.dart';

/// Appends provider tool calls + tool approval responses to a Prompt IR.
///
/// This is the "persistence-friendly" building block for provider-executed tool
/// approvals (AI SDK style):
/// - The provider emits `tool-approval-request` parts while streaming.
/// - Your app collects user decisions.
/// - You append `ToolApprovalResponsePart` to the prompt and resume streaming.
///
/// Notes:
/// - [providerToolCalls] should be the provider-executed tool calls that were
///   produced in the assistant response that triggered the approvals.
/// - If [assistantText] is provided, it is included in the appended assistant
///   message (best-effort). If empty, only tool-call parts are appended.
Prompt appendProviderToolApprovalsToPrompt(
  Prompt base, {
  String assistantText = '',
  List<LLMProviderToolCallPart> providerToolCalls =
      const <LLMProviderToolCallPart>[],
  required List<ToolApprovalDecision> decisions,
}) {
  if (decisions.isEmpty) return base;

  final messages = List<PromptMessage>.from(base.messages);

  final assistantParts = <PromptPart>[];
  if (assistantText.trim().isNotEmpty) {
    assistantParts.add(TextPart(assistantText));
  }

  for (final call in providerToolCalls) {
    assistantParts.add(
      ToolCallPart(
        toolCallId: call.toolCallId,
        toolName: call.toolName,
        input: call.input,
        providerExecuted: true,
        providerOptions: _tryProviderOptions(call.providerMetadata),
      ),
    );
  }

  if (assistantParts.isNotEmpty) {
    messages.add(
      PromptMessage(
        role: PromptRole.assistant,
        parts: List<PromptPart>.unmodifiable(assistantParts),
      ),
    );
  }

  final approvalParts = decisions
      .map(
        (d) => ToolApprovalResponsePart(
          approvalId: d.approvalId,
          approved: d.approved,
          reason: d.reason,
        ),
      )
      .toList(growable: false);

  if (messages.isNotEmpty && messages.last.role == PromptRole.tool) {
    final last = messages.removeLast();
    messages.add(
      PromptMessage(
        role: PromptRole.tool,
        parts: List<PromptPart>.unmodifiable([...last.parts, ...approvalParts]),
        providerOptions: last.providerOptions,
        protocolPayloads: last.protocolPayloads,
      ),
    );
  } else {
    messages.add(PromptMessage.tool(parts: approvalParts));
  }

  return Prompt(messages: List<PromptMessage>.unmodifiable(messages));
}

ProviderOptions _tryProviderOptions(Map<String, dynamic>? metadata) {
  if (metadata == null || metadata.isEmpty) return const {};
  final out = <String, Map<String, dynamic>>{};
  for (final entry in metadata.entries) {
    final key = entry.key;
    final value = entry.value;
    if (value is Map<String, dynamic>) {
      out[key] = value;
    } else if (value is Map) {
      out[key] = value.cast<String, dynamic>();
    }
  }
  return out.isEmpty ? const {} : out;
}
