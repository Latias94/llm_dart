import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_openai/responses.dart';
import 'package:test/test.dart';

Map<String, dynamic> _loadFixture(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  group('OpenAI Responses providerMetadata server tool calls', () {
    test('exposes codeInterpreterCalls', () {
      final raw = _loadFixture(
        'test/fixtures/openai/responses/openai-code-interpreter-tool.1.json',
      );
      final response = OpenAIResponsesResponse(raw);
      final meta =
          response.providerMetadata?['openai'] as Map<String, dynamic>?;
      expect(meta, isNotNull);

      final calls = meta!['codeInterpreterCalls'] as List?;
      expect(calls, isNotNull);
      expect(calls, isNotEmpty);
      expect((calls!.first as Map)['type'], equals('code_interpreter_call'));
    });

    test('exposes imageGenerationCalls', () {
      final raw = _loadFixture(
        'test/fixtures/openai/responses/openai-image-generation-tool.1.json',
      );
      final response = OpenAIResponsesResponse(raw);
      final meta =
          response.providerMetadata?['openai'] as Map<String, dynamic>?;
      expect(meta, isNotNull);

      final calls = meta!['imageGenerationCalls'] as List?;
      expect(calls, isNotNull);
      expect(calls, isNotEmpty);
      expect((calls!.first as Map)['type'], equals('image_generation_call'));
    });

    test('exposes applyPatchCalls', () {
      final raw = _loadFixture(
        'test/fixtures/openai/responses/openai-apply-patch-tool.1.json',
      );
      final response = OpenAIResponsesResponse(raw);
      final meta =
          response.providerMetadata?['openai'] as Map<String, dynamic>?;
      expect(meta, isNotNull);

      final calls = meta!['applyPatchCalls'] as List?;
      expect(calls, isNotNull);
      expect(calls, isNotEmpty);
      final first = calls!.first as Map;
      expect(first['type'], equals('apply_patch_call'));
      expect(first['operation'], isA<Map>());
    });

    test('exposes shellCalls', () {
      final raw = _loadFixture(
        'test/fixtures/openai/responses/openai-shell-tool.1.json',
      );
      final response = OpenAIResponsesResponse(raw);
      final meta =
          response.providerMetadata?['openai'] as Map<String, dynamic>?;
      expect(meta, isNotNull);

      final calls = meta!['shellCalls'] as List?;
      expect(calls, isNotNull);
      expect(calls, isNotEmpty);
      expect((calls!.first as Map)['type'], equals('shell_call'));
    });

    test('exposes localShellCalls', () {
      final raw = _loadFixture(
        'test/fixtures/openai/responses/openai-local-shell-tool.1.json',
      );
      final response = OpenAIResponsesResponse(raw);
      final meta =
          response.providerMetadata?['openai'] as Map<String, dynamic>?;
      expect(meta, isNotNull);

      final calls = meta!['localShellCalls'] as List?;
      expect(calls, isNotNull);
      expect(calls, isNotEmpty);
      expect((calls!.first as Map)['type'], equals('local_shell_call'));
    });

    test('exposes mcpCalls and mcpListTools', () {
      final raw = _loadFixture(
        'test/fixtures/openai/responses/openai-mcp-tool.1.json',
      );
      final response = OpenAIResponsesResponse(raw);
      final meta =
          response.providerMetadata?['openai'] as Map<String, dynamic>?;
      expect(meta, isNotNull);

      final listTools = meta!['mcpListTools'] as List?;
      expect(listTools, isNotNull);
      expect(listTools, isNotEmpty);
      expect((listTools!.first as Map)['type'], equals('mcp_list_tools'));

      final calls = meta['mcpCalls'] as List?;
      expect(calls, isNotNull);
      expect(calls, isNotEmpty);
      expect((calls!.first as Map)['type'], equals('mcp_call'));
    });

    test('exposes mcpApprovalRequests when present', () {
      final raw = _loadFixture(
        'test/fixtures/openai/responses/openai-mcp-tool-approval.3.json',
      );
      final response = OpenAIResponsesResponse(raw);
      final meta =
          response.providerMetadata?['openai'] as Map<String, dynamic>?;
      expect(meta, isNotNull);

      final requests = meta!['mcpApprovalRequests'] as List?;
      expect(requests, isNotNull);
      expect(requests, isNotEmpty);
      expect((requests!.first as Map)['type'], equals('mcp_approval_request'));
    });
  });
}
