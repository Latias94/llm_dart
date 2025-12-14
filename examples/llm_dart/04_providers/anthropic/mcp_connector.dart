import 'dart:io';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic_sub;

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
  if (apiKey == null) {
    print('❌ Please set ANTHROPIC_API_KEY environment variable');
    return;
  }

  await demonstrateBasicMcpConnector(apiKey);
  await demonstrateMultipleMcpServers(apiKey);
  await demonstrateMcpWithAuthentication(apiKey);

  print('\n✅ Anthropic MCP connector examples completed!');
}

/// Demonstrate basic MCP connector usage
Future<void> demonstrateBasicMcpConnector(String apiKey) async {
  print('🔧 Basic MCP Connector:\n');

  try {
    // Configure Anthropic language model with MCP server (prompt-first)
    final model = await ai()
        .anthropic((anthropic) => anthropic.mcpServers([
              const AnthropicMCPServer.url(
                name: 'example-server',
                url: 'https://example-server.modelcontextprotocol.io/sse',
              ),
            ]))
        .apiKey(apiKey)
        .model('claude-sonnet-4-20250514')
        .buildLanguageModel();

    print('   📡 Configured MCP server: example-server');
    print('   🤖 Model: claude-sonnet-4-20250514');

    // Send a message that might use MCP tools
    final prompt = ChatPromptBuilder.user()
        .text('What tools do you have available from the MCP server?')
        .build();
    final response = await generateTextWithModel(
      model,
      promptMessages: [prompt],
    );

    print('   💬 User: What tools do you have available from the MCP server?');
    print('   🤖 Claude: ${response.text}');

    // Check for MCP tool usage
    final raw = response.rawResponse as anthropic_sub.AnthropicChatResponse?;
    final mcpToolUses = raw?.mcpToolUses;
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
    final model = await ai()
        .anthropic((anthropic) => anthropic.withMcpServers(
              fileServerUrl: 'https://file-server.example.com/mcp',
              databaseServerUrl: 'https://db-server.example.com/mcp',
              webServerUrl: 'https://web-server.example.com/mcp',
              customServers: [
                const AnthropicMCPServer.url(
                  name: 'custom-analytics',
                  url: 'https://analytics.example.com/mcp',
                  toolConfiguration: AnthropicMCPToolConfiguration(
                    enabled: true,
                    allowedTools: ['analyze_data', 'generate_report'],
                  ),
                ),
              ],
            ))
        .apiKey(apiKey)
        .model('claude-sonnet-4-20250514')
        .buildLanguageModel();

    print('   📡 Configured multiple MCP servers:');
    print('      • file_server (File operations)');
    print('      • database_server (Database queries)');
    print('      • web_server (Web scraping)');
    print('      • custom-analytics (Data analysis)');

    final prompt = ChatPromptBuilder.user()
        .text('Can you help me analyze some data using the available tools?')
        .build();
    final response = await generateTextWithModel(
      model,
      promptMessages: [prompt],
    );

    print(
        '   💬 User: Can you help me analyze some data using the available tools?');
    print('   🤖 Claude: ${response.text}');

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

    final model = await ai()
        .anthropic((anthropic) => anthropic.mcpServers([
              const AnthropicMCPServer.url(
                name: 'authenticated-server',
                url: 'https://secure-server.example.com/mcp',
                authorizationToken: mockAccessToken,
                toolConfiguration: AnthropicMCPToolConfiguration(
                  enabled: true,
                  allowedTools: ['secure_operation', 'private_data'],
                ),
              ),
            ]))
        .apiKey(apiKey)
        .model('claude-sonnet-4-20250514')
        .buildLanguageModel();

    print('   🔒 Configured authenticated MCP server');
    print('   🎫 Using OAuth access token');
    print('   🛡️ Limited to specific tools: secure_operation, private_data');

    final prompt = ChatPromptBuilder.user()
        .text('Access my private data securely.')
        .build();
    final response = await generateTextWithModel(
      model,
      promptMessages: [prompt],
    );

    print('   💬 User: Access my private data securely.');
    print('   🤖 Claude: ${response.text}');

    // Check for MCP tool results
    final raw = response.rawResponse as anthropic_sub.AnthropicChatResponse?;
    final mcpToolResults = raw?.mcpToolResults;
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
