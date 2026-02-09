library;

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:test/test.dart';

void main() {
  group('provider metadata alias', () {
    test('wrapStreamPartsWithProviderMetadataAlias aliases provider tool parts',
        () async {
      final parts = Stream<LLMStreamPart>.fromIterable([
        const LLMProviderToolCallPart(
          toolCallId: 'tool_1',
          toolName: 'web_search',
          input: {'q': 'hi'},
          providerMetadata: {
            'openai': {'type': 'web_search_call'}
          },
        ),
        const LLMProviderToolDeltaPart(
          toolCallId: 'tool_1',
          toolName: 'web_search',
          status: 'searching',
          providerMetadata: {
            'openai': {'type': 'web_search_call'}
          },
        ),
        const LLMProviderToolApprovalRequestPart(
          approvalId: 'approval_1',
          toolCallId: 'tool_1',
          toolName: 'mcp',
          input: {'x': 1},
          providerMetadata: {
            'openai': {'type': 'mcp_approval_request'}
          },
        ),
        const LLMProviderToolResultPart(
          toolCallId: 'tool_1',
          toolName: 'web_search',
          result: {'ok': true},
          providerMetadata: {
            'openai': {'type': 'web_search_call'}
          },
        ),
      ]);

      final wrapped = await wrapStreamPartsWithProviderMetadataAlias(
        parts,
        baseKey: 'openai',
        aliasKey: 'openai.responses',
      ).toList();

      for (final part in wrapped) {
        final meta = switch (part) {
          LLMProviderToolCallPart(:final providerMetadata) => providerMetadata,
          LLMProviderToolDeltaPart(:final providerMetadata) => providerMetadata,
          LLMProviderToolApprovalRequestPart(:final providerMetadata) =>
            providerMetadata,
          LLMProviderToolResultPart(:final providerMetadata) =>
            providerMetadata,
          _ => null,
        };

        expect(meta, isNotNull);
        expect(meta!['openai'], isA<Map>());
        expect(meta['openai.responses'], equals(meta['openai']));
      }
    });

    test('withProviderMetadataAlias aliases single-entry providerMetadata',
        () async {
      final parts = Stream<LLMStreamPart>.fromIterable([
        const LLMProviderToolCallPart(
          toolCallId: 'tool_1',
          toolName: 'web_search',
          providerMetadata: {
            'xai.responses': {'type': 'web_search_call'}
          },
        ),
      ]);

      final wrapped = await wrapStreamPartsWithProviderMetadataAlias(
        parts,
        baseKey: 'openai',
        aliasKey: 'openai.responses',
      ).toList();

      final call = wrapped.single as LLMProviderToolCallPart;
      expect(call.providerMetadata, isNotNull);
      expect(call.providerMetadata!['openai.responses'], isA<Map>());
      expect(call.providerMetadata!['openai.responses'],
          equals(call.providerMetadata!['xai.responses']));
    });
  });
}
