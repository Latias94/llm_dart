import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';

/// Anthropic MCP Connector Example
///
/// This example demonstrates how to use Anthropic's MCP connector feature
/// to connect to remote MCP servers directly from the Messages API.
///
/// The MCP connector is a feature specific to Anthropic's API that allows
/// connecting to remote MCP servers without implementing a separate MCP client.
///
/// Reference: https://docs.anthropic.com/en/docs/agents-and-tools/mcp-connector
Future<void> main() async {
  print('🔗 Anthropic MCP Connector Example\n');

  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set ANTHROPIC_API_KEY environment variable');
    return;
  }

  registerAnthropic();

  await demonstrateBasicMcpConnector(apiKey);
  await demonstrateMultipleMcpServers(apiKey);
  await demonstrateMcpWithAuthentication(apiKey);

  print('\n✅ Anthropic MCP connector examples completed!');
}

/// Demonstrate basic MCP connector usage
Future<void> demonstrateBasicMcpConnector(String apiKey) async {
  print('🔧 Basic MCP Connector:\n');

  try {
    final provider = await LLMBuilder()
        .provider(anthropicProviderId)
        .apiKey(apiKey)
        .model('claude-sonnet-4-20250514')
        .providerOptions(anthropicProviderId, {
      'mcpServers': [
        const AnthropicMCPServer.url(
          name: 'example-server',
          url: 'https://example-server.modelcontextprotocol.io/sse',
        ).toJson(),
      ],
    }).build();

    print('   📡 Configured MCP server: example-server');
    print('   🤖 Model: claude-sonnet-4-20250514');

    final result = await generateText(
      model: provider,
      promptIr: Prompt(
        messages: [
          PromptMessage.user(
            'What tools do you have available from the MCP server?',
          ),
        ],
      ),
    );

    print('   💬 User: What tools do you have available from the MCP server?');
    print('   🤖 Claude: ${result.text}');

    // Check for MCP tool usage
    final raw = result.rawResponse;
    final mcpToolUses = raw is AnthropicChatResponse ? raw.mcpToolUses : null;
    if (mcpToolUses != null && mcpToolUses.isNotEmpty) {
      print('   🔧 MCP Tools Used:');
      for (final toolUse in mcpToolUses) {
        print('      • ${toolUse.name} (Server: ${toolUse.serverName})');
      }
    }

    print('   ✅ Basic MCP connector successful\n');
  } catch (e) {
    print('   ❌ Basic MCP connector failed: $e\n');
  }
}

/// Demonstrate multiple MCP servers
Future<void> demonstrateMultipleMcpServers(String apiKey) async {
  print('🌐 Multiple MCP Servers:\n');

  try {
    const fileServerUrl = 'https://file-server.example.com/mcp';
    const databaseServerUrl = 'https://db-server.example.com/mcp';
    const webServerUrl = 'https://web-server.example.com/mcp';

    final servers = <AnthropicMCPServer>[
      const AnthropicMCPServer.url(name: 'file_server', url: fileServerUrl),
      const AnthropicMCPServer.url(
        name: 'database_server',
        url: databaseServerUrl,
      ),
      const AnthropicMCPServer.url(name: 'web_server', url: webServerUrl),
      const AnthropicMCPServer.url(
        name: 'custom-analytics',
        url: 'https://analytics.example.com/mcp',
        toolConfiguration: AnthropicMCPToolConfiguration(
          enabled: true,
          allowedTools: ['analyze_data', 'generate_report'],
        ),
      ),
    ];

    final provider = await LLMBuilder()
        .provider(anthropicProviderId)
        .apiKey(apiKey)
        .model('claude-sonnet-4-20250514')
        .providerOptions(anthropicProviderId, {
      'mcpServers': servers.map((s) => s.toJson()).toList(),
    }).build();

    print('   📡 Configured multiple MCP servers:');
    print('      • file_server (File operations)');
    print('      • database_server (Database queries)');
    print('      • web_server (Web scraping)');
    print('      • custom-analytics (Data analysis)');

    final result = await generateText(
      model: provider,
      promptIr: Prompt(
        messages: [
          PromptMessage.user(
            'Can you help me analyze some data using the available tools?',
          ),
        ],
      ),
    );

    print(
        '   💬 User: Can you help me analyze some data using the available tools?');
    print('   🤖 Claude: ${result.text}');

    print('   ✅ Multiple MCP servers successful\n');
  } catch (e) {
    print('   ❌ Multiple MCP servers failed: $e\n');
  }
}

/// Demonstrate MCP with OAuth authentication
Future<void> demonstrateMcpWithAuthentication(String apiKey) async {
  print('🔐 MCP with Authentication:\n');

  try {
    // Note: In a real application, you would obtain the access token
    // through an OAuth flow. This is just for demonstration.
    const mockAccessToken = 'mock_access_token_here';

    final provider = await LLMBuilder()
        .provider(anthropicProviderId)
        .apiKey(apiKey)
        .model('claude-sonnet-4-20250514')
        .providerOptions(anthropicProviderId, {
      'mcpServers': [
        AnthropicMCPServer.url(
          name: 'authenticated-server',
          url: 'https://secure-server.example.com/mcp',
          authorizationToken: mockAccessToken,
          toolConfiguration: const AnthropicMCPToolConfiguration(
            enabled: true,
            allowedTools: ['secure_operation', 'private_data'],
          ),
        ).toJson(),
      ],
    }).build();

    print('   🔒 Configured authenticated MCP server');
    print('   🎫 Using OAuth access token');
    print('   🛡️ Limited to specific tools: secure_operation, private_data');

    final result = await generateText(
      model: provider,
      promptIr: Prompt(
        messages: [
          PromptMessage.user('Access my private data securely.'),
        ],
      ),
    );

    print('   💬 User: Access my private data securely.');
    print('   🤖 Claude: ${result.text}');

    // Check for MCP tool results
    final raw = result.rawResponse;
    final mcpToolResults =
        raw is AnthropicChatResponse ? raw.mcpToolResults : null;
    if (mcpToolResults != null && mcpToolResults.isNotEmpty) {
      print('   📊 MCP Tool Results:');
      for (final result in mcpToolResults) {
        print(
            '      • Tool ${result.toolUseId}: ${result.isError ? 'Error' : 'Success'}');
      }
    }

    print('   ✅ Authenticated MCP successful\n');
  } catch (e) {
    print('   ❌ Authenticated MCP failed: $e\n');
  }
}
