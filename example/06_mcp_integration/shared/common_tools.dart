// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';
import 'package:mcp_dart/mcp_dart.dart';

/// Common MCP tools that can be used by both stdio and HTTP servers
///
/// This file contains shared tool definitions and implementations that
/// are used across different MCP transport types (stdio and HTTP).
class CommonMcpTools {
  /// Register all common mathematical tools
  static void registerMathTools(McpServer server) {
    // Basic calculator
    server.registerTool(
      'calculate',
      description:
          'Perform mathematical calculations (supports +, -, *, /, parentheses, sqrt, sin, cos, tan)',
      inputSchema: JsonObject(
        properties: {
          'expression': JsonSchema.string(
            description:
                'Mathematical expression to evaluate, such as "2 + 3 * 4", "sqrt(16)", or "sin(30)".',
          ),
        },
        required: ['expression'],
      ),
      callback: (args, extra) async {
        try {
          final expression = args['expression'] as String;
          final result = _evaluateMathExpression(expression);
          return _textResult(
            'Expression: $expression\nResult: $result',
          );
        } catch (e) {
          return _textResult(
            'Math error: $e',
            isError: true,
          );
        }
      },
    );

    // Random number generator
    server.registerTool(
      'random_number',
      description: 'Generate random numbers within specified range',
      inputSchema: JsonObject(
        properties: {
          'min': JsonSchema.number(
            description: 'Minimum value (inclusive)',
            defaultValue: 0,
          ),
          'max': JsonSchema.number(
            description: 'Maximum value (inclusive)',
            defaultValue: 100,
          ),
          'count': JsonSchema.integer(
            description: 'Number of random numbers to generate',
            defaultValue: 1,
            minimum: 1,
            maximum: 10,
          ),
        },
      ),
      callback: (args, extra) async {
        try {
          final min = (args['min'] as num?)?.toInt() ?? 0;
          final max = (args['max'] as num?)?.toInt() ?? 100;
          final count = (args['count'] as num?)?.toInt() ?? 1;

          final random = Random();
          final numbers = List.generate(
            count,
            (_) => min + random.nextInt(max - min + 1),
          );

          return _textResult(
            'Random numbers between $min and $max:\n${numbers.join(', ')}',
          );
        } catch (e) {
          return _textResult(
            'Random generation error: $e',
            isError: true,
          );
        }
      },
    );
  }

  /// Register all common utility tools
  static void registerUtilityTools(McpServer server) {
    // Current time
    server.registerTool(
      'current_time',
      description: 'Get current date and time in various formats',
      inputSchema: JsonObject(
        properties: {
          'format': JsonSchema.string(
            description: 'Time format: iso, local, utc, timestamp',
            enumValues: ['iso', 'local', 'utc', 'timestamp'],
            defaultValue: 'local',
          ),
          'timezone': JsonSchema.string(
            description: 'Timezone (only for local format)',
            defaultValue: 'system',
          ),
        },
      ),
      callback: (args, extra) async {
        try {
          final format = args['format'] as String? ?? 'local';
          final now = DateTime.now();

          String timeString;
          switch (format) {
            case 'iso':
              timeString = now.toIso8601String();
              break;
            case 'utc':
              timeString = now.toUtc().toString();
              break;
            case 'timestamp':
              timeString = now.millisecondsSinceEpoch.toString();
              break;
            case 'local':
            default:
              timeString = now.toString();
              break;
          }

          return _textResult(
            'Current time ($format): $timeString',
          );
        } catch (e) {
          return _textResult(
            'Time error: $e',
            isError: true,
          );
        }
      },
    );

    // UUID generator
    server.registerTool(
      'uuid_generate',
      description: 'Generate UUID (Universally Unique Identifier)',
      inputSchema: JsonObject(
        properties: {
          'count': JsonSchema.integer(
            description: 'Number of UUIDs to generate',
            defaultValue: 1,
            minimum: 1,
            maximum: 5,
          ),
        },
      ),
      callback: (args, extra) async {
        try {
          final count = (args['count'] as num?)?.toInt() ?? 1;
          final uuids = List.generate(count, (_) => _generateUuid());

          return _textResult(
            count == 1
                ? 'Generated UUID: ${uuids.first}'
                : 'Generated UUIDs:\n${uuids.map((u) => '• $u').join('\n')}',
          );
        } catch (e) {
          return _textResult(
            'UUID generation error: $e',
            isError: true,
          );
        }
      },
    );
  }

  /// Register all common file operation tools
  static void registerFileTools(McpServer server) {
    server.registerTool(
      'file_info',
      description: 'Get information about a file or directory',
      inputSchema: JsonObject(
        properties: {
          'path': JsonSchema.string(
            description: 'File or directory path',
          ),
        },
        required: ['path'],
      ),
      callback: (args, extra) async {
        try {
          final path = args['path'] as String;
          final file = File(path);
          final directory = Directory(path);

          String info;
          if (await file.exists()) {
            final stat = await file.stat();
            final size = stat.size;
            final modified = stat.modified;
            info = 'File: $path\n'
                'Size: $size bytes\n'
                'Modified: $modified\n'
                'Type: ${stat.type}';
          } else if (await directory.exists()) {
            final contents = await directory.list().length;
            info = 'Directory: $path\n'
                'Contents: $contents items\n'
                'Type: directory';
          } else {
            info = 'Path does not exist: $path';
          }

          return _textResult(info);
        } catch (e) {
          return _textResult(
            'File info error: $e',
            isError: true,
          );
        }
      },
    );
  }

  /// Register all common system information tools
  static void registerSystemTools(McpServer server) {
    server.registerTool(
      'system_info',
      description: 'Get system information',
      inputSchema: JsonObject(
        properties: {
          'type': JsonSchema.string(
            description: 'Type of system info: os, memory, environment',
            enumValues: ['os', 'memory', 'environment', 'all'],
            defaultValue: 'all',
          ),
        },
      ),
      callback: (args, extra) async {
        try {
          final type = args['type'] as String? ?? 'all';
          final info = StringBuffer();

          if (type == 'os' || type == 'all') {
            info.writeln('Operating System: ${Platform.operatingSystem}');
            info.writeln('OS Version: ${Platform.operatingSystemVersion}');
            info.writeln('Dart Version: ${Platform.version}');
          }

          if (type == 'environment' || type == 'all') {
            info.writeln('\nEnvironment Variables:');
            final envVars = Platform.environment;
            final importantVars = ['PATH', 'HOME', 'USER', 'SHELL'];
            for (final varName in importantVars) {
              if (envVars.containsKey(varName)) {
                info.writeln('  $varName: ${envVars[varName]}');
              }
            }
          }

          return _textResult(info.toString().trim());
        } catch (e) {
          return _textResult(
            'System info error: $e',
            isError: true,
          );
        }
      },
    );
  }

  /// Register all common tools at once
  static void registerAllCommonTools(McpServer server) {
    registerMathTools(server);
    registerUtilityTools(server);
    registerFileTools(server);
    registerSystemTools(server);
  }

  /// Simple math expression evaluator with proper operator precedence
  static double _evaluateMathExpression(String expression) {
    // Remove spaces
    expression = expression.replaceAll(' ', '');

    // Handle special functions
    if (expression.startsWith('sqrt(') && expression.endsWith(')')) {
      final inner = expression.substring(5, expression.length - 1);
      return sqrt(_evaluateMathExpression(inner));
    }

    if (expression.startsWith('sin(') && expression.endsWith(')')) {
      final inner = expression.substring(4, expression.length - 1);
      return sin(_evaluateMathExpression(inner) *
          pi /
          180); // Convert degrees to radians
    }

    if (expression.startsWith('cos(') && expression.endsWith(')')) {
      final inner = expression.substring(4, expression.length - 1);
      return cos(_evaluateMathExpression(inner) * pi / 180);
    }

    if (expression.startsWith('tan(') && expression.endsWith(')')) {
      final inner = expression.substring(4, expression.length - 1);
      return tan(_evaluateMathExpression(inner) * pi / 180);
    }

    // Handle parentheses
    while (expression.contains('(')) {
      final start = expression.lastIndexOf('(');
      final end = expression.indexOf(')', start);
      if (end == -1) throw FormatException('Mismatched parentheses');

      final inner = expression.substring(start + 1, end);
      final result = _evaluateMathExpression(inner);
      expression = expression.substring(0, start) +
          result.toString() +
          expression.substring(end + 1);
    }

    // Simple approach: handle operator precedence manually
    // First handle multiplication and division
    expression = _handleMultiplicationDivision(expression);

    // Then handle addition and subtraction
    expression = _handleAdditionSubtraction(expression);

    // Single number
    return double.parse(expression);
  }

  /// Handle multiplication and division operations
  static String _handleMultiplicationDivision(String expression) {
    // Find multiplication or division operations
    final regex = RegExp(r'(\d+(?:\.\d+)?)\s*([*/])\s*(\d+(?:\.\d+)?)');

    while (regex.hasMatch(expression)) {
      final match = regex.firstMatch(expression)!;
      final left = double.parse(match.group(1)!);
      final operator = match.group(2)!;
      final right = double.parse(match.group(3)!);

      final result = operator == '*' ? left * right : left / right;
      expression = expression.replaceFirst(match.group(0)!, result.toString());
    }

    return expression;
  }

  /// Handle addition and subtraction operations
  static String _handleAdditionSubtraction(String expression) {
    // Find addition or subtraction operations (but not negative numbers)
    final regex = RegExp(r'(\d+(?:\.\d+)?)\s*([+\-])\s*(\d+(?:\.\d+)?)');

    while (regex.hasMatch(expression)) {
      final match = regex.firstMatch(expression)!;
      final left = double.parse(match.group(1)!);
      final operator = match.group(2)!;
      final right = double.parse(match.group(3)!);

      final result = operator == '+' ? left + right : left - right;
      expression = expression.replaceFirst(match.group(0)!, result.toString());
    }

    return expression;
  }

  static CallToolResult _textResult(String text, {bool isError = false}) {
    return CallToolResult(
      content: [TextContent(text: text)],
      isError: isError,
    );
  }

  /// Generate a simple UUID (not cryptographically secure)
  static String _generateUuid() {
    final random = Random();
    final chars = '0123456789abcdef';
    final uuid = StringBuffer();

    for (int i = 0; i < 32; i++) {
      if (i == 8 || i == 12 || i == 16 || i == 20) {
        uuid.write('-');
      }
      uuid.write(chars[random.nextInt(chars.length)]);
    }

    return uuid.toString();
  }
}
