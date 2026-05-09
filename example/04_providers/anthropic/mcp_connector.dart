// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:llm_dart/anthropic.dart' as anthropic;
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;

/// Anthropic MCP connector examples built on the stable Anthropic chat model
/// facade plus typed provider-owned MCP options.
///
/// Reference: https://docs.anthropic.com/en/docs/agents-and-tools/mcp-connector
Future<void> main() async {
  print('🔗 Anthropic MCP Connector Example\n');

  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set ANTHROPIC_API_KEY environment variable');
    return;
  }

  await demonstrateBasicMcpConnector(apiKey);
  await demonstrateMultipleMcpServers(apiKey);
  await demonstrateMcpWithAuthentication(apiKey);

  print('✅ Anthropic MCP connector examples completed!');
}

Future<void> demonstrateBasicMcpConnector(String apiKey) async {
  print('🔧 Basic MCP Connector:\n');

  try {
    final model = _createAnthropicModel(apiKey);
    final result = await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text(
          'What tools do you have available from the MCP server?',
        ),
      ],
      callOptions: _mcpCallOptions([
        const anthropic.AnthropicMcpServer.url(
          name: 'example-server',
          url: 'https://example-server.modelcontextprotocol.io/sse',
        ),
      ]),
    );

    print('   📡 Configured MCP server: example-server');
    print('   🤖 Model: ${model.modelId}');
    print('   💬 User: What tools do you have available from the MCP server?');
    print('   🤖 Claude: ${result.text}');
    _printMcpActivity(result);

    print('   ✅ Basic MCP connector completed\n');
  } catch (error) {
    print('   ❌ Basic MCP connector failed: $error\n');
  }
}

Future<void> demonstrateMultipleMcpServers(String apiKey) async {
  print('🌐 Multiple MCP Servers:\n');

  try {
    final model = _createAnthropicModel(apiKey);
    final result = await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text(
          'Can you help me analyze some data using the available tools?',
        ),
      ],
      callOptions: _mcpCallOptions([
        const anthropic.AnthropicMcpServer.url(
          name: 'file-server',
          url: 'https://file-server.example.com/mcp',
        ),
        const anthropic.AnthropicMcpServer.url(
          name: 'database-server',
          url: 'https://db-server.example.com/mcp',
        ),
        const anthropic.AnthropicMcpServer.url(
          name: 'web-server',
          url: 'https://web-server.example.com/mcp',
        ),
        const anthropic.AnthropicMcpServer.url(
          name: 'custom-analytics',
          url: 'https://analytics.example.com/mcp',
          toolConfiguration: anthropic.AnthropicMcpToolConfiguration(
            enabled: true,
            allowedTools: ['analyze_data', 'generate_report'],
          ),
        ),
      ]),
    );

    print('   📡 Configured MCP servers:');
    print('      • file-server');
    print('      • database-server');
    print('      • web-server');
    print('      • custom-analytics');
    print(
      '   💬 User: Can you help me analyze some data using the available tools?',
    );
    print('   🤖 Claude: ${result.text}');
    _printMcpActivity(result);

    print('   ✅ Multiple MCP servers completed\n');
  } catch (error) {
    print('   ❌ Multiple MCP servers failed: $error\n');
  }
}

Future<void> demonstrateMcpWithAuthentication(String apiKey) async {
  print('🔐 MCP with Authentication:\n');

  try {
    const mockAccessToken = 'mock_access_token_here';

    final model = _createAnthropicModel(apiKey);
    final result = await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text('Access my private data securely.'),
      ],
      callOptions: _mcpCallOptions([
        const anthropic.AnthropicMcpServer.url(
          name: 'authenticated-server',
          url: 'https://secure-server.example.com/mcp',
          authorizationToken: mockAccessToken,
          toolConfiguration: anthropic.AnthropicMcpToolConfiguration(
            enabled: true,
            allowedTools: ['secure_operation', 'private_data'],
          ),
        ),
      ]),
    );

    print('   🔒 Configured authenticated MCP server');
    print('   🎫 Authorization token supplied');
    print('   🛡️ Limited tools: secure_operation, private_data');
    print('   💬 User: Access my private data securely.');
    print('   🤖 Claude: ${result.text}');
    _printMcpActivity(result);

    print('   ✅ Authenticated MCP connector completed\n');
  } catch (error) {
    print('   ❌ Authenticated MCP connector failed: $error\n');
  }
}

core.LanguageModel _createAnthropicModel(String apiKey) {
  return llm
      .anthropic(
        apiKey: apiKey,
      )
      .chatModel('claude-sonnet-4-5');
}

core.CallOptions _mcpCallOptions(List<anthropic.AnthropicMcpServer> servers) {
  return core.CallOptions(
    providerOptions: anthropic.AnthropicGenerateTextOptions(
      mcpServers: servers,
    ),
  );
}

void _printMcpActivity(core.GenerateTextCallResult<dynamic> result) {
  final toolUses = result.content
      .whereType<core.ToolCallContentPart>()
      .where(_isMcpToolUse)
      .toList(growable: false);
  final toolResults = result.content
      .whereType<core.ToolResultContentPart>()
      .where(_isMcpToolResult)
      .toList(growable: false);

  if (toolUses.isEmpty && toolResults.isEmpty) {
    print('   ℹ️  No MCP tool activity was returned in this response');
    _printCallMetadata(result);
    return;
  }

  if (toolUses.isNotEmpty) {
    print('   🔧 MCP Tool Uses (stable content parts):');
    for (final part in toolUses) {
      final metadata = part.providerMetadata?.namespace('anthropic');
      final serverName =
          part.toolCall.title ?? metadata?['serverName'] ?? 'unknown-server';
      print('      • ${part.toolCall.toolName} (Server: $serverName)');
      print('        Tool call ID: ${part.toolCall.toolCallId}');
      print('        Input: ${_formatValue(part.toolCall.input)}');
    }
  }

  if (toolResults.isNotEmpty) {
    print('   📊 MCP Tool Results (stable content parts):');
    for (final part in toolResults) {
      final metadata = part.providerMetadata?.namespace('anthropic');
      print(
        '      • ${part.toolResult.toolName} '
        '[${part.toolResult.isError ? 'error' : 'success'}]',
      );
      print('        Tool call ID: ${part.toolResult.toolCallId}');
      print('        Block type: ${metadata?['partType'] ?? 'unknown'}');
      print('        Output: ${_formatValue(part.toolResult.output)}');
    }
  }

  _printCallMetadata(result);
}

bool _isMcpToolUse(core.ToolCallContentPart part) {
  return part.toolCall.providerExecuted &&
      part.toolCall.isDynamic &&
      part.toolCall.toolName.startsWith('mcp.');
}

bool _isMcpToolResult(core.ToolResultContentPart part) {
  final metadata = part.providerMetadata?.namespace('anthropic');
  return metadata?['partType'] == 'mcp_tool_result' ||
      part.toolResult.toolName.startsWith('mcp.');
}

void _printCallMetadata(core.GenerateTextCallResult<dynamic> result) {
  print('   🧾 Stable call metadata:');
  print('      Response ID: ${result.responseId ?? 'unknown'}');
  print('      Finish reason: ${result.finishReason}');

  final anthropicMetadata = result.providerMetadata?.namespace('anthropic');
  if (result.usage != null) {
    print('      Total tokens: ${result.usage!.totalTokens}');
  }
  if (anthropicMetadata != null && anthropicMetadata.isNotEmpty) {
    print('      Anthropic metadata: ${_formatValue(anthropicMetadata)}');
  }
}

String _formatValue(Object? value) {
  if (value == null) {
    return 'null';
  }

  if (value is Map || value is List) {
    return JsonEncoder.withIndent('  ').convert(value);
  }

  return value.toString();
}
