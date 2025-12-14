// ignore_for_file: avoid_print
import 'dart:convert';

/// MCP Concept Demo - Understanding Model Context Protocol
///
/// This example demonstrates the core concepts of MCP (Model Context Protocol)
/// and how it can be integrated with LLM applications like llm_dart.
///
/// Key concepts covered:
/// - What is MCP and why it matters
/// - MCP tool definitions and schemas
/// - Tool discovery and execution patterns
/// - Integration strategies with LLMs
///
/// Run: dart run new_example/07_mcp_integration/mcp_concept_demo.dart
void main() async {
  print('MCP Concept Demo - Understanding Model Context Protocol\n');

  await demonstrateMcpConcepts();
  await demonstrateToolDefinitions();
  await demonstrateIntegrationPatterns();
  await demonstrateRealWorldExamples();

  print('\nMCP concept demo completed!');
  print('Ready to build MCP-powered AI applications!');
}

/// Demonstrate core MCP concepts
Future<void> demonstrateMcpConcepts() async {
  print('Core MCP Concepts:\n');

  print('   What is MCP?');
  print(
      '      Model Context Protocol (MCP) is like USB-C for AI applications.');
  print(
      '      It provides a standardized way to connect LLMs to external tools and data.\n');

  print('   MCP Architecture:');
  print('      ┌─────────────┐    ┌─────────────┐    ┌─────────────┐');
  print('      │ LLM Client  │◄──►│ MCP Bridge  │◄──►│ MCP Server  │');
  print('      │ (llm_dart)  │    │ (Converter) │    │ (Tools)     │');
  print('      └─────────────┘    └─────────────┘    └─────────────┘\n');

  print('   Key Components:');
  print('      • MCP Server: Provides tools and resources');
  print('      • MCP Client: Consumes tools and resources');
  print('      • Transport: Communication layer (stdio, HTTP, WebSocket)');
  print('      • Protocol: Standardized message format (JSON-RPC 2.0)\n');

  print('   Core concepts explained\n');
}

/// Demonstrate MCP tool definitions
Future<void> demonstrateToolDefinitions() async {
  print('🛠️ MCP Tool Definitions:\n');

  // Example MCP tool definition
  final mcpToolDefinition = {
    'name': 'file_search',
    'description': 'Search for files in a directory',
    'inputSchema': {
      'type': 'object',
      'properties': {
        'directory': {
          'type': 'string',
          'description': 'Directory path to search in',
        },
        'pattern': {
          'type': 'string',
          'description': 'File name pattern (glob)',
        },
        'recursive': {
          'type': 'boolean',
          'description': 'Search recursively in subdirectories',
          'default': false,
        },
      },
      'required': ['directory', 'pattern'],
    },
  };

  print('   📋 Example MCP Tool Definition:');
  print('   ${JsonEncoder.withIndent('   ').convert(mcpToolDefinition)}\n');

  // Show how this converts to llm_dart format
  print('   🔄 Converted to llm_dart Tool:');
  final llmDartTool = {
    'type': 'function',
    'function': {
      'name': mcpToolDefinition['name'],
      'description': mcpToolDefinition['description'],
      'parameters': mcpToolDefinition['inputSchema'],
    },
  };
  print('   ${JsonEncoder.withIndent('   ').convert(llmDartTool)}\n');

  print('   ✅ Tool definitions demonstrated\n');
}

/// Demonstrate integration patterns
Future<void> demonstrateIntegrationPatterns() async {
  print('🔗 Integration Patterns:\n');

  print('   Pattern 1: Direct Integration');
  print('   ┌─────────┐ direct ┌─────────────┐');
  print('   │ LLM     │◄──────►│ MCP Server  │');
  print('   │ Client  │        │ (Built-in)  │');
  print('   └─────────┘        └─────────────┘');
  print('   • Best for: Simple, single-purpose tools');
  print('   • Example: Calculator, time utilities\n');

  print('   Pattern 2: Bridge Integration');
  print('   ┌─────────┐ bridge ┌─────────┐ mcp ┌─────────────┐');
  print('   │ LLM     │◄──────►│ Bridge  │◄───►│ MCP Server  │');
  print('   │ Client  │        │ Layer   │     │ (External)  │');
  print('   └─────────┘        └─────────┘     └─────────────┘');
  print('   • Best for: Complex, external tools');
  print('   • Example: Database, file system, APIs\n');

  print('   Pattern 3: Multi-Server Integration');
  print('   ┌─────────┐        ┌─────────┐     ┌─────────────┐');
  print('   │ LLM     │◄──────►│ Bridge  │◄───►│ MCP Server 1│');
  print('   │ Client  │        │ Layer   │     ├─────────────┤');
  print('   └─────────┘        └─────────┘     │ MCP Server 2│');
  print('                                      ├─────────────┤');
  print('                                      │ MCP Server 3│');
  print('                                      └─────────────┘');
  print('   • Best for: Complex workflows with multiple tool types');
  print('   • Example: Data analysis pipeline\n');

  print('   ✅ Integration patterns explained\n');
}

/// Demonstrate real-world examples
Future<void> demonstrateRealWorldExamples() async {
  print('🌍 Real-World MCP Examples:\n');

  final examples = [
    {
      'name': 'File System MCP Server',
      'description': 'Read, write, and search files',
      'tools': ['file_read', 'file_write', 'file_search', 'directory_list'],
      'use_case': 'Code analysis, document processing',
      'url':
          'https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem',
    },
    {
      'name': 'Database MCP Server',
      'description': 'Query SQL databases',
      'tools': ['query_execute', 'schema_describe', 'table_list'],
      'use_case': 'Data analysis, reporting',
      'url':
          'https://github.com/modelcontextprotocol/servers/tree/main/src/sqlite',
    },
    {
      'name': 'Web Search MCP Server',
      'description': 'Search the web for information',
      'tools': ['web_search', 'url_fetch', 'page_summarize'],
      'use_case': 'Research, fact-checking',
      'url':
          'https://github.com/modelcontextprotocol/servers/tree/main/src/brave-search',
    },
    {
      'name': 'Git MCP Server',
      'description': 'Git repository operations',
      'tools': ['git_status', 'git_diff', 'git_commit', 'git_log'],
      'use_case': 'Code review, version control',
      'url':
          'https://github.com/modelcontextprotocol/servers/tree/main/src/git',
    },
  ];

  for (final example in examples) {
    print('   📦 ${example['name']}');
    print('      Description: ${example['description']}');
    print('      Tools: ${(example['tools'] as List).join(', ')}');
    print('      Use Case: ${example['use_case']}');
    print('      URL: ${example['url']}\n');
  }

  print('   💡 How to Use with llm_dart:');
  print('      1. Install MCP server (npm, pip, cargo, etc.)');
  print('      2. Create MCP bridge in your Dart app');
  print('      3. Convert MCP tools to llm_dart tools');
  print('      4. Use tools in LLM conversations');
  print('      5. Handle tool results and continue conversation\n');

  print('   🔧 Example Integration Code:');
  print('''
      // 1. Create MCP bridge
      final bridge = await McpToolBridge.createStdioBridge(
        serverCommand: 'npx',
        serverArgs: ['@modelcontextprotocol/server-filesystem', '/path/to/files'],
      );
      
      // 2. Get tools
      final tools = bridge.convertToLlmDartTools();
      
      // 3. Use with LLM
      final response = await llm.chatWithTools(messages, tools);
      
      // 4. Execute tool calls
      for (final toolCall in response.toolCalls ?? []) {
        final result = await bridge.executeMcpTool(
          toolCall.function.name,
          toolCall.function.arguments,
        );
        // Handle result...
      }
   ''');

  print('   ✅ Real-world examples demonstrated\n');
}

/// 🎯 Next Steps for MCP Integration:
///
/// 1. **Explore MCP Ecosystem**:
///    - Browse available servers: https://modelcontextprotocol.io/examples
///    - Try demo servers: https://demo-day.mcp.cloudflare.com/sse
///    - Read specification: https://modelcontextprotocol.io/specification
///
/// 2. **Build Your First MCP Integration**:
///    - Start with simple tools (calculator, time)
///    - Add file system operations
///    - Integrate with databases or APIs
///    - Create custom business logic tools
///
/// 3. **Production Considerations**:
///    - Error handling and retries
///    - Security and input validation
///    - Performance and caching
///    - Monitoring and logging
///    - Tool discovery and registration
///
/// 4. **Advanced Patterns**:
///    - Multi-server orchestration
///    - Dynamic tool loading
///    - Tool composition and chaining
///    - Context-aware tool selection
///    - Tool result caching and optimization
///
/// 5. **Contribute to MCP**:
///    - Build new MCP servers
///    - Improve existing tools
///    - Share integration patterns
///    - Help grow the ecosystem
///
/// Remember: MCP is about creating reusable, standardized tools that any
/// AI application can use. Think of it as building LEGO blocks for AI!
