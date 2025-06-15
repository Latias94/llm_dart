// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:mcp_dart/mcp_dart.dart';

/// MCP Tool Bridge - Converting Between MCP and llm_dart Tools
///
/// This bridge converts MCP tools to llm_dart tools, enabling seamless
/// integration between MCP servers and llm_dart's tool calling system.
///
/// Key Features:
/// - Automatic tool discovery from MCP servers
/// - Schema conversion between MCP and llm_dart formats
/// - Tool execution forwarding
/// - Error handling and response mapping
class McpToolBridge {
  final Client _mcpClient;
  final Map<String, dynamic> _mcpTools = {};

  McpToolBridge(this._mcpClient);

  /// Connect to MCP server and discover tools
  Future<void> initialize() async {
    try {
      // In a real implementation, you would:
      // final toolsResponse = await _mcpClient.listTools();
      // _mcpTools.addAll(toolsResponse.tools);

      print('🔍 Discovering MCP tools...');
      // For demo purposes, we'll simulate discovered tools
      _simulateDiscoveredTools();
      print('✅ Discovered ${_mcpTools.length} MCP tools');
    } catch (e) {
      print('❌ Failed to discover MCP tools: $e');
      rethrow;
    }
  }

  /// Convert MCP tools to llm_dart tools
  List<llm.Tool> convertToLlmDartTools() {
    final tools = <llm.Tool>[];

    for (final entry in _mcpTools.entries) {
      final toolName = entry.key;
      final mcpTool = entry.value as Map<String, dynamic>;

      try {
        final llmTool = _convertMcpToolToLlmDart(toolName, mcpTool);
        tools.add(llmTool);
      } catch (e) {
        print('⚠️ Failed to convert tool $toolName: $e');
      }
    }

    return tools;
  }

  /// Execute MCP tool and return result
  Future<String> executeMcpTool(String toolName, dynamic arguments) async {
    try {
      print('      🔧 MCP: Executing tool "$toolName"');
      print('         📥 MCP Args: ${jsonEncode(arguments)}');

      // In a real implementation:
      // final result = await _mcpClient.callTool(toolName, arguments);
      // return _formatMcpResult(result);

      // Parse arguments if they are a JSON string
      Map<String, dynamic> parsedArguments;
      if (arguments is String) {
        parsedArguments = jsonDecode(arguments) as Map<String, dynamic>;
      } else if (arguments is Map<String, dynamic>) {
        parsedArguments = arguments;
      } else {
        throw ArgumentError(
            'Arguments must be either a JSON string or Map<String, dynamic>');
      }

      // For demo purposes, simulate tool execution
      final result = _simulateToolExecution(toolName, parsedArguments);
      print('         📤 MCP Result: $result');
      return result;
    } catch (e) {
      final errorMsg = 'MCP tool execution failed: $e';
      print('         ❌ MCP Error: $errorMsg');
      return errorMsg;
    }
  }

  /// Convert MCP tool definition to llm_dart Tool
  llm.Tool _convertMcpToolToLlmDart(
      String toolName, Map<String, dynamic> mcpTool) {
    final description =
        mcpTool['description'] as String? ?? 'MCP tool: $toolName';
    final inputSchema = mcpTool['inputSchema'] as Map<String, dynamic>? ?? {};

    // Convert MCP input schema to llm_dart ParametersSchema
    final properties = <String, llm.ParameterProperty>{};
    final required = <String>[];

    if (inputSchema['properties'] is Map<String, dynamic>) {
      final mcpProperties = inputSchema['properties'] as Map<String, dynamic>;

      for (final entry in mcpProperties.entries) {
        final propName = entry.key;
        final propDef = entry.value as Map<String, dynamic>;

        properties[propName] = llm.ParameterProperty(
          propertyType: propDef['type'] as String? ?? 'string',
          description: propDef['description'] as String,
          enumList: (propDef['enum'] as List?)?.cast<String>(),
        );
      }
    }

    if (inputSchema['required'] is List) {
      required.addAll((inputSchema['required'] as List).cast<String>());
    }

    return llm.Tool.function(
      name: toolName,
      description: description,
      parameters: llm.ParametersSchema(
        schemaType: 'object',
        properties: properties,
        required: required,
      ),
    );
  }

  /// Simulate discovered MCP tools for demo
  void _simulateDiscoveredTools() {
    _mcpTools.addAll({
      'calculate': {
        'description': 'Perform mathematical calculations',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'expression': {
              'type': 'string',
              'description': 'Mathematical expression to evaluate',
            },
          },
          'required': ['expression'],
        },
      },
      'get_weather': {
        'description': 'Get current weather information',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'location': {
              'type': 'string',
              'description': 'City or location name',
            },
            'unit': {
              'type': 'string',
              'description': 'Temperature unit',
              'enum': ['celsius', 'fahrenheit'],
            },
          },
          'required': ['location'],
        },
      },
      'random_number': {
        'description': 'Generate random numbers',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'min': {
              'type': 'number',
              'description': 'Minimum value',
            },
            'max': {
              'type': 'number',
              'description': 'Maximum value',
            },
            'count': {
              'type': 'integer',
              'description': 'Number of random numbers',
            },
          },
          'required': ['min', 'max'],
        },
      },
      'current_time': {
        'description': 'Get current date and time',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'format': {
              'type': 'string',
              'description': 'Time format',
              'enum': ['iso', 'local', 'utc', 'timestamp'],
            },
          },
        },
      },
      'file_info': {
        'description': 'Get file or directory information',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'path': {
              'type': 'string',
              'description': 'File or directory path',
            },
          },
          'required': ['path'],
        },
      },
    });
  }

  /// Simulate MCP tool execution for demo
  String _simulateToolExecution(
      String toolName, Map<String, dynamic> arguments) {
    switch (toolName) {
      case 'calculate':
        final expression = arguments['expression'] as String;
        return 'Calculation result for "$expression": ${_simpleCalculate(expression)}';

      case 'get_weather':
        final location = arguments['location'] as String;
        final unit = arguments['unit'] as String? ?? 'celsius';
        return 'Weather in $location: 22°${unit == 'celsius' ? 'C' : 'F'}, Sunny';

      case 'random_number':
        final min = arguments['min'] as num;
        final max = arguments['max'] as num;
        final count = arguments['count'] as num? ?? 1;
        final numbers =
            List.generate(count.toInt(), (_) => min + (max - min) * 0.5);
        return 'Random numbers: ${numbers.join(', ')}';

      case 'current_time':
        final format = arguments['format'] as String? ?? 'local';
        final now = DateTime.now();
        switch (format) {
          case 'iso':
            return 'Current time (ISO): ${now.toIso8601String()}';
          case 'utc':
            return 'Current time (UTC): ${now.toUtc()}';
          case 'timestamp':
            return 'Current timestamp: ${now.millisecondsSinceEpoch}';
          default:
            return 'Current time: $now';
        }

      case 'file_info':
        final path = arguments['path'] as String;
        return 'File info for "$path": Regular file, 1024 bytes, modified today';

      default:
        return 'Unknown tool: $toolName';
    }
  }

  /// Simple calculation for demo
  String _simpleCalculate(String expression) {
    try {
      expression = expression.replaceAll(' ', '');

      // Handle multiplication first (higher precedence)
      if (expression.contains('*')) {
        // For complex expressions like "18*24+6", we need to handle order of operations
        return _evaluateExpression(expression).toString();
      }

      if (expression.contains('+')) {
        final parts = expression.split('+');
        final result = parts.map(double.parse).reduce((a, b) => a + b);
        return result.toString();
      }
      if (expression.contains('-')) {
        final parts = expression.split('-');
        final result = parts.map(double.parse).reduce((a, b) => a - b);
        return result.toString();
      }
      if (expression.contains('/')) {
        final parts = expression.split('/');
        final result = parts.map(double.parse).reduce((a, b) => a / b);
        return result.toString();
      }
      return double.parse(expression).toString();
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Evaluate mathematical expression with proper order of operations
  double _evaluateExpression(String expression) {
    // Simple expression evaluator for demo purposes
    // Handle multiplication and addition with proper precedence

    // First handle multiplication
    while (expression.contains('*')) {
      final regex = RegExp(r'(\d+(?:\.\d+)?)\s*\*\s*(\d+(?:\.\d+)?)');
      final match = regex.firstMatch(expression);
      if (match != null) {
        final a = double.parse(match.group(1)!);
        final b = double.parse(match.group(2)!);
        final result = a * b;
        expression =
            expression.replaceFirst(match.group(0)!, result.toString());
      } else {
        break;
      }
    }

    // Then handle addition and subtraction from left to right
    while (expression.contains('+') || expression.contains('-')) {
      final regex = RegExp(r'(\d+(?:\.\d+)?)\s*([+\-])\s*(\d+(?:\.\d+)?)');
      final match = regex.firstMatch(expression);
      if (match != null) {
        final a = double.parse(match.group(1)!);
        final operator = match.group(2)!;
        final b = double.parse(match.group(3)!);
        final result = operator == '+' ? a + b : a - b;
        expression =
            expression.replaceFirst(match.group(0)!, result.toString());
      } else {
        break;
      }
    }

    return double.parse(expression);
  }

  /// Close MCP client connection
  Future<void> close() async {
    await _mcpClient.close();
  }
}

/// Factory for creating MCP tool bridges
class McpToolBridgeFactory {
  /// Create a bridge for stdio-based MCP server
  static Future<McpToolBridge> createStdioBridge({
    required String serverCommand,
    List<String> serverArgs = const [],
  }) async {
    final client = Client(
      Implementation(name: "llm-dart-mcp-bridge", version: "1.0.0"),
    );

    // In a real implementation, you would connect to the actual server:
    // final transport = StdioClientTransport(serverCommand, serverArgs);
    // await client.connect(transport);

    final bridge = McpToolBridge(client);
    await bridge.initialize();
    return bridge;
  }

  /// Create a bridge for HTTP-based MCP server
  static Future<McpToolBridge> createHttpBridge({
    required String serverUrl,
    Map<String, String> headers = const {},
  }) async {
    final client = Client(
      Implementation(name: "llm-dart-mcp-bridge", version: "1.0.0"),
    );

    // In a real implementation:
    // final transport = HttpClientTransport(serverUrl, headers);
    // await client.connect(transport);

    final bridge = McpToolBridge(client);
    await bridge.initialize();
    return bridge;
  }

  /// Create a bridge for stream-based MCP server (in-process)
  static Future<McpToolBridge> createStreamBridge(McpServer server) async {
    final client = Client(
      Implementation(name: "llm-dart-mcp-bridge", version: "1.0.0"),
    );

    // Note: In a real implementation, you would connect using appropriate transport
    // For demo purposes, we'll just create the bridge

    final bridge = McpToolBridge(client);
    await bridge.initialize();
    return bridge;
  }
}
