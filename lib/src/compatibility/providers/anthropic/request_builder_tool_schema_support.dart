part of 'request_builder.dart';

final class _AnthropicToolSchemaSupport {
  const _AnthropicToolSchemaSupport();

  Map<String, dynamic> convertFunctionTool(Tool tool) {
    final schema = tool.function.parameters.toJson();

    if (schema['type'] != 'object') {
      throw ArgumentError(
        'Anthropic tools require input_schema to be of type "object". '
        'Tool "${tool.function.name}" has type "${schema['type']}". '
        '\n\nTo fix this, update your tool definition:\n'
        'ParametersSchema(\n'
        '  schemaType: "object",  // <- Change this to "object"\n'
        '  properties: {...},\n'
        '  required: [...],\n'
        ')\n\n'
        'See: https://docs.anthropic.com/en/api/messages#tools',
      );
    }

    final inputSchema = Map<String, dynamic>.from(schema);

    if (!inputSchema.containsKey('properties')) {
      inputSchema['properties'] = <String, dynamic>{};
    }

    return {
      'name': tool.function.name,
      'description': tool.function.description.isNotEmpty
          ? tool.function.description
          : 'No description provided',
      'input_schema': inputSchema,
    };
  }
}
